#!/usr/bin/env bash
# Place and route logic_tile_routed (ladder step 0: gf180mcu_fd_sc_mcu7t5v0,
# gf180mcuD, tt_025C_5v00) and pin the routed stream under layout/.
#
#   layout/run-par.sh           # regenerate par.json, run klt, write records
#   layout/run-par.sh --check   # klt place-and-route --check against the record
#
# Single local run (not a grid). Run from anywhere; klt is invoked from the
# repo root because OpenROAD only mounts the invocation directory and the
# netlist lives under flow/.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(git -C "$here" rev-parse --show-toplevel)"
export PDK_ROOT="${PDK_ROOT:-$root/flow/.pdk-root}"
export PDK="${PDK:-$(jq -er .smoke_variant "$root/flow/pdk.json")}"
"$root/flow/setup-pdk.sh" --verify || exit 2
cd "$root" || exit 1
source "$root/flow/klt.sh" || exit 2

if [[ "${1:-}" == "--check" ]]; then
  klt place-and-route --check layout/records/step0-par.json layout/par.json
  exit $?
fi

# Tile core: 190 sites x 27 rows of the 7-track library (106.40 x 105.84 um).
# Last argument is power.tapcell.distance_um: the staggered tap-column spacing,
# about twice the worst-case Comp-to-tap distance it yields, so 24 um keeps the
# routed tile under the 15 um MV limit of comp.tap_distance.{nwell,psub}.mv.1
# (40 um gave 19.75 um measured and 46 DRC violations, issue #55).
python3 -I layout/make-request.py layout/par.json ../flow/tile/netlist/logic_tile_routed_synth.v \
  gf180mcu_fd_sc_mcu7t5v0 GF018hv5v_mcu_sc7 gf180mcu_7t_6M \
  0.56 3.92 190 27 24 || exit 1

rm -rf layout/.klt
mkdir -p layout/records
klt place-and-route --format json layout/par.json > layout/records/step0-par.json
rc=$?
echo "place-and-route exit=$rc"
[[ $rc -eq 0 ]] || exit $rc

out=layout/.klt/place-and-route
cp "$out/logic_tile_routed.gds" layout/logic_tile_routed.gds
cp "$out/logic_tile_routed.def" layout/logic_tile_routed.def
cp "$out/logic_tile_routed.v" layout/logic_tile_routed_routed.v

# Records are committed evidence: repo-relative paths, symbolic $PDK_ROOT.
pdk_root="$(cd "$PDK_ROOT" && pwd)"
sed -i -e "s#$root/##g" -e "s#$pdk_root#\$PDK_ROOT#g" layout/records/step0-par.json
klt env-provenance scan layout/records/step0-par.json

# 2x2 abutment: neighbour placed one tile pitch over on each axis.
kbin="$(klt_bin_dir)" || exit 1
PATH="$kbin:$PATH" "$kbin/python" -I layout/abut-check.py layout/logic_tile_routed.gds \
  layout/.klt/abut > layout/records/abutment.json || exit 1
