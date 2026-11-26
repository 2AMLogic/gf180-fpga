#!/usr/bin/env bash
# Record a FABulous generator run on the vendored description (ADR-0001's
# deferred question: does the pinned FABulous generate a gf180mcu fabric with
# no change to rtl/common/fabulous/?). Runs FABulous 2.2.0 (the version in
# rtl/common/fabulous/.FABulous/.env) through uvx on a scratch copy, so the
# vendored tree is never written; fails if the run changes any vendored file.
#
#   flow/tile/run-fabulous.sh    writes flow/tile/records/fabulous-gen.txt
#
# The generator runs under a pinned PYTHONHASHSEED (the caller's value is
# overridden): FABulous builds its tile list from a set, so without the pin
# the tile order in the log changes with every run (issue #201).
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../klt.sh" || exit 2
src="$here/../../rtl/common/fabulous"
ver="$(sed -n "s/^FAB_PROJ_VERSION='\(.*\)'/\1/p" "$src/.FABulous/.env")"
scratch="$(mktemp -d)" || exit 3
trap 'rm -rf "$scratch"' EXIT
hashseed=0

if ! cp -r "$src" "$scratch/proj"; then
  echo "run-fabulous: cannot copy vendored description" >&2
  exit 3
fi
( cd "$scratch/proj" &&
  env PYTHONHASHSEED="$hashseed" uvx --from "FABulous-FPGA==$ver" FABulous --log "$scratch/gen.log" script FABulous.tcl >/dev/null 2>&1 ) \
  || { echo "run-fabulous: generator failed (FABulous $ver)" >&2; exit 1; }

# Vendored files must be byte-identical after the run; files that only exist
# in the scratch copy are generated outputs and expected. Finish the walk
# before comparing so a partial list cannot certify the vendored tree.
if ! find "$src" -type f -print0 > "$scratch/inputs"; then
  echo "run-fabulous: cannot enumerate vendored inputs" >&2
  exit 3
fi
changed=0
while IFS= read -r -d '' orig; do
  rel="${orig#"$src"/}"
  run_copy="$scratch/proj/$rel"
  if [[ ! -e "$run_copy" ]]; then
    echo "run-fabulous: vendored input missing after the run: $rel" >&2
    changed=1
    continue
  elif [[ ! -f "$run_copy" ]]; then
    echo "run-fabulous: vendored input cannot be compared: $rel" >&2
    changed=1
    continue
  fi
  rc=0
  cmp -s "$orig" "$run_copy" || rc=$?
  if [[ $rc -eq 1 ]]; then
    echo "run-fabulous: vendored input changed: $rel" >&2
    changed=1
  elif [[ $rc -ne 0 ]]; then
    echo "run-fabulous: vendored input cannot be compared: $rel" >&2
    changed=1
  fi
done < "$scratch/inputs" || exit 3
if [[ $changed -ne 0 ]]; then
  echo "run-fabulous: vendored description changed under FABulous $ver" >&2
  exit 3
fi
mkdir -p "$here/records"
{ echo "# FABulous $ver generator run on rtl/common/fabulous (flow/tile/run-fabulous.sh)"
  echo "# exit 0; no vendored file differs after the run"
  echo "# PYTHONHASHSEED=$hashseed (pinned by the wrapper so the tile order in this log is reproducible)"
  sed -e "s#$scratch#<scratch>#g" -e 's#path: /[^ ]*/#path: <host>/#' "$scratch/gen.log"; } > "$here/records/fabulous-gen.txt"
klt env-provenance scan "$here/records/fabulous-gen.txt"
