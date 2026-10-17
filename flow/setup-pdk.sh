#!/usr/bin/env bash
# Install the pinned gf180mcu PDK (flow/pdk.json) with ciel and verify it.
#
#   flow/setup-pdk.sh            install into $PDK_ROOT (default flow/.pdk-root)
#   flow/setup-pdk.sh --verify   verify only; never install
#
# Fails (exit 2) if any variant's SOURCES revision differs from the pin, so a
# leftover install at another revision is never picked up silently. ciel runs
# through `uvx --from ciel==<pin>` unless a ciel at exactly that version is on
# PATH; nothing is installed host-wide.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pin="$here/pdk.json"
verify_only=0
[[ "${1:-}" == "--verify" ]] && verify_only=1

jqr() { jq -er "$1" "$pin"; }
rev="$(jqr .open_pdks_revision)"
family="$(jqr .pdk_family)"
ciel_ver="$(jqr .installer.version)"
mapfile -t variants < <(jqr '.variants[]')
mapfile -t libs < <(jqr '.libraries[]')

export PDK_ROOT="${PDK_ROOT:-$here/.pdk-root}"

check_revision() {
  local bad=0 v src got
  for v in "${variants[@]}"; do
    src="$PDK_ROOT/$v/SOURCES"
    if [[ ! -f "$src" ]]; then
      echo "setup-pdk: MISSING $src" >&2; bad=1; continue
    fi
    got="$(head -n1 "$src" | awk '{print $2}')"
    if [[ "$got" != "$rev" ]]; then
      echo "setup-pdk: REVISION MISMATCH for $v: found '$got', pin is '$rev' ($src)" >&2
      bad=1
    fi
    for l in "${libs[@]}"; do
      [[ -d "$PDK_ROOT/$v/libs.ref/$l" ]] || { echo "setup-pdk: MISSING library $l in $v" >&2; bad=1; }
    done
  done
  return $bad
}

if [[ $verify_only -eq 0 ]]; then
  if command -v ciel >/dev/null && [[ "$(ciel --version 2>/dev/null | head -n1)" == *"$ciel_ver"* ]]; then
    ciel=(ciel)
  else
    ciel=(uvx --from "ciel==$ciel_ver" ciel)
  fi
  inc=()
  for l in "${libs[@]}"; do inc+=(-l "$l"); done
  mkdir -p "$PDK_ROOT"
  "${ciel[@]}" enable --pdk-root "$PDK_ROOT" --pdk-family "$family" "${inc[@]}" "$rev"
fi

if ! check_revision; then
  echo "setup-pdk: FAILED: $PDK_ROOT does not match flow/pdk.json" >&2
  exit 2
fi
echo "setup-pdk: OK: $PDK_ROOT is open_pdks $rev (${variants[*]})"
