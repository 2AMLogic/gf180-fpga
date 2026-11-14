#!/usr/bin/env bash
# Gate-level LVS of the routed tile (T1 item 4, issue #24).
#
#   layout/run-lvs.sh           # regenerate layout/records/lvs*.json
#   layout/run-lvs.sh --check   # klt lvs --check on both committed reports
#
# The request is read on stdin from the repo root, so the repo-relative paths
# inside layout/records/lvs*-request.json are the ones klt records and --check
# re-hashes. Two single local compares (not a grid):
#   lvs.json          layout GDS vs the as-built netlist from the same
#                     place-and-route run (logic_tile_routed_routed.v). Item 4 cites this.
#   lvs-vs-synth.json layout GDS vs the pre-P&R synthesized netlist (#21).
#                     Expected `mismatch`; kept as evidence of why it is not the reference.
# Needs the pinned PDK (flow/setup-pdk.sh) for the library pin order and deck.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(git -C "$here" rev-parse --show-toplevel)"
source "$root/flow/pdk-root.sh" || exit 2
PDK_ROOT="$(pdk_root_resolve)" || exit 2
export PDK_ROOT
export PDK="${PDK:-$(jq -er .smoke_variant "$root/flow/pdk.json")}"
"$root/flow/setup-pdk.sh" --verify || exit 2
cd "$root" || exit 1
source "$root/flow/klt.sh" || exit 2

if [[ "${1:-}" == "--check" ]]; then
  rc=0
  for r in lvs lvs-vs-synth; do
    klt lvs --check "layout/records/$r.json" || rc=$?
  done
  exit $rc
fi

pdk_root="$(cd "$PDK_ROOT" && pwd)"
for r in lvs lvs-vs-synth; do
  klt lvs - --format json < "layout/records/$r-request.json" > "layout/records/$r.json"
  echo "$r: klt lvs exit=$? (0 match, 3 mismatch)"
  sed -i "s#$pdk_root#\$PDK_ROOT#g" "layout/records/$r.json"
  klt env-provenance scan "layout/records/$r.json"
done
