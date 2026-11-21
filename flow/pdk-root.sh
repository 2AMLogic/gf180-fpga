# Source this file; it defines pdk_revision_ok(), pdk_root_select() and
# pdk_root_resolve() -- the single place that decides which PDK root this repo
# uses. Everything is derived from the pin in flow/pdk.json, and nothing is
# installed host-wide. flow/setup-pdk.sh and every consumer that needs
# $PDK_ROOT delegate here instead of baking their own flow/.pdk-root default.
#
# Resolution order (first match wins):
#
#   1. explicit       a non-empty $PDK_ROOT already in the environment. Used as
#                     given; a mismatch is still refused by the caller (exit 2),
#                     never adopted-around and never repaired.
#   2. repo           flow/.pdk-root, when an install has materialized there
#                     (any variant SOURCES present). Taken even at the wrong
#                     revision, so setup-pdk.sh's header invariant holds: a
#                     leftover install at another revision is refused, not
#                     silently reached past.
#   3. shared         ${CIEL_PDK_ROOT:-$HOME/.ciel}, ciel's own store, when it
#                     satisfies the pinned revision and both libraries. Adopted,
#                     and `ciel enable` skipped: re-fetching 3.6 GB of a PDK the
#                     host already has is the defect this exists to remove
#                     (issue #79, which is what parked #55 on 2026-11-05).
#   4. install-target flow/.pdk-root otherwise -- what install mode installs
#                     into, and the root whose absence verify mode reports
#                     before exiting 2. Unchanged from the old default.
#
# Step 2 keys on a SOURCES file rather than on the directory, because install
# mode mkdir -p's flow/.pdk-root before fetching: a directory with no SOURCES
# in it is a download that never landed (the #55 timeout), not an install worth
# protecting, so it must not block adoption of a store that is already correct.
#
# Step 3 is a point-in-time check by necessity: $HOME/.ciel is shared with
# sibling repos, which re-point its flat variant symlinks with their own
# `ciel enable`. pdk_revision_ok() therefore runs against the candidate
# immediately before it is adopted, and every consumer re-verifies on each run
# (via setup-pdk.sh --verify).
#
# No local here=... below: this file is sourced, and setup-pdk.sh /
# layout/run-par.sh / layout/run-lvs.sh / flow/tile/run-synth.sh /
# flow/smoke/run-smoke.sh each keep their own `here`.
PDK_PIN_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pdk.json"
PDK_ROOT_INSTALL_TARGET="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.pdk-root"

# pdk_revision_ok [-v] <root>
#   True when <root> carries every pinned variant at the pinned open_pdks
#   revision with both pinned libraries present. Quiet by default so a
#   candidate store can be probed without noise; -v prints the per-variant
#   MISSING / REVISION MISMATCH diagnostics setup-pdk.sh reports on failure.
pdk_revision_ok() {
  local verbose=0
  if [[ "${1:-}" == "-v" ]]; then verbose=1; shift; fi
  local root="${1:-}"
  if [[ -z "$root" ]]; then
    echo "pdk_revision_ok: a root argument is required" >&2
    return 2
  fi

  local rev bad=0 v l src got
  local variants=() libs=()
  rev="$(jq -er .open_pdks_revision "$PDK_PIN_FILE")" || return 2
  mapfile -t variants < <(jq -er '.variants[]' "$PDK_PIN_FILE")
  mapfile -t libs < <(jq -er '.libraries[]' "$PDK_PIN_FILE")
  if [[ ${#variants[@]} -eq 0 || ${#libs[@]} -eq 0 ]]; then
    echo "pdk_revision_ok: cannot read .variants/.libraries from $PDK_PIN_FILE" >&2
    return 2
  fi

  for v in "${variants[@]}"; do
    src="$root/$v/SOURCES"
    if [[ ! -f "$src" ]]; then
      if [[ $verbose -eq 1 ]]; then echo "setup-pdk: MISSING $src" >&2; fi
      bad=1
      continue
    fi
    got="$(head -n1 "$src" | awk '{print $2}')"
    if [[ "$got" != "$rev" ]]; then
      if [[ $verbose -eq 1 ]]; then
        echo "setup-pdk: REVISION MISMATCH for $v: found '$got', pin is '$rev' ($src)" >&2
      fi
      bad=1
    fi
    for l in "${libs[@]}"; do
      if [[ ! -d "$root/$v/libs.ref/$l" ]]; then
        if [[ $verbose -eq 1 ]]; then echo "setup-pdk: MISSING library $l in $v" >&2; fi
        bad=1
      fi
    done
  done
  return $bad
}

# pdk_root_select
#   Resolve the root into the globals PDK_ROOT_RESOLVED and PDK_ROOT_SOURCE
#   (explicit | repo | shared | install-target). Deliberately not a subshell:
#   setup-pdk.sh reads PDK_ROOT_SOURCE to decide whether `ciel enable` is
#   needed at all, which a command substitution would hide.
# shellcheck disable=SC2034  # both globals are the cross-file contract: read by
# flow/setup-pdk.sh (PDK_ROOT_SOURCE gates `ciel enable`) and by pdk_root_resolve.
pdk_root_select() {
  PDK_ROOT_RESOLVED=""
  PDK_ROOT_SOURCE=""

  # 1. explicit: a root the caller put in the environment. PDK_ROOT= (set but
  #    empty) is treated as unset, never as a root of "".
  if [[ -n "${PDK_ROOT:-}" ]]; then
    PDK_ROOT_RESOLVED="$PDK_ROOT"
    PDK_ROOT_SOURCE="explicit"
    return 0
  fi

  # 2. repo: an install already materialized in flow/.pdk-root, at whatever
  #    revision. A wrong one is refused downstream, not reached past.
  local v variants=()
  mapfile -t variants < <(jq -er '.variants[]' "$PDK_PIN_FILE")
  if [[ ${#variants[@]} -eq 0 ]]; then
    echo "pdk_root_select: cannot read .variants from $PDK_PIN_FILE" >&2
    return 2
  fi
  for v in "${variants[@]}"; do
    if [[ -f "$PDK_ROOT_INSTALL_TARGET/$v/SOURCES" ]]; then
      PDK_ROOT_RESOLVED="$PDK_ROOT_INSTALL_TARGET"
      PDK_ROOT_SOURCE="repo"
      return 0
    fi
  done

  # 3. shared: ciel's own store, only when it already satisfies the pin.
  #    CIEL_PDK_ROOT, when set, is the one candidate considered -- it names the
  #    store this host uses, so $HOME/.ciel is not tried behind its back.
  local shared=""
  if [[ -n "${CIEL_PDK_ROOT:-}" ]]; then
    shared="$CIEL_PDK_ROOT"
  elif [[ -n "${HOME:-}" ]]; then
    shared="$HOME/.ciel"
  fi
  if [[ -n "$shared" && -d "$shared" ]] && pdk_revision_ok "$shared"; then
    PDK_ROOT_RESOLVED="$shared"
    PDK_ROOT_SOURCE="shared"
    echo "setup-pdk: adopting the ciel store $shared (already at the pinned open_pdks revision); no install needed" >&2
    return 0
  fi

  # 4. install-target: nothing usable yet.
  PDK_ROOT_RESOLVED="$PDK_ROOT_INSTALL_TARGET"
  PDK_ROOT_SOURCE="install-target"
  return 0
}

# pdk_root_resolve
#   The same resolution, echoing the chosen root on stdout (any adoption notice
#   goes to stderr). For callers that only need the path:
#     PDK_ROOT="$(pdk_root_resolve)" || exit 2
#     export PDK_ROOT
pdk_root_resolve() {
  pdk_root_select || return $?
  printf '%s\n' "$PDK_ROOT_RESOLVED"
}
