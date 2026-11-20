#!/usr/bin/env bash
# flow/blinky.sh -- the one-command blinky demo for THIS repo (issue #144):
# RTL -> bitstream -> simulated blinking output, open tools only, from a
# clean checkout. The newcomer's reproducible path; README.md "Tool flow"
# points here.
#
# The flow itself is PDK-independent and is NOT re-written here: it is
# stamped verbatim from sky130-fpga at the reuse.lock.json commit into
# flow/common/ (byte-held; ADR-0005). The stamped scripts address the
# sibling's own tree layout (design/, sim/), so this wrapper builds a
# throwaway staging tree under flow/build/stage/ that reproduces that layout
# with symlinks into this repo's stamped trees (rtl/common/...,
# verification/common/...) and runs the stamped flow/common/blinky.sh there
# UNMODIFIED. No vendored file is edited or written through; all generated
# output stays under flow/build/ (git-ignored).
#
# The staged script downloads the pinned OSS CAD Suite (~750 MB, sha256-
# verified) into flow/build/dl/ on the first run, regenerates the fabric
# model with the pinned FABulous (throwaway venv, flow/build/), maps
# blinky.v with yosys + nextpnr-generic, assembles the frame stream
# (byte-compared with FABulous's own bit_gen) and loads it into the stamped
# self-checking bench (+design=blinky +mutate: reset-to-0 then a toggle every
# clock, and every used routing/BEL bit flipped with each flip required to be
# detected -- the built-in negative control). It exits nonzero unless the
# bench reports its terminal PASS line, so a bitstream that does not blink
# fails the command. EXPERIMENTAL single-LOGIC4 harness (not the ratified
# fabric); a functional bitstream-level result only -- no timing claim.
#
# On success this wrapper writes flow/records/blinky.json: the tool versions
# the run itself verified against the pins, the wall clock, and the
# bitstream sha256 -- the machine-readable record behind flow/README.md's
# figures.
#
# Prerequisites on PATH (checked, never skipped): bash, python3 (with
# tkinter: FABulous imports it at load), uv, curl, tar, sha256sum, timeout,
# iverilog, vvp. Nothing is installed host-wide.
#
# Usage: ./flow/blinky.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGE="$ROOT/flow/build/stage"
DL="$ROOT/flow/build/dl"

for t in python3 uv curl tar sha256sum timeout iverilog vvp; do
    command -v "$t" >/dev/null 2>&1 || {
        echo "error: $t not found on PATH; blinky NOT RUN (see flow/README.md 'The one-command blinky demo' for the prerequisites)" >&2
        exit 2
    }
done

# --- staging tree: the sibling layout over this repo's stamped files -------
# design/rtl and design/fabulous map whole-directory; sim/ splits across
# verification/common/ (the benches) and verification/common/bitstream/ (the
# committed fixtures the staged flow byte-compares its regenerated model
# against). The flow scripts themselves are COPIED into the stage (not
# symlinked): two of them derive their tree root from __file__.resolve(),
# which would follow a symlink back into flow/common/ and break the staged
# layout. Copies are refreshed from flow/common/ on every run, so a
# re-stamp is picked up and the bytes that run are still the stamped bytes.
mkdir -p "$STAGE/design" "$STAGE/sim" "$STAGE/flow/build" "$DL"
ln -sfn "$ROOT/rtl/common/rtl"                            "$STAGE/design/rtl"
ln -sfn "$ROOT/rtl/common/fabulous"                       "$STAGE/design/fabulous"
ln -sfn "$ROOT/verification/common/tb_logic_tile_bitstream.v" "$STAGE/sim/tb_logic_tile_bitstream.v"
ln -sfn "$ROOT/verification/common/bitstream_corrupt.py"  "$STAGE/sim/bitstream_corrupt.py"
ln -sfn "$ROOT/verification/common/bitstream"             "$STAGE/sim/bitstream"
for f in "$ROOT"/flow/common/*; do
    [[ -f "$f" ]] || continue   # files only: __pycache__/ never stages
    t="$STAGE/flow/$(basename "$f")"
    rm -f "$t"                  # replace any stale entry (never write through)
    cp -p "$f" "$t"
done
# keep the pinned-tool tarball at a stable path so warm runs (and the CI
# cache) reuse it across staging rebuilds
ln -sfn "$DL" "$STAGE/flow/build/dl"

# --- run the stamped flow, verbatim ----------------------------------------
# shellcheck source=/dev/null   # vendored, byte-held by reuse.lock.json
source "$ROOT/flow/common/tool_versions.sh"   # pins only; prints nothing
FETCHED=0
[[ -f "$DL/$RECORDED_OSS_CAD_TARBALL" ]] || FETCHED=1
SECONDS=0
"$STAGE/flow/blinky.sh"

# --- record (committed evidence: flow/records/blinky.json) -----------------
python3 - "$ROOT" "$STAGE" "$SECONDS" "$FETCHED" "$RECORDED_YOSYS_VERSION" \
         "$RECORDED_NEXTPNR_VERSION" "$RECORDED_FABULOUS_VERSION" \
         "$RECORDED_OSS_CAD_TAG" "$RECORDED_OSS_CAD_TARBALL" \
         "$RECORDED_OSS_CAD_SHA256" <<'PY'
import datetime, hashlib, json, os, platform, re, subprocess, sys

root, stage, seconds, fetched, yosys, nextpnr, fab, oss_tag, oss_tgz, oss_sha = sys.argv[1:]
lock = json.load(open(os.path.join(root, "reuse.lock.json")))
def ver(argv, pat):
    try:
        p = subprocess.run(argv, capture_output=True, text=True, timeout=30)
        m = re.search(pat, p.stdout + p.stderr)
        return m.group(1) if m else "unknown"
    except Exception:
        return "unknown"
bitstream = os.path.join(stage, "flow/build/blinky-run/blinky.bin")
record = {
    "_comment": "Written by ./flow/blinky.sh on every successful run (issue #144). "
                "The staged flow verified yosys/nextpnr against the pins at run time; "
                "the benches run under the OSS CAD Suite's iverilog (tools.iverilog; the "
                "host iverilog recorded as iverilog_host_prereq only satisfies the "
                "staged script's PATH check before the suite is unpacked). Wall clock is "
                "tool wall-clock on this machine, not a fabric timing claim.",
    "schema": "blinky-record/1",
    "date_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
    "command": "./flow/blinky.sh",
    "source": {
        "repo": lock["source"]["repo"],
        "commit": lock["source"]["commit"],
        "stamped_flow": "flow/common/ (ADR-0005)",
    },
    "harness": "experimental single-LOGIC4 (not the ratified fabric); functional "
               "bitstream-level result only, no timing claim",
    "tools": {
        "yosys": yosys,
        "nextpnr_generic": nextpnr,
        "oss_cad_suite": {"tag": oss_tag, "tarball": oss_tgz, "sha256": oss_sha},
        "FABulous": fab,
        "iverilog": ver([os.path.join(stage, "flow/build/oss-cad-suite/bin/iverilog"), "-V"], r"version (\S+)"),
        "iverilog_host_prereq": ver(["iverilog", "-V"], r"version (\S+)"),
        "uv": ver(["uv", "--version"], r"uv (\S+)"),
        "python3": ver(["python3", "--version"], r"Python (\S+)"),
    },
    "wall_clock_s": int(seconds),
    "tool_fetch": "fetched-this-run" if fetched == "1" else "cached",
    "bitstream_sha256": hashlib.sha256(open(bitstream, "rb").read()).hexdigest()
        if os.path.isfile(bitstream) else None,
    "machine": {
        "os": platform.platform(),
        "cpu": platform.processor() or "unknown",
        "nproc": os.cpu_count(),
    },
}
out = os.path.join(root, "flow/records")
os.makedirs(out, exist_ok=True)
with open(os.path.join(out, "blinky.json"), "w") as f:
    json.dump(record, f, indent=2)
    f.write("\n")
print("recorded flow/records/blinky.json")
PY
