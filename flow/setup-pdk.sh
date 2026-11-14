#!/usr/bin/env bash
# Install the pinned gf180mcu PDK (flow/pdk.json) with ciel and verify it.
#
#   flow/setup-pdk.sh            install into the resolved root (see below)
#   flow/setup-pdk.sh --verify   verify only; never install
#
# Which root is used is decided in one place, flow/pdk-root.sh: an explicit
# $PDK_ROOT, else an install already in flow/.pdk-root, else ciel's own store
# (${CIEL_PDK_ROOT:-$HOME/.ciel}) when it already satisfies the pin, else
# flow/.pdk-root as the install target. Adopting an already-correct ciel store
# skips `ciel enable` entirely, so a host that has the PDK does not re-fetch
# 3.6 GB of it (issue #79).
#
# Fails (exit 2) if any variant's SOURCES revision differs from the pin, so a
# leftover install at another revision is never picked up silently -- and never
# reached past in favour of the shared store either. ciel runs through
# `uvx --from ciel==<pin>` unless a ciel at exactly that version is on PATH;
# nothing is installed host-wide.
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

source "$here/pdk-root.sh"
pdk_root_select
export PDK_ROOT="$PDK_ROOT_RESOLVED"

# An adopted ciel store is already at the pin (pdk_root_select just checked it),
# so there is nothing to install; every other root installs as before.
if [[ $verify_only -eq 0 && "$PDK_ROOT_SOURCE" != "shared" ]]; then
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

if ! pdk_revision_ok -v "$PDK_ROOT"; then
  echo "setup-pdk: FAILED: $PDK_ROOT does not match flow/pdk.json" >&2
  exit 2
fi
echo "setup-pdk: OK: $PDK_ROOT is open_pdks $rev (${variants[*]})"
