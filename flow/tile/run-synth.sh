#!/usr/bin/env bash
# T1 item 1 (design sources): synthesize logic_tile_routed onto
# gf180mcu_fd_sc_mcu7t5v0 at tt_025C_5v00 and pin the gate-level netlist.
#
#   flow/tile/run-synth.sh           regenerate netlist/ and records/ in place
#   flow/tile/run-synth.sh --check   re-synthesize into a scratch dir and exit
#                                    3 if the committed netlist is stale;
#                                    writes nothing under flow/tile/
#
# Single local `klt synthesize` run; not a grid. Needs the pinned PDK
# (flow/setup-pdk.sh) plus jq, yosys and klt on PATH.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PDK_ROOT="${PDK_ROOT:-$here/../.pdk-root}"
export PDK="${PDK:-$(jq -er .smoke_variant "$here/../pdk.json")}"
check=0
[[ "${1:-}" == "--check" ]] && check=1

"$here/../setup-pdk.sh" --verify || exit 2

repo="$(git -C "$here" rev-parse --show-toplevel)"
pdk_root="$(cd "$PDK_ROOT" && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

# klt resolves sources relative to the request and writes .klt/ beside it, so
# run from a scratch copy of the request laid out like flow/tile/.
mkdir -p "$scratch/flow/tile"
cp "$here/synth.json" "$scratch/flow/tile/synth.json"
ln -s "$repo/rtl" "$scratch/rtl"
( cd "$scratch/flow/tile" && git init -q . >/dev/null 2>&1
  klt synthesize --format json synth.json > "$scratch/resp.json" ) || {
  echo "run-synth: klt synthesize failed" >&2; exit 1; }

net="$(ls -t "$scratch"/flow/tile/.klt/synthesize/run-*/logic_tile_routed_synth.v | head -n1)"

if [[ $check -eq 1 ]]; then
  cmp -s "$net" "$here/netlist/logic_tile_routed_synth.v" && exit 0
  echo "run-synth: committed netlist is stale vs. re-synthesis" >&2
  exit 3
fi

mkdir -p "$here/netlist" "$here/records"
cp "$net" "$here/netlist/logic_tile_routed_synth.v"
# Records are committed evidence: repo-relative paths, symbolic $PDK_ROOT,
# and no per-run scratch location (klt env-provenance scan).
sed -e "s#$scratch/##g" -e "s#$repo/##g" -e "s#$pdk_root#\$PDK_ROOT#g" \
  "$scratch/resp.json" > "$here/records/synth.json"
klt env-provenance scan "$here/records/synth.json"
