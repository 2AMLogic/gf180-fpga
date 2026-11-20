#!/usr/bin/env bash
# Re-measure T1 item 5 on the committed 24 um-pitch routed stream (issue #160,
# measurement carve-out from #27). Produces, in this directory:
#
#   extract.report.json + logic_tile_routed.spef   klt extract --parasitics
#                                                   --spef --def-net-names
#                                                   --def-net-connections
#                                                   (the 2026-11-05 options)
#   sta-lef-only.report.json                        klt sta, 15 corners,
#                                                   from the committed request
#   sta-spef.report.json                            klt sta, 15 corners, SPEF,
#                                                   from the committed request
#   sta-noncfg-{lef-only,spef}.{request,report}.json  diagnostic runs (only
#                                                   the graded failing corners)
#                                                   with constraints
#                                                   .false_path_from over every
#                                                   cfg[*] input port, so the
#                                                   reported worst path per
#                                                   corner is the worst path
#                                                   NOT starting at a cfg port
#                                                   (issue #160 step 6, via
#                                                   klt 0.9.0's own
#                                                   false_path_from field --
#                                                   klt#2968; the graded runs
#                                                   carry no exclusion).
#
# The pre-registered constraints (comment on #27, 2026-11-05) are copied
# byte-identically by the two committed sta-*.request.json records: 20 ns
# period on clk, I/O delays 0, ideal clock, all 15 gf180mcu_fd_sc_mcu7t5v0
# corners. Nothing here tunes or relaxes them.
#
# Designed to run as a repo-script job on the batch fleet's heavy image
# (repo-script-submit.py --wait-for-capacity 600), which carries OpenROAD and
# the gf180mcuD PDK at the pinned open_pdks revision; it also runs as-is on a
# dispatch worker with the PDK installed (flow/setup-pdk.sh). The klt pin
# (flow/pdk.json: klayout-tools==0.9.0, klayout==0.30.12) is forced here via
# flow/klt.sh (uvx) or, when uv is absent, a throwaway venv -- the image's own
# klt is never used. Do not bump the pin here (#102 owns that decision).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here/../.."

for tool in jq python3 openroad; do
  command -v "$tool" >/dev/null 2>&1 || { echo "::error::$tool is required" >&2; exit 2; }
done

# --- pinned klt, independent of whatever klt the host/image carries ----------
if command -v uvx >/dev/null 2>&1; then
  # shellcheck disable=SC1091
  source flow/klt.sh
else
  venv="$(mktemp -d)/klt-pin"
  python3 -m venv "$venv"
  "$venv/bin/pip" install --quiet "$(jq -er .klt_spec flow/pdk.json)" "$(jq -er .klayout_spec flow/pdk.json)"
  klt() { "$venv/bin/klt" "$@"; }
fi
klt --version
openroad -version || true

# --- PDK: the image's bake-time root, asserted against the flow/pdk.json pin --
# (pdk_revision_ok in flow/pdk-root.sh demands all four gf180mcu variants; the
# heavy image ships gf180mcuD only, so this checks exactly what these runs
# consume: gf180mcuD at the pinned open_pdks revision with the mcu7t5v0
# library. The reports themselves record provenance.pdk.version.)
PDK_ROOT="${PDK_ROOT:-/opt/pdk}"
rev="$(jq -er .open_pdks_revision flow/pdk.json)"
lib="$(jq -er '.libraries[0]' flow/pdk.json)"
src="$PDK_ROOT/gf180mcuD/SOURCES"
[[ -f "$src" ]] || { echo "::error::no gf180mcuD under $PDK_ROOT" >&2; exit 2; }
got="$(head -n1 "$src" | awk '{print $2}')"
[[ "$got" == "$rev" ]] || { echo "::error::gf180mcuD is open_pdks $got, pin is $rev" >&2; exit 2; }
[[ -d "$PDK_ROOT/gf180mcuD/libs.ref/$lib" ]] || { echo "::error::$lib missing under gf180mcuD" >&2; exit 2; }
echo "PDK: $PDK_ROOT/gf180mcuD at open_pdks $rev ($lib present)"

# --- 1. extract: committed GDS -> SPEF (2026-11-05 options) -------------------
scratch="$(mktemp -d)"
klt extract layout/logic_tile_routed.gds \
  --pdk gf180mcuD --pdk-root "$PDK_ROOT" \
  --parasitics --spef measurements/item5-24um/logic_tile_routed.spef \
  --def-net-names --def-net-connections layout/logic_tile_routed.def \
  -o "$scratch/logic_tile_routed.sp" \
  --format json > measurements/item5-24um/extract.report.json
rm -rf "$scratch"
echo "extract: $(jq -r .status measurements/item5-24um/extract.report.json), $(jq -r '.parasitics.nets | length' measurements/item5-24um/extract.report.json) parasitic nets"

# --- 2. graded 15-corner STA, LEF-only then SPEF ------------------------------
for run in lef-only spef; do
  klt sta "measurements/item5-24um/sta-$run.request.json" \
    --pdk gf180mcuD --pdk-root "$PDK_ROOT" \
    --format json > "measurements/item5-24um/sta-$run.report.json"
  echo "sta $run: $(jq -r .status measurements/item5-24um/sta-$run.report.json), $(jq -r '[.corners[] | select(.setup_violation_count > 0)] | length' measurements/item5-24um/sta-$run.report.json) setup-failing corners"
done

# --- 3. diagnostic non-cfg runs over the graded failing corners ---------------
python3 - <<'PY'
import json
from pathlib import Path

root = Path("measurements/item5-24um")

# every cfg[*] INPUT port, read from the committed DEF's PINS section
cfg = []
in_pins = False
for line in Path("layout/logic_tile_routed.def").read_text().splitlines():
    if line.startswith("PINS"):
        in_pins = True
        continue
    if in_pins and line.startswith("END PINS"):
        break
    if in_pins and line.lstrip().startswith("- ") and "DIRECTION INPUT" in line:
        name = line.split()[1]
        if name.startswith("cfg["):
            cfg.append(name)
cfg.sort(key=lambda s: int(s[4:-1]))
assert cfg, "no cfg input ports found in the DEF"

for run in ("lef-only", "spef"):
    graded = json.loads((root / f"sta-{run}.report.json").read_text())
    failing = [
        c["corner"] for c in graded["corners"]
        if c.get("setup_violation_count", 0) > 0
        or (c.get("worst_slack_ns") is not None and c["worst_slack_ns"] < 0)
    ]
    req_path = root / f"sta-noncfg-{run}.request.json"
    if not failing:
        req_path.unlink(missing_ok=True)
        (root / f"sta-noncfg-{run}.report.json").unlink(missing_ok=True)
        print(f"noncfg {run}: no failing corner, no diagnostic run")
        continue
    req = json.loads((root / f"sta-{run}.request.json").read_text())
    req["pdk"]["corners"] = failing
    req["constraints"]["false_path_from"] = cfg
    req_path.write_text(json.dumps(req, indent=2) + "\n")
    print(f"noncfg {run}: {len(cfg)} cfg ports false-pathed, corners {failing}")
PY
for run in lef-only spef; do
  req="measurements/item5-24um/sta-noncfg-$run.request.json"
  [[ -f "$req" ]] || continue
  klt sta "$req" --pdk gf180mcuD --pdk-root "$PDK_ROOT" \
    --format json > "measurements/item5-24um/sta-noncfg-$run.report.json"
  echo "sta noncfg $run: done"
done

# --- 4. assertions: status, corner census, stream binding ---------------------
python3 - <<'PY'
import hashlib, json
from pathlib import Path

def sha(p):
    return "sha256:" + hashlib.sha256(Path(p).read_bytes()).hexdigest()

root = Path("measurements/item5-24um")
gds, deff = sha("layout/logic_tile_routed.gds"), sha("layout/logic_tile_routed.def")

ex = json.loads((root / "extract.report.json").read_text())
assert ex["provenance"]["input"]["content_hash"] == gds, \
    "extract report is not bound to the committed GDS"

for name in ("sta-lef-only.report.json", "sta-spef.report.json"):
    rep = json.loads((root / name).read_text())
    assert rep["status"] == "ok", (name, rep["status"])
    assert rep["provenance"]["input"]["content_hash"] == deff, \
        f"{name} is not bound to the committed DEF"
    assert len(rep["corners"]) == 15, (name, len(rep["corners"]))
    bad = [c["corner"] for c in rep["corners"] if c["timing_status"] != "constrained"]
    assert not bad, (name, bad)
    failing = [
        (c["corner"], c["worst_slack_ns"]) for c in rep["corners"]
        if c.get("setup_violation_count", 0) > 0 or c["worst_slack_ns"] < 0
    ]
    print(f"{name}: 15/15 constrained, {len(failing)} setup-failing corners")
    for corner, wns in failing:
        print(f"  {corner}: worst_slack_ns {wns}")

for name in ("sta-noncfg-lef-only.report.json", "sta-noncfg-spef.report.json"):
    p = root / name
    if not p.is_file():
        continue
    rep = json.loads(p.read_text())
    assert rep["status"] == "ok", (name, rep["status"])
    assert rep["provenance"]["input"]["content_hash"] == deff, name
    for c in rep["corners"]:
        assert not c["worst_setup_path"]["startpoint"].startswith("cfg["), \
            (name, c["corner"], c["worst_setup_path"]["startpoint"])
        print(f"noncfg {name} {c['corner']}: worst non-cfg path "
              f"{c['worst_setup_path']['startpoint']} -> {c['worst_setup_path']['endpoint']}"
              f" slack {c['worst_setup_path']['slack_ns']}")
PY

# --- 5. drop the per-request klt scratch so the record dir collects clean -----
rm -rf measurements/item5-24um/.klt
echo "run-fleet: all records written"
