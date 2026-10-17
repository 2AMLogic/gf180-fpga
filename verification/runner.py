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
    import cocotb

    return {
        "cocotb": cocotb.__version__,
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


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    p.add_argument("test_dir", type=Path, help="test directory (see convention above)")
    p.add_argument("--module", help="cocotb module (default test_NAME)")
    p.add_argument("--toplevel", help="HDL toplevel (default NAME)")
    p.add_argument("--dut", type=Path, help="good DUT source (default <test_dir>/NAME.v)")
    p.add_argument("--broken", type=Path, help="broken DUT source (default negative_control/NAME_broken.v)")
    p.add_argument("--seed", type=int, help="random seed (default: random, recorded in result)")
    p.add_argument("--good-only", action="store_true", help="run only the good leg")
    p.add_argument("--broken-only", action="store_true", help="run only the negative-control leg")
    p.add_argument("--result", type=Path, help="result JSON path (default <test_dir>/sim_build/result.json)")
    args = p.parse_args()
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
