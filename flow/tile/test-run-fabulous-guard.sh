#!/usr/bin/env bash
# PDK-free, network-free regression test for the vendored-input guard in
# flow/tile/run-fabulous.sh (issue #196): the success record may only be
# written when every original vendored file survives the generator run
# byte-identical. FABulous itself is stubbed (uvx on PATH) and told, per case,
# to leave the scratch copy alone, add a generated file, edit an input,
# remove an input or replace one with a directory; klt is stubbed via a
# scratch flow/klt.sh. Nothing is fetched and no PDK is read.
#
#   flow/tile/test-run-fabulous-guard.sh
#
# The wrapper is copied into a scratch tree and the copy is the one
# exercised, because it derives both the vendored tree and the record
# directory from its own location.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

mkdir -p "$work/flow/tile" "$work/bin" "$work/rtl/common/fabulous/.FABulous" \
  "$work/rtl/common/fabulous/Tile"
cp "$root/flow/tile/run-fabulous.sh" "$work/flow/tile/"

# fixture vendored description: nested directories, a dotfile, an empty file
# and a filename with spaces, so the guard's file walk covers more than the
# flat case
printf "FAB_PROJ_VERSION='2.2.0'\n" > "$work/rtl/common/fabulous/.FABulous/.env"
printf 'fabric grid\n' > "$work/rtl/common/fabulous/fabric.csv"
printf 'FABulous script\n' > "$work/rtl/common/fabulous/FABulous.tcl"
printf 'PE_clb\n' > "$work/rtl/common/fabulous/Tile/PE_clb.txt"
: > "$work/rtl/common/fabulous/empty.cfg"
printf 'space\n' > "$work/rtl/common/fabulous/a file with spaces.txt"

# klt stub: records every call; the wrapper must scan the record it writes
cat > "$work/flow/klt.sh" <<'EOF'
klt() { printf '%s\n' "$*" >> "${KLT_CALL_LOG:-/dev/null}"; }
EOF

# FABulous stub: the wrapper has already copied the vendored tree to $PWD;
# FAB_STUB_MODE decides what the "generator" does to it
cat > "$work/bin/uvx" <<'EOF'
#!/usr/bin/env bash
set -u
log=""
prev=""
for a in "$@"; do
  [[ "$prev" == "--log" ]] && log="$a"
  prev="$a"
done
printf 'INFO | Running at: %s\n' "$PWD" > "$log"
case "${FAB_STUB_MODE:-clean}" in
  clean) ;;
  extra) mkdir generated && printf 'new output\n' > generated/new_file.v ;;
  edit) printf 'mutated\n' >> fabric.csv ;;
  remove) rm .FABulous/.env ;;
  swap) rm empty.cfg && mkdir empty.cfg ;;
  *) echo "uvx stub: unknown FAB_STUB_MODE '$FAB_STUB_MODE'" >&2; exit 2 ;;
esac
exit 0
EOF
chmod +x "$work/bin/uvx"

fail() { echo "FAIL: $*" >&2; exit 1; }
record="$work/flow/tile/records/fabulous-gen.txt"
RUN_RC=0

run_wrapper() { # $1 = FAB_STUB_MODE
  local rc=0
  rm -rf "$work/flow/tile/records" "$work/klt-calls"
  ( cd "$work" &&
    FAB_STUB_MODE="$1" KLT_CALL_LOG="$work/klt-calls" \
    PATH="$work/bin:$PATH" bash flow/tile/run-fabulous.sh ) \
    >"$work/stdout" 2>"$work/stderr" || rc=$?
  RUN_RC=$rc
}

# 1. inputs byte-identical: accept, write the record, scan it
run_wrapper clean
[[ $RUN_RC -eq 0 ]] || fail "identical inputs: expected exit 0, got $RUN_RC: $(cat "$work/stderr")"
[[ -f $record ]] || fail "identical inputs: no record written"
grep -q 'no vendored file differs' "$record" || fail "identical inputs: record lacks the success line"
grep -qx 'env-provenance scan .*fabulous-gen.txt' "$work/klt-calls" || fail "identical inputs: record not provenance-scanned"

# 2. identical inputs plus a generated file: still accept
run_wrapper extra
[[ $RUN_RC -eq 0 ]] || fail "extra generated file: expected exit 0, got $RUN_RC: $(cat "$work/stderr")"
[[ -f $record ]] || fail "extra generated file: no record written"

# 3. an original edited by the run: reject before the record
run_wrapper edit
[[ $RUN_RC -eq 3 ]] || fail "edited input: expected exit 3, got $RUN_RC: $(cat "$work/stderr")"
[[ ! -e $record ]] || fail "edited input: record written despite the change"
grep -q 'vendored input changed: fabric.csv' "$work/stderr" || fail "edited input: stderr does not name the changed file: $(cat "$work/stderr")"

# 4. an original removed by the run: reject before the record
run_wrapper remove
[[ $RUN_RC -eq 3 ]] || fail "removed input: expected exit 3, got $RUN_RC: $(cat "$work/stderr")"
[[ ! -e $record ]] || fail "removed input: record written despite the removal"
grep -q 'vendored input missing after the run: .FABulous/.env' "$work/stderr" || fail "removed input: stderr does not name the missing file: $(cat "$work/stderr")"

# 5. an original that can no longer be compared (a directory in its place)
run_wrapper swap
[[ $RUN_RC -eq 3 ]] || fail "uncomparable input: expected exit 3, got $RUN_RC: $(cat "$work/stderr")"
[[ ! -e $record ]] || fail "uncomparable input: record written"
grep -q 'cannot be compared: empty.cfg' "$work/stderr" || fail "uncomparable input: stderr does not name the file: $(cat "$work/stderr")"

echo "ok"
