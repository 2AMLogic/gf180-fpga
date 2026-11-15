#!/usr/bin/env python3
"""Render (or check) the T1 item-9 testbench inventory from benches.json.

    python3 -I verification/item9/inventory.py            # write INVENTORY.md
    python3 -I verification/item9/inventory.py --check    # fail if stale

Also fails if a stamped testbench (tb_*.v under verification/common or
rtl/common) is neither run nor excluded in benches.json, so a newly stamped
bench cannot be silently left out of the inventory.

Also fails if verification/signoff/item9-inventory.json (the attested copy)
diverges from the files that own the facts it restates: the bench set, the
cold-start argv, the PDK revision and the Icarus version.
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
COLD_START = "python3 -I verification/runner.py --vvp verification/item9/benches.json"
COLD_START_TOOLS = {"icarus"}   # tools the attested argv invokes
KNOWN_STALE_TOOLS = {"cocotb"}  # false pin in the attested JSON; #103 deletes it


def workflow_pins():
    """Parse the two pins asserted against out of the CI workflow.

    Returns (icarus_version, cold_start_argv), or None after printing an
    error naming the pattern it could not find: a scan that silently skips
    would guard nothing while still passing.
    """
    rel = WORKFLOW.relative_to(ROOT)
    text = WORKFLOW.read_text()
    m = re.search(r"^[ \t]*ICARUS_VERSION:[ \t]*(.+?)[ \t]*$", text, re.MULTILINE)
    if not m:
        print(f"ERROR: ICARUS_VERSION env line not found in {rel}; cannot check the Icarus pin", file=sys.stderr)
        return None
    icarus = m.group(1).strip().strip("\"'")
    if not icarus:
        print(f"ERROR: ICARUS_VERSION env line in {rel} has an empty value; cannot check the Icarus pin", file=sys.stderr)
        return None
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
            return icarus, value.split()
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
    wf = workflow_pins()
    if wf is None:
        return 1
    wf_icarus, wf_argv = wf
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
    if attested["pins"]["tools"].get("icarus") != wf_icarus:
        problems.append("item9-inventory.json pins.tools.icarus diverges from verification.yml ICARUS_VERSION")
    tools = set(attested["pins"]["tools"])
    for extra in sorted(tools - COLD_START_TOOLS - KNOWN_STALE_TOOLS):
        problems.append(f"item9-inventory.json pins a tool the cold start never invokes: {extra}")
    for missing in sorted(COLD_START_TOOLS - tools):
        problems.append(f"item9-inventory.json is missing a pin for {missing}")
    for retired in sorted(KNOWN_STALE_TOOLS - tools):
        problems.append(f"known-stale pin {retired} is gone; drop it from KNOWN_STALE_TOOLS (#103)")
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
        f"- Icarus Verilog {wf_icarus} (`verification.yml`)",
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
