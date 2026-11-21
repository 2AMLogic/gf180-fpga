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
ACTION = ROOT / ".github" / "actions" / "setup-icarus" / "action.yml"
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


def cold_start_argv():
    """Parse the cold-start argv asserted against out of the CI workflow.

    Returns the argv list, or None after printing an error naming the
    pattern it could not find: a scan that silently skips would guard
    nothing while still passing.
    """
    rel = WORKFLOW.relative_to(ROOT)
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
    if icarus is None or wf_argv is None:
        return 1
    attested = json.loads(SIGNED_OFF.read_text())

    run_benches = {r["bench"] for r in runs}
    excl_benches = {e["bench"] for e in excluded}
    problems = []
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
