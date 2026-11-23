#!/usr/bin/env python3
"""Render (or check) the T1 item-9 testbench inventory from benches.json.

    python3 -I verification/item9/inventory.py            # write INVENTORY.md
    python3 -I verification/item9/inventory.py --check    # fail if stale

Also fails if a stamped testbench (tb_*.v under verification/common or
rtl/common) is neither run nor excluded in benches.json, so a newly stamped
bench cannot be silently left out of the inventory.

Also fails if verification/signoff/item9-inventory.json (the attested copy)
diverges from the files that own the facts it restates: the bench set, the
cold-start argv, the PDK revision and the Icarus version (pinned once in the
setup-icarus composite action both CI jobs share).

Also fails if a workflow under .github/workflows declares a second Icarus
pin of its own: an ICARUS_VERSION declaration, an icarus-version override
at a setup-icarus call site, a workflow-local Icarus cache key or a clone
of steveicarus/iverilog. The setup-icarus action owns all four, so the
declaration itself is the violation even when its value matches the action
default (#158).
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
TABLE = HERE / "benches.json"
OUT = HERE / "INVENTORY.md"
SIGNED_OFF = ROOT / "verification" / "signoff" / "item9-inventory.json"
WORKFLOW = ROOT / ".github" / "workflows" / "verification.yml"
WORKFLOWS_DIR = ROOT / ".github" / "workflows"
ACTION = ROOT / ".github" / "actions" / "setup-icarus" / "action.yml"
IVERILOG_REPO = "steveicarus/iverilog"
COLD_START = "python3 -I verification/runner.py --vvp verification/item9/benches.json"
COLD_START_TOOLS = {"icarus"}   # tools the attested argv invokes


def icarus_pin():
    """Read the single CI Icarus pin from the shared setup-icarus action.

    Both CI jobs get their Icarus build from ACTION, whose icarus-version
    input default is the one place the version is declared; the attested pin
    is asserted against it. Returns the version string, or None after
    printing an error naming the pattern it could not find: a scan that
    silently skips would guard nothing while still passing.
    """
    rel = ACTION.relative_to(ROOT)
    if not ACTION.is_file():
        print(f"ERROR: {rel} not found; cannot check the Icarus pin", file=sys.stderr)
        return None
    lines = ACTION.read_text().splitlines()
    start = None
    for i, line in enumerate(lines):
        if re.match(r"^[ \t]*icarus-version:[ \t]*$", line):
            start = i
            break
    if start is None:
        print(f"ERROR: icarus-version input not found in {rel}; cannot check the Icarus pin", file=sys.stderr)
        return None
    indent = re.match(r"^[ \t]*", lines[start]).group(0)
    default = None
    for line in lines[start + 1:]:
        if not line.strip():
            continue
        if len(line) - len(line.lstrip()) <= len(indent):
            break   # left the icarus-version input block without a default
        s = line.strip()
        if s.startswith("default:"):
            default = s[len("default:"):].strip().strip("\"'")
            break
    if default is None:
        print(f"ERROR: icarus-version input in {rel} has no default; cannot check the Icarus pin", file=sys.stderr)
        return None
    if not default:
        print(f"ERROR: icarus-version default in {rel} has an empty value; cannot check the Icarus pin", file=sys.stderr)
        return None
    return default


def _code_text(line):
    """Drop the comment tail so a comment naming a forbidden setting is
    not itself a declaration: '#' at line start or after whitespace opens
    a YAML or shell comment in every context the scan matches.
    """
    m = re.search(r"(?:^|[ \t])#", line)
    return line if m is None else line[:m.start()]


def workflow_local_pins():
    """Scan the CI workflows for a second Icarus pin or a copied setup recipe.

    The single CI Icarus pin is the setup-icarus action's icarus-version
    input default, and the action owns the cache, the iverilog clone and
    the ICARUS_VERSION export. A workflow that declares ICARUS_VERSION,
    overrides the icarus-version input at a call site, keys its own
    Icarus cache or clones iverilog itself is a second pin or a stale
    copy of the recipe (#158), and fails even when its value matches the
    action default. Reads of the exported variable (the result asserts),
    comments and unrelated cache steps do not match. Returns problem
    strings naming the workflow and line; a missing or empty workflows
    directory is itself a problem, a scan that silently skips would
    guard nothing while still passing.
    """
    rel_dir = WORKFLOWS_DIR.relative_to(ROOT)
    if not WORKFLOWS_DIR.is_dir():
        return [f"{rel_dir} not found; cannot check for workflow-local Icarus pins"]
    workflows = sorted(
        p for p in WORKFLOWS_DIR.iterdir()
        if p.is_file() and p.suffix in (".yml", ".yaml")
    )
    if not workflows:
        return [f"no *.yml or *.yaml workflow under {rel_dir}; cannot check for workflow-local Icarus pins"]
    problems = []
    for wf in workflows:
        rel = wf.relative_to(ROOT)
        for n, raw in enumerate(wf.read_text().splitlines(), 1):
            line = _code_text(raw)
            if re.match(r"^[ \t]*ICARUS_VERSION[ \t]*:", line) or re.search(r"\bICARUS_VERSION=", line):
                problems.append(f"{rel}:{n}: workflow-local ICARUS_VERSION declaration; the setup-icarus action owns the pin")
            elif re.match(r"^[ \t]*icarus-version[ \t]*:", line):
                problems.append(f"{rel}:{n}: caller override of the setup-icarus icarus-version input; change the action default, do not override it")
            elif (m := re.match(r"^[ \t]*key[ \t]*:[ \t]*(.*)$", line)) and "icarus" in m.group(1).lower():
                problems.append(f"{rel}:{n}: workflow-local Icarus cache key; the setup-icarus action owns the cache")
            elif IVERILOG_REPO in line and "clone" in line:
                problems.append(f"{rel}:{n}: workflow clones {IVERILOG_REPO} itself; the setup-icarus action owns the build")
    return problems


def cold_start_argv():
    """Parse the cold-start argv asserted against out of the CI workflow.

    Returns the argv list, or None after printing an error naming the
    pattern it could not find: a scan that silently skips would guard
    nothing while still passing.
    """
    rel = WORKFLOW.relative_to(ROOT)
    if not WORKFLOW.is_file():
        print(f"ERROR: {rel} not found; cannot check the cold-start argv", file=sys.stderr)
        return None
    text = WORKFLOW.read_text()
    lines = text.splitlines()
    start = None
    for i, line in enumerate(lines):
        s = line.strip()
        if s.startswith("- name:") and "Stamped benches" in s:
            start = i + 1
            break
    if start is None:
        print(f"ERROR: 'Stamped benches' step not found in {rel}; cannot check the cold-start argv", file=sys.stderr)
        return None
    for line in lines[start:]:
        s = line.strip()
        if s.startswith("- name:"):
            break
        if s.startswith("run:"):
            value = s[len("run:"):].strip()
            if not value or value in ("|", ">"):
                print(f"ERROR: 'Stamped benches' run: in {rel} is not a single-line command; cannot check the cold-start argv", file=sys.stderr)
                return None
            return value.split()
    print(f"ERROR: 'Stamped benches' step in {rel} has no run: line; cannot check the cold-start argv", file=sys.stderr)
    return None


def main(argv):
    table = json.loads(TABLE.read_text())
    pdk = json.loads((ROOT / "flow" / "pdk.json").read_text())
    runs, excluded = table["runs"], table["excluded"]

    on_disk = {
        str(p.relative_to(ROOT))
        for d in ("verification/common", "rtl/common")
        for p in (ROOT / d).rglob("tb_*.v")
    }
    icarus = icarus_pin()
    wf_argv = cold_start_argv()
    # Run the workflow-local pin scan before the early return so its two
    # fail-closed arms (workflows directory absent, or holding no
    # *.yml/*.yaml) execute even when the pin or argv could not be read:
    # those shapes remove verification.yml, and a scan that silently
    # skipped would guard nothing while still passing (#170).
    pin_problems = workflow_local_pins()
    if icarus is None or wf_argv is None:
        if pin_problems:
            print("\n".join(f"ERROR: {p}" for p in pin_problems), file=sys.stderr)
        return 1
    attested = json.loads(SIGNED_OFF.read_text())

    run_benches = {r["bench"] for r in runs}
    excl_benches = {e["bench"] for e in excluded}
    problems = list(pin_problems)
    if run_benches & excl_benches:
        problems.append(f"both run and excluded: {sorted(run_benches & excl_benches)}")
    for missing in sorted(on_disk - run_benches - excl_benches):
        problems.append(f"stamped bench neither run nor excluded: {missing}")
    for ghost in sorted((run_benches | excl_benches) - on_disk):
        problems.append(f"listed bench not on disk: {ghost}")

    if sorted(attested["testbenches"]) != sorted(run_benches):
        problems.append(f"item9-inventory.json testbenches diverge from {TABLE.relative_to(ROOT)} runs[].bench")
    if attested["cold_start"]["argv"] != COLD_START.split():
        problems.append("item9-inventory.json cold_start.argv diverges from inventory.py COLD_START")
    if wf_argv != COLD_START.split():
        problems.append("verification.yml 'Stamped benches' run line diverges from inventory.py COLD_START")
    if attested["pins"]["pdk"]["revision"] != pdk["open_pdks_revision"]:
        problems.append("item9-inventory.json pins.pdk.revision diverges from flow/pdk.json open_pdks_revision")
    if attested["pins"]["tools"].get("icarus") != icarus:
        problems.append("item9-inventory.json pins.tools.icarus diverges from the setup-icarus action pin (.github/actions/setup-icarus/action.yml)")
    tools = set(attested["pins"]["tools"])
    for extra in sorted(tools - COLD_START_TOOLS):
        problems.append(f"item9-inventory.json pins a tool the cold start never invokes: {extra}")
    for missing in sorted(COLD_START_TOOLS - tools):
        problems.append(f"item9-inventory.json is missing a pin for {missing}")
    if problems:
        print("\n".join(f"ERROR: {p}" for p in problems), file=sys.stderr)
        return 1

    lines = [
        "# T1 item 9 -- testbench inventory",
        "",
        "Generated by `verification/item9/inventory.py` from `benches.json`; do not edit.",
        "",
        "## Cold start",
        "",
        "```sh",
        COLD_START,
        "```",
        "",
        "Needs Icarus Verilog (`iverilog`, `vvp`) on `PATH`; no cocotb. Writes",
        "`verification/item9/sim_build/result.json` (per-run pass/fail, the",
        "negative control, tool versions, commit). A missing simulator exits 2.",
        "",
        "## Pins",
        "",
        f"- PDK: {pdk['pdk_family']} @ open_pdks `{pdk['open_pdks_revision']}` (`flow/pdk.json`)",
        f"- Icarus Verilog {icarus} (`.github/actions/setup-icarus/action.yml`, the one CI pin)",
        "",
        "These benches are RTL-level and use no PDK data; the PDK pin is recorded",
        "for the flow they belong to, not because the simulation reads it.",
        "",
        "## Benches run",
        "",
        "| run id | bench | negative control |",
        "|---|---|---|",
    ]
    for r in runs:
        nc = "yes (must fail)" if r.get("negative_control") else "-"
        lines.append(f"| `{r['id']}` | `{r['bench']}` | {nc} |")
    lines += [
        "",
        "## Benches not run",
        "",
        "| bench | status | reason |",
        "|---|---|---|",
    ]
    for e in excluded:
        lines.append(f"| `{e['bench']}` | {e['status']} | {e['reason']} |")
    text = "\n".join(lines) + "\n"

    if "--check" in argv:
        if not OUT.is_file() or OUT.read_text() != text:
            print(f"ERROR: {OUT.relative_to(ROOT)} is stale; run verification/item9/inventory.py", file=sys.stderr)
            return 1
        print("inventory up to date")
        return 0
    OUT.write_text(text)
    print(f"wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
