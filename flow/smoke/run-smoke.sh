#!/usr/bin/env bash
# Run the flow smoke (klt synthesize + klt place-and-route) on both candidate
# standard-cell libraries and write the JSON responses to flow/smoke/records/.
# Single-corner, local; this is not a grid.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pdk="$here/../pdk.json"
export PDK_ROOT="${PDK_ROOT:-$here/../.pdk-root}"
export PDK="${PDK:-$(jq -er .smoke_variant "$pdk")}"

"$here/../setup-pdk.sh" --verify || exit 2

rc=0
for lib in mcu7t5v0 mcu9t5v0; do
  ( cd "$here/$lib" || exit 1
    klt synthesize --format json synth.json > "$here/records/$lib.synth.json"
    echo "$lib synthesize exit=$?"
    # klt names the netlist dir by run id; pin a stable copy for the P&R request.
    mkdir -p netlist
    cp "$(ls -t .klt/synthesize/run-*/smoke_lut4_synth.v | head -n1)" netlist/smoke_lut4_synth.v
    klt place-and-route --format json par.json > "$here/records/$lib.par.json"
    echo "$lib place-and-route exit=$?" ) || rc=1
done

# Records are committed evidence: strip host-absolute prefixes so they carry
# repo-relative paths and a symbolic $PDK_ROOT only (klt env-provenance scan).
repo="$(git -C "$here" rev-parse --show-toplevel)"
pdk_root="$(cd "$PDK_ROOT" && pwd)"
for f in "$here"/records/mcu*.json; do
  sed -i -e "s#$repo/##g" -e "s#$pdk_root#\$PDK_ROOT#g" "$f"
done
klt env-provenance scan "$here"/records/mcu*.json || rc=1
exit $rc
