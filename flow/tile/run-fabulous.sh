#!/usr/bin/env bash
# Record a FABulous generator run on the vendored description (ADR-0001's
# deferred question: does the pinned FABulous generate a gf180mcu fabric with
# no change to rtl/common/fabulous/?). Runs FABulous 2.2.0 (the version in
# rtl/common/fabulous/.FABulous/.env) through uvx on a scratch copy, so the
# vendored tree is never written; fails if the run changes any vendored file.
#
#   flow/tile/run-fabulous.sh    writes flow/tile/records/fabulous-gen.txt
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/../../rtl/common/fabulous"
ver="$(sed -n "s/^FAB_PROJ_VERSION='\(.*\)'/\1/p" "$src/.FABulous/.env")"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

cp -r "$src" "$scratch/proj"
( cd "$scratch/proj" &&
  uvx --from "FABulous-FPGA==$ver" FABulous --log "$scratch/gen.log" script FABulous.tcl >/dev/null 2>&1 ) \
  || { echo "run-fabulous: generator failed (FABulous $ver)" >&2; exit 1; }

# Vendored files must be byte-identical after the run; generated outputs
# ("Only in") are expected.
if diff -rq "$src" "$scratch/proj" | grep -v '^Only in'; then
  echo "run-fabulous: vendored description changed under FABulous $ver" >&2
  exit 3
fi
mkdir -p "$here/records"
{ echo "# FABulous $ver generator run on rtl/common/fabulous (flow/tile/run-fabulous.sh)"
  echo "# exit 0; no vendored file differs after the run"
  sed -e "s#$scratch#<scratch>#g" -e 's#path: /[^ ]*/#path: <host>/#' "$scratch/gen.log"; } > "$here/records/fabulous-gen.txt"
klt env-provenance scan "$here/records/fabulous-gen.txt"
