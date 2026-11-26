#!/usr/bin/env bash
# Run the flow smoke (klt synthesize + klt place-and-route) on both candidate
# standard-cell libraries and write the JSON responses to flow/smoke/records/.
# Single-corner, local; this is not a grid.
# A failed stage is logged with klt's real exit status, leaves its record as it
# was, and makes the script exit non-zero (issue #209).
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pdk="$here/../pdk.json"
source "$here/../pdk-root.sh" || exit 2
PDK_ROOT="$(pdk_root_resolve)" || exit 2
export PDK_ROOT
export PDK="${PDK:-$(jq -er .smoke_variant "$pdk")}"

"$here/../setup-pdk.sh" --verify || exit 2
source "$here/../klt.sh" || exit 2
source "$here/../report-paths.sh" || exit 2

repo="$(git -C "$here" rev-parse --show-toplevel)"
pdk_root="$(cd "$PDK_ROOT" && pwd)"
# Stage output is collected in a scratch directory inside records/, so that
# publishing is a rename on one filesystem (atomic) rather than a copy that
# first unlinks the record it replaces.
scratch="$(mktemp -d "$here/records/.smoke-run.XXXXXX")" || exit 2
trap 'rm -rf "$scratch"' EXIT

# stage <library> <klt-command> <request> <record>
#   Run `klt <klt-command>` from the current directory, log its real exit
#   status, and publish its stdout as <record>, but only when klt exited 0. A
#   failed stage (an error on stderr only, or a partial document on stdout)
#   leaves a prior <record> byte-for-byte intact and an absent one absent.
#   Returns klt's status, or 1 when the record could not be published.
stage() {
  local lib="$1" cmd="$2" request="$3" record="$4" raw st
  raw="$scratch/$lib.$cmd.json"
  klt "$cmd" --format json "$request" > "$raw"
  st=$?
  echo "$lib $cmd exit=$st"
  if [[ $st -ne 0 ]]; then
    echo "run-smoke: $lib $cmd failed; ${record#"$here"/} not rewritten" >&2
    return "$st"
  fi
  # Records are committed evidence: strip host-absolute prefixes so they carry
  # repo-relative paths and a symbolic $PDK_ROOT only (klt env-provenance scan).
  # Rewritten into a second scratch file and renamed into place, so <record>
  # is only ever replaced by a complete document.
  report_path_rewrite "$repo" "$pdk_root" < "$raw" > "$raw.normalized" \
    && mv "$raw.normalized" "$record" && return 0
  echo "run-smoke: $lib $cmd record not published: ${record#"$here"/}" >&2
  return 1
}

rc=0
for lib in mcu7t5v0 mcu9t5v0; do
  ( cd "$here/$lib" || exit 1
    stage "$lib" synthesize synth.json "$here/records/$lib.synth.json" || exit 1
    # klt names the netlist dir by run id; pin a stable copy for the P&R request.
    mkdir -p netlist
    cp "$(ls -t .klt/synthesize/run-*/smoke_lut4_synth.v | head -n1)" netlist/smoke_lut4_synth.v \
      || { echo "run-smoke: $lib netlist stage failed; place-and-route skipped" >&2; exit 1; }
    stage "$lib" place-and-route par.json "$here/records/$lib.par.json" || exit 1 ) || rc=1
done

klt env-provenance scan "$here"/records/mcu*.json || rc=1
exit $rc
