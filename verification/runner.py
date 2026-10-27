#!/usr/bin/env python3
"""Cold-start runner for a cocotb + Icarus test directory.

Builds and simulates one test directory and enforces the two-leg plan
documented in verification/README.md:

  - good leg: the DUT must pass every test (zero failures, at least one test).
  - negative-control leg: the *same* tests run against a deliberately broken
    DUT must FAIL -- a bench that has never failed is not known to be able to.

Exit status is 0 only if both requested legs behave as expected; CI gates on
it. A machine-readable result (per-test pass/fail, seed, tool versions,
commit) is written to <test_dir>/sim_build/result.json.

Cold start (from a fresh clone):

    python3 -m venv .venv && . .venv/bin/activate
    pip install -r verification/requirements.txt
    python3 verification/runner.py verification/smoke

Test directory convention (NAME = directory name):

    <test_dir>/test_NAME.py                    cocotb module
    <test_dir>/NAME.v                          good DUT, toplevel NAME
    <test_dir>/negative_control/NAME_broken.v  broken DUT, same toplevel

Override with --module/--toplevel/--dut/--broken (e.g. to point a vendored
test at DUT sources under rtl/).

Plain-Verilog mode (--vvp TABLE): the stamped benches under verification/common/
are self-checking Verilog, not cocotb. `--vvp verification/item9/benches.json`
compiles each table entry with iverilog and runs it under vvp. A run passes only
if vvp exits 0, prints a `PASS:` line and no line starting `FAIL` or `ERROR`; a
bench that ends without a verdict (e.g. an early $finish) counts as a failure.
Entries with a `negative_control` are re-run against the broken DUT and must
FAIL. Needs no cocotb.
"""

from __future__ import annotations

import argparse
import json
import os
import random
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


def _cmd_version(cmd: list[str], pattern: str) -> str | None:
    exe = shutil.which(cmd[0])
    if exe is None:
        return None
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    m = re.search(pattern, out)
    return m.group(1) if m else out.strip().splitlines()[0] if out.strip() else "unknown"


def tool_versions() -> dict[str, str | None]:
    try:
        import cocotb

        cocotb_version = cocotb.__version__
    except ImportError:
        cocotb_version = None

    return {
        "cocotb": cocotb_version,
        "icarus": _cmd_version(["iverilog", "-V"], r"version (\S+)"),
        "verilator": _cmd_version(["verilator", "--version"], r"Verilator (\S+)"),
        "python": sys.version.split()[0],
    }


def git_commit() -> str:
    try:
        return subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=REPO, capture_output=True, text=True, check=True
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def parse_results(results_xml: Path) -> list[dict[str, str]]:
    tests = []
    for case in ET.parse(results_xml).getroot().iter("testcase"):
        failed = case.find("failure") is not None or case.find("error") is not None
        tests.append({"name": case.get("name", "?"), "result": "fail" if failed else "pass"})
    return tests


def run_leg(args, dut: Path, sub: str, seed: int) -> list[dict[str, str]]:
    from cocotb_tools.runner import get_runner

    build_dir = args.test_dir / "sim_build" / sub
    runner = get_runner("icarus")
    runner.build(
        verilog_sources=[dut],
        hdl_toplevel=args.toplevel,
        build_dir=build_dir,
        always=True,
        build_args=["-g2005"],  # Verilog-2005, no vendor extensions
        timescale=("1ns", "1ps"),
    )
    results_xml = runner.test(
        test_module=args.module,
        hdl_toplevel=args.toplevel,
        build_dir=build_dir,
        test_dir=args.test_dir,
        seed=seed,
    )
    return parse_results(Path(results_xml))


def _expand_runs(table: dict) -> list[dict]:
    """Expand `cases_from` entries ('<case> <design>' per line) into one run each."""
    runs = []
    for entry in table["runs"]:
        src = entry.get("cases_from")
        if src is None:
            runs.append(entry)
            continue
        for line in (REPO / src).read_text().splitlines():
            if not line.strip():
                continue
            case, design = line.split()
            sub = {k: v for k, v in entry.items() if k != "cases_from"}
            sub["id"] = entry["id"].format(case=case, design=design)
            sub["plusargs"] = [a.format(case=case, design=design) for a in entry["plusargs"]]
            runs.append(sub)
    return runs


def _plusarg(arg: str) -> str:
    """Resolve a repo-relative path value in a +key=value plusarg against REPO."""
    key, sep, val = arg.partition("=")
    if sep and val.startswith(("verification/", "rtl/")):
        return f"{key}={REPO / val}"
    return arg


def run_vvp_leg(run: dict, sources: list[str], outdir: Path, timeout: int) -> dict:
    """Compile and run one bench; classify the verdict from its output."""
    outdir.mkdir(parents=True, exist_ok=True)
    vvp_file = outdir / "a.vvp"
    cmd = ["iverilog", *run["iverilog_args"]]
    for inc in run.get("includes", []):
        cmd += ["-I", str(REPO / inc)]
    cmd += ["-o", str(vvp_file), str(REPO / run["bench"]), *(str(REPO / s) for s in sources)]
    comp = subprocess.run(cmd, capture_output=True, text=True, cwd=REPO)
    if comp.returncode != 0:
        return {"result": "fail", "reason": "compile error", "detail": comp.stderr.strip()[-2000:]}
    args = [_plusarg(a) for a in run.get("plusargs", [])]
    try:
        sim = subprocess.run(["vvp", str(vvp_file), *args], capture_output=True, text=True, cwd=REPO, timeout=timeout)
    except subprocess.TimeoutExpired:
        return {"result": "fail", "reason": f"timeout after {timeout}s"}
    (outdir / "sim.log").write_text(sim.stdout + sim.stderr)
    lines = sim.stdout.splitlines()
    pass_lines = [l for l in lines if l.startswith("PASS:")]
    bad_lines = [l for l in lines if l.startswith(("FAIL", "ERROR"))]
    if sim.returncode != 0:
        reason = f"vvp exit {sim.returncode}"
    elif bad_lines:
        reason = bad_lines[0]
    elif not pass_lines:
        reason = "no PASS: verdict line (bench ended without a verdict)"
    else:
        return {"result": "pass", "verdict": pass_lines[-1]}
    return {"result": "fail", "reason": reason}


def main_vvp(args) -> int:
    table = json.loads(args.vvp.read_text())
    runs = _expand_runs(table)
    for r in runs:
        r["iverilog_args"] = table["iverilog_args"]
    ok = True
    results = []
    build = args.vvp.resolve().parent / "sim_build"
    for r in runs:
        print(f"=== {r['id']}: {r['bench']}")
        good = run_vvp_leg(r, r["sources"], build / r["id"] / "good", args.timeout)
        print(f"  good: {good['result'].upper()} {good.get('verdict', good.get('reason', ''))}")
        entry = {"id": r["id"], "bench": r["bench"], "plusargs": r.get("plusargs", []), "good": good}
        ok &= good["result"] == "pass"
        nc = r.get("negative_control")
        if nc:
            sources = [nc.get(s, s) for s in r["sources"]]
            broken = run_vvp_leg(r, sources, build / r["id"] / "broken", args.timeout)
            caught = broken["result"] == "fail"
            print(f"  negative control: {'correctly FAILED' if caught else 'DID NOT FAIL'} ({broken.get('reason', broken.get('verdict', ''))})")
            entry["negative_control"] = {"expected": "fail", "ok": caught, **broken}
            ok &= caught
        results.append(entry)
    result = {
        "table": str(args.vvp.resolve().relative_to(REPO)),
        "commit": git_commit(),
        "tools": tool_versions(),
        "runs": results,
        "excluded": table.get("excluded", []),
        "overall": "pass" if ok else "fail",
    }
    out = args.result or build / "result.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2) + "\n")
    npass = sum(e["good"]["result"] == "pass" for e in results)
    print(f"\n{npass}/{len(results)} bench runs passed; {len(table.get('excluded', []))} excluded; result: {out}\nOVERALL: {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    p.add_argument("test_dir", type=Path, nargs="?", help="test directory (see convention above)")
    p.add_argument("--vvp", type=Path, help="plain-Verilog bench table (see above); replaces test_dir")
    p.add_argument("--timeout", type=int, default=300, help="per-bench vvp timeout in seconds (--vvp)")
    p.add_argument("--module", help="cocotb module (default test_NAME)")
    p.add_argument("--toplevel", help="HDL toplevel (default NAME)")
    p.add_argument("--dut", type=Path, help="good DUT source (default <test_dir>/NAME.v)")
    p.add_argument("--broken", type=Path, help="broken DUT source (default negative_control/NAME_broken.v)")
    p.add_argument("--seed", type=int, help="random seed (default: random, recorded in result)")
    p.add_argument("--good-only", action="store_true", help="run only the good leg")
    p.add_argument("--broken-only", action="store_true", help="run only the negative-control leg")
    p.add_argument("--result", type=Path, help="result JSON path (default <test_dir>/sim_build/result.json)")
    args = p.parse_args()
    if args.vvp:
        for tool in ("iverilog", "vvp"):
            if shutil.which(tool) is None:
                print(f"ERROR: {tool} not found on PATH; install Icarus Verilog (see verification/README.md)", file=sys.stderr)
                return 2
        return main_vvp(args)
    if args.test_dir is None:
        p.error("test_dir is required unless --vvp is given")
    if args.good_only and args.broken_only:
        p.error("--good-only and --broken-only are mutually exclusive")

    args.test_dir = args.test_dir.resolve()
    name = args.test_dir.name
    args.module = args.module or f"test_{name}"
    args.toplevel = args.toplevel or name
    dut = (args.dut or args.test_dir / f"{name}.v").resolve()
    broken = (args.broken or args.test_dir / "negative_control" / f"{name}_broken.v").resolve()
    seed = args.seed if args.seed is not None else random.randrange(2**32)

    if shutil.which("iverilog") is None:
        print("ERROR: iverilog not found on PATH; install Icarus Verilog (see verification/README.md)", file=sys.stderr)
        return 2
    for src in ([] if args.broken_only else [dut]) + ([] if args.good_only else [broken]):
        if not src.is_file():
            print(f"ERROR: missing DUT source {src}", file=sys.stderr)
            return 2

    # Make the test module importable and pin cocotb's seed for reproduction.
    os.environ["PYTHONPATH"] = os.pathsep.join(filter(None, [str(args.test_dir), os.environ.get("PYTHONPATH")]))
    ok = True
    legs: dict[str, dict] = {}

    if not args.broken_only:
        print(f"=== good leg: {args.module} vs. {dut} (seed {seed}) ===")
        tests = run_leg(args, dut, "good", seed)
        nfail = sum(t["result"] == "fail" for t in tests)
        passed = bool(tests) and nfail == 0
        print(f"good DUT: {len(tests)} test(s), {nfail} failed")
        print("PASS: good DUT passed the bench." if passed else "FAIL: the good DUT must pass every test (and at least one must run).")
        legs["good"] = {"expected": "pass", "ok": passed, "tests": tests}
        ok &= passed

    if not args.good_only:
        print(f"=== negative control: {args.module} vs. {broken} (seed {seed}) ===")
        tests = run_leg(args, broken, "broken", seed)
        nfail = sum(t["result"] == "fail" for t in tests)
        failed = nfail > 0
        print(f"broken DUT: {len(tests)} test(s), {nfail} failed")
        print(
            f"PASS: negative control correctly failed ({nfail}/{len(tests)})."
            if failed
            else "FAIL: negative control did not fail -- this bench is not known to be able to fail."
        )
        legs["negative_control"] = {"expected": "fail", "ok": failed, "tests": tests}
        ok &= failed

    result = {
        "test_dir": str(args.test_dir.relative_to(REPO)) if args.test_dir.is_relative_to(REPO) else str(args.test_dir),
        "seed": seed,
        "commit": git_commit(),
        "tools": tool_versions(),
        "legs": legs,
        "overall": "pass" if ok else "fail",
    }
    out = args.result or args.test_dir / "sim_build" / "result.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2) + "\n")
    print(f"\nresult: {out}\nOVERALL: {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
