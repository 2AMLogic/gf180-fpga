#!/usr/bin/env bash
# Supply ERC of the routed tile (T1 item 11, issue #30).
#
#   layout/run-erc.sh           # regenerate layout/records/erc.json
#   layout/run-erc.sh --check   # klt erc --check on the committed report
#
# Run from the repo root so the repo-relative layout/spec paths are the ones
# klt records and --check re-hashes. One local single-cell run (not a grid).
# Needs no PDK: the stackup is declared in layout/records/erc-supply-spec.json.
# --findings-only --compact: the supply, tie and floating-gate findings are the
# item 11 evidence; the antenna half is not graded here (erc_status is the
# verdict, the exit code is 4 on a clean run without --pdk).
set -uo pipefail

root="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
cd "$root" || exit 1
source "$root/flow/klt.sh" || exit 2
spec=layout/records/erc-supply-spec.json
report=layout/records/erc.json

if [[ "${1:-}" == "--check" ]]; then
  klt erc --check "$report"
  exit $?
fi

klt erc --validate-spec "$spec" > /dev/null || exit 1
klt erc layout/logic_tile_routed.gds "$spec" --top logic_tile_routed \
  --findings-only --compact --format json > "$report"
rc=$?
status="$(jq -r .erc_status "$report")"
echo "klt erc exit=$rc erc_status=$status (4 clean without --pdk, 3 violations)"
[[ "$status" == "clean" ]]
