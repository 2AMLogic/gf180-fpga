#!/usr/bin/env bash
# PDK-free test of flow/pdk-root.sh's resolution order and of
# flow/setup-pdk.sh --verify on top of it (issue #79).
#
#   flow/test-pdk-root.sh
#
# Downloads nothing and needs no PDK: check_revision()/pdk_revision_ok() read
# only <root>/<variant>/SOURCES and <root>/<variant>/libs.ref/<lib>/, so a
# fixture tree of four directories, a one-line SOURCES and empty library
# directories is a complete stand-in for a 3.6 GB store. ciel and uvx are
# stubbed to a recorder that exits 1, so any install attempt is both visible
# and fatal -- that is how "no network fetch" is asserted rather than timed.
#
# The scripts under test are copied into a scratch tree and the copies are the
# ones exercised, because both derive flow/.pdk-root and flow/pdk.json from
# their own location: the real flow/.pdk-root, the real $HOME/.ciel and the
# host's CIEL_PDK_ROOT are therefore never read or written.
# SC2016/SC1091 are deliberate throughout: each `bash -c` body is single-quoted
# so the child interprets it rather than this shell expanding it (the script
# under test arrives as $0), and the sourced paths are built at run time inside
# the scratch tree. A file-level directive must precede the first command.
# shellcheck disable=SC2016,SC1091
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

mkdir -p "$work/flow" "$work/bin"
cp "$root/flow/pdk-root.sh" "$root/flow/setup-pdk.sh" "$root/flow/pdk.json" "$work/flow/"

rev="$(jq -er .open_pdks_revision "$work/flow/pdk.json")"
mapfile -t variants < <(jq -er '.variants[]' "$work/flow/pdk.json")
mapfile -t libs < <(jq -er '.libraries[]' "$work/flow/pdk.json")

# ciel/uvx stubs: record any install attempt, then fail.
cat > "$work/bin/ciel" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "enable" ]]; then echo "ciel \$*" >> "$work/install-attempted"; fi
exit 1
EOF
cat > "$work/bin/uvx" <<EOF
#!/usr/bin/env bash
echo "uvx \$*" >> "$work/install-attempted"
exit 1
EOF
chmod +x "$work/bin/ciel" "$work/bin/uvx"
export PATH="$work/bin:$PATH"

fail() { echo "FAIL: $*" >&2; exit 1; }

# mkstore <root> <revision> [library-to-omit]
mkstore() {
  local r="$1" sources_rev="$2" omit="${3:-}" v l
  rm -rf "$r"
  for v in "${variants[@]}"; do
    mkdir -p "$r/$v"
    printf 'open_pdks %s\n' "$sources_rev" > "$r/$v/SOURCES"
    for l in "${libs[@]}"; do
      if [[ "$l" == "$omit" ]]; then continue; fi
      mkdir -p "$r/$v/libs.ref/$l"
    done
  done
}

# resolve [VAR=val ...] -> echoes "<source> <root>" from a clean environment.
# stderr is dropped: the adoption notice is asserted separately, below.
resolve() {
  env -u PDK_ROOT -u CIEL_PDK_ROOT "HOME=$work/home" "PATH=$PATH" bash -c '
    set -euo pipefail
    source "$0"
    pdk_root_select
    printf "%s %s\n" "$PDK_ROOT_SOURCE" "$PDK_ROOT_RESOLVED"
  ' "$work/flow/pdk-root.sh" 2>/dev/null
}

# resolve_stderr -> whatever pdk_root_select reported to stderr
resolve_stderr() {
  { env -u PDK_ROOT -u CIEL_PDK_ROOT "HOME=$work/home" "PATH=$PATH" bash -c '
      set -euo pipefail
      source "$0"; pdk_root_select
    ' "$work/flow/pdk-root.sh" >/dev/null; } 2>&1
}

# verify [VAR=val ...] -> runs the copied setup-pdk.sh --verify, echoes "rc=<n>" plus output
verify() {
  local out rc=0
  out="$(env -u PDK_ROOT -u CIEL_PDK_ROOT "HOME=$work/home" "PATH=$PATH" \
         "$work/flow/setup-pdk.sh" --verify 2>&1)" || rc=$?
  printf 'rc=%s\n%s\n' "$rc" "$out"
}

install_mode() {
  local out rc=0
  rm -f "$work/install-attempted"
  out="$(env -u PDK_ROOT -u CIEL_PDK_ROOT "HOME=$work/home" "PATH=$PATH" \
         "$work/flow/setup-pdk.sh" 2>&1)" || rc=$?
  printf 'rc=%s\n%s\n' "$rc" "$out"
}

mkdir -p "$work/home"
good="$work/good-store"
bad="$work/bad-store"
nolib="$work/nolib-store"
mkstore "$good" "$rev"
mkstore "$bad" "0000000000000000000000000000000000000000"
mkstore "$nolib" "$rev" "${libs[0]}"

# ---------------------------------------------------------------- 1. pdk_revision_ok
( source "$work/flow/pdk-root.sh"
  pdk_revision_ok "$good"  || fail "pdk_revision_ok rejected a satisfying store"
  ! pdk_revision_ok "$bad" || fail "pdk_revision_ok accepted a wrong revision"
  ! pdk_revision_ok "$nolib" || fail "pdk_revision_ok accepted a store missing ${libs[0]}"
  ! pdk_revision_ok "$work/absent" || fail "pdk_revision_ok accepted an absent root"
  # quiet by default, diagnostic under -v
  [[ -z "$(pdk_revision_ok "$bad" 2>&1)" ]] || fail "pdk_revision_ok is not quiet by default"
  diag="$(pdk_revision_ok -v "$bad" 2>&1 || true)"
  grep -q 'REVISION MISMATCH' <<<"$diag" \
    || fail "pdk_revision_ok -v printed no mismatch diagnostic: $diag" ) || exit 1

# ---------------------------------------------------------------- 2. nothing anywhere
out="$(resolve)"
[[ "$out" == "install-target $work/flow/.pdk-root" ]] \
  || fail "empty host did not fall back to the install target: $out"

# ---------------------------------------------------------------- 3. shared store adopted
ln -sfn "$good" "$work/home/.ciel"
out="$(resolve)"
[[ "$out" == "shared $work/home/.ciel" ]] || fail "satisfying \$HOME/.ciel not adopted: $out"
notice="$(resolve_stderr)"
grep -q "adopting the ciel store $work/home/.ciel" <<<"$notice" \
  || fail "adoption was not reported on stderr: $notice"

# --verify adopts it too, and installs nothing (AC: consumers reach the PDK via --verify)
out="$(verify)"
grep -q '^rc=0$' <<<"$out" || fail "--verify did not succeed against an adopted store: $out"
grep -q "setup-pdk: OK: $work/home/.ciel is open_pdks $rev" <<<"$out" \
  || fail "--verify did not report the adopted root: $out"
[[ ! -e "$work/install-attempted" ]] || fail "--verify ran an installer: $(cat "$work/install-attempted")"

# install mode adopts it as well, with no network fetch at all
out="$(install_mode)"
grep -q '^rc=0$' <<<"$out" || fail "install mode failed against an adopted store: $out"
[[ ! -e "$work/install-attempted" ]] \
  || fail "install mode re-fetched an already-pinned store: $(cat "$work/install-attempted")"
[[ ! -d "$work/flow/.pdk-root" ]] || fail "install mode created flow/.pdk-root despite adopting"

# ---------------------------------------------------------------- 4. unusable shared stores
ln -sfn "$bad" "$work/home/.ciel"
out="$(resolve)"
[[ "$out" == "install-target $work/flow/.pdk-root" ]] \
  || fail "a wrong-revision store was adopted: $out"
ln -sfn "$nolib" "$work/home/.ciel"
out="$(resolve)"
[[ "$out" == "install-target $work/flow/.pdk-root" ]] \
  || fail "a store missing ${libs[0]} was adopted: $out"
out="$(verify)"
grep -q '^rc=2$' <<<"$out" || fail "--verify with no usable root did not exit 2: $out"
grep -q "MISSING $work/flow/.pdk-root/${variants[0]}/SOURCES" <<<"$out" \
  || fail "--verify did not report the install target as missing: $out"
[[ ! -e "$work/install-attempted" ]] || fail "--verify ran an installer: $(cat "$work/install-attempted")"

# ---------------------------------------------------------------- 5. explicit PDK_ROOT wins
ln -sfn "$good" "$work/home/.ciel"
out="$(env -u CIEL_PDK_ROOT "HOME=$work/home" "PATH=$PATH" PDK_ROOT="$bad" bash -c '
  set -euo pipefail
  source "$0"; pdk_root_select; printf "%s %s\n" "$PDK_ROOT_SOURCE" "$PDK_ROOT_RESOLVED"
' "$work/flow/pdk-root.sh" 2>/dev/null)"
[[ "$out" == "explicit $bad" ]] || fail "explicit PDK_ROOT did not win over a good store: $out"

rc=0
out="$(env -u CIEL_PDK_ROOT "HOME=$work/home" "PATH=$PATH" PDK_ROOT="$work/empty-root" \
       "$work/flow/setup-pdk.sh" --verify 2>&1)" || rc=$?
[[ $rc -eq 2 ]] || fail "explicit empty root did not exit 2 (rc=$rc): $out"
grep -q "$work/empty-root" <<<"$out" || fail "exit-2 message did not name the explicit root: $out"
grep -q "$work/home/.ciel" <<<"$out" && fail "explicit root silently fell back to the ciel store: $out"

# PDK_ROOT set but empty is unset, not a root of ""
out="$(env -u CIEL_PDK_ROOT "HOME=$work/home" "PATH=$PATH" PDK_ROOT= bash -c '
  set -euo pipefail
  source "$0"; pdk_root_select; printf "%s %s\n" "$PDK_ROOT_SOURCE" "$PDK_ROOT_RESOLVED"
' "$work/flow/pdk-root.sh" 2>/dev/null)"
[[ "$out" == "shared $work/home/.ciel" ]] || fail "PDK_ROOT= was not treated as unset: $out"

# ---------------------------------------------------------------- 6. CIEL_PDK_ROOT
out="$(env -u PDK_ROOT "HOME=$work/home" "PATH=$PATH" CIEL_PDK_ROOT="$good" bash -c '
  set -euo pipefail
  source "$0"; pdk_root_select; printf "%s %s\n" "$PDK_ROOT_SOURCE" "$PDK_ROOT_RESOLVED"
' "$work/flow/pdk-root.sh" 2>/dev/null)"
[[ "$out" == "shared $good" ]] || fail "CIEL_PDK_ROOT was not honoured: $out"

# CIEL_PDK_ROOT names the store this host uses: a bad one is not worked around
# by trying $HOME/.ciel behind its back.
ln -sfn "$good" "$work/home/.ciel"
out="$(env -u PDK_ROOT "HOME=$work/home" "PATH=$PATH" CIEL_PDK_ROOT="$bad" bash -c '
  set -euo pipefail
  source "$0"; pdk_root_select; printf "%s %s\n" "$PDK_ROOT_SOURCE" "$PDK_ROOT_RESOLVED"
' "$work/flow/pdk-root.sh" 2>/dev/null)"
[[ "$out" == "install-target $work/flow/.pdk-root" ]] \
  || fail "a bad CIEL_PDK_ROOT fell through to \$HOME/.ciel: $out"

# ---------------------------------------------------------------- 7. flow/.pdk-root precedence
# An install in the repo wins over the shared store...
mkstore "$work/flow/.pdk-root" "$rev"
out="$(resolve)"
[[ "$out" == "repo $work/flow/.pdk-root" ]] || fail "flow/.pdk-root did not win over the store: $out"
out="$(verify)"
grep -q '^rc=0$' <<<"$out" || fail "--verify failed against a good flow/.pdk-root: $out"

# ...and a leftover install at the wrong revision exits 2 rather than being
# reached past in favour of a store that would have satisfied the pin
# (setup-pdk.sh's header invariant).
mkstore "$work/flow/.pdk-root" "0000000000000000000000000000000000000000"
out="$(resolve)"
[[ "$out" == "repo $work/flow/.pdk-root" ]] \
  || fail "a mismatched flow/.pdk-root fell through to the shared store: $out"
out="$(verify)"
grep -q '^rc=2$' <<<"$out" || fail "a mismatched flow/.pdk-root did not exit 2: $out"
grep -q 'REVISION MISMATCH' <<<"$out" || fail "no mismatch diagnostic: $out"
grep -q "$work/home/.ciel" <<<"$out" && fail "mismatched repo root silently used the ciel store: $out"

# An empty flow/.pdk-root is a download that never landed, not an install: it
# must not block adoption of a store that is already correct (the #55 timeout).
rm -rf "$work/flow/.pdk-root"; mkdir -p "$work/flow/.pdk-root"
out="$(resolve)"
[[ "$out" == "shared $work/home/.ciel" ]] \
  || fail "an empty flow/.pdk-root blocked adoption: $out"
rm -rf "$work/flow/.pdk-root"

# ---------------------------------------------------------------- 8. install mode still installs
rm -f "$work/home/.ciel"
out="$(install_mode)"
grep -q '^rc=0$' <<<"$out" && fail "install mode succeeded with no PDK and a failing installer: $out"
[[ -e "$work/install-attempted" ]] || fail "install mode did not attempt an install: $out"
grep -q -- "--pdk-root $work/flow/.pdk-root" "$work/install-attempted" \
  || fail "installer was not pointed at flow/.pdk-root: $(cat "$work/install-attempted")"

echo "ok"
