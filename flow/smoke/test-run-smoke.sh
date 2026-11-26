#!/usr/bin/env bash
# PDK-free, network-free regression test for flow/smoke/run-smoke.sh (issue
# #209): a failed klt stage must reach the runner's exit status and must not
# disturb the record it would have written. Before the fix the loop's subshell
# exited with the status of the `echo` that logs each klt run, so `|| rc=1`
# never fired: the runner exited 0, and the `> record` redirection had already
# truncated the failed stage's record to 0 bytes.
#
#   flow/smoke/test-run-smoke.sh
#
# The runner is copied into a scratch checkout and the copy is the one
# exercised, because it derives its requests, its records and its sibling
# scripts from its own location. PDK root resolution and verification are
# stubbed (flow/test-pdk-root.sh covers the real ones) and klt is a stub
# driven by the environment. The scratch checkout is a git repository, so the
# runner's checkout-prefix rewrite has a non-empty root, and the fixture PDK
# root sits outside it, as an external store does.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"
work="$(cd "$work" && pwd -P)"    # git reports the checkout root with symlinks resolved
trap 'rm -rf "$work"' EXIT
repo="$work/repo"                 # scratch checkout holding the runner
smoke="$repo/flow/smoke"
rec="$smoke/records"
rec_rel=flow/smoke/records        # the same directory, relative to the checkout
pdk="$work/pdk"                   # fixture PDK root, outside the checkout
libs=(mcu7t5v0 mcu9t5v0)

fail() { echo "FAIL: $*" >&2; exit 1; }

# klt stub: every call is appended to $KLT_LOG; the KLT_* variables that
# run_runner() passes decide how it behaves.
#   KLT_FAIL_LIB        glob: libraries whose KLT_FAIL_STAGE fails
#   KLT_FAIL_STAGE      synthesize | place-and-route
#   KLT_FAIL_MODE       stderr: error document on stderr, nothing on stdout
#                       partial: truncated document on stdout, error on stderr
#   KLT_FAIL_STATUS     exit status of the failing stage (default 17)
#   KLT_NO_NETLIST_LIB  glob: libraries whose synthesize exits 0 but leaves no netlist
#   KLT_SCAN_FAIL       env-provenance scan exits 1
# KLT_ROOT is the prefix a normalized record no longer contains.
cat > "$work/klt-stub" <<'STUB'
#!/usr/bin/env bash
set -u
: "${KLT_LOG:?}" "${KLT_ROOT:?}" "${PDK_ROOT:?}"
lib="$(basename "$PWD")"
log() { printf '%s\n' "$*" >> "$KLT_LOG"; }
case "${1:-}" in
  synthesize|place-and-route)
    [[ "$*" == "$1 --format json $4" ]] || { echo "klt-stub: unexpected argv: $*" >&2; exit 2; }
    cmd="$1" request="$4"
    log "$lib $cmd"
    fail_lib="${KLT_FAIL_LIB:-}" no_netlist_lib="${KLT_NO_NETLIST_LIB:-}"
    if [[ "$lib" == $fail_lib && "$cmd" == "${KLT_FAIL_STAGE:-}" ]]; then
      case "${KLT_FAIL_MODE:-stderr}" in
        stderr) ;;
        partial) printf '{ "schema_version": 1, "command": "%s", "truncat' "$cmd" ;;
        *) echo "klt-stub: unknown KLT_FAIL_MODE '${KLT_FAIL_MODE}'" >&2; exit 2 ;;
      esac
      echo "{ \"schema_version\": 1, \"error\": { \"command\": \"$cmd\", \"message\": \"stub $cmd failure\" } }" >&2
      if [[ "$cmd" == synthesize ]]; then
        # A netlist a correct runner never stages: this synthesis failed.
        mkdir -p .klt/synthesize/run-failed
        echo "// decoy netlist left by a failed synthesize" > .klt/synthesize/run-failed/smoke_lut4_synth.v
      fi
      exit "${KLT_FAIL_STATUS:-17}"
    fi
    echo '{'
    if [[ "$cmd" == synthesize ]]; then
      run=".klt/synthesize/run-current"
      printf '  "netlist_path": {"scope": "repo", "path": "flow/smoke/%s/%s/smoke_lut4_synth.v"},\n' "$lib" "$run"
      if [[ "$lib" != $no_netlist_lib ]]; then
        mkdir -p "$run"
        echo "// netlist left by the klt stub for $lib" > "$run/smoke_lut4_synth.v"
      fi
    fi
    cat <<DOC
  "schema_version": 1,
  "command": "$cmd",
  "status": "ok",
  "request": "$PWD/$request",
  "netlist": "$PWD/netlist/smoke_lut4_synth.v",
  "layer_map": "$PDK_ROOT/gf180mcuD/libs.tech/klayout/tech/gf180mcu.map"
}
DOC
    ;;
  env-provenance)
    [[ "${2:-}" == scan && $# -ge 3 ]] || { echo "klt-stub: unexpected argv: $*" >&2; exit 2; }
    shift 2
    log "scan $*"
    leaks=0
    for f in "$@"; do
      log "scanned ${f##*/} $(sha256sum "$f" | cut -d' ' -f1)"
      if grep -qF -- "$KLT_ROOT/" "$f"; then
        echo "leak: $KLT_ROOT/ in $f" >&2
        leaks=$((leaks + 1))
      fi
    done
    echo "clean: $leaks leak(s) in $# file(s)"
    [[ $leaks -eq 0 && "${KLT_SCAN_FAIL:-0}" -eq 0 ]] || exit 1
    ;;
  *) echo "klt-stub: unexpected call: $*" >&2; exit 2 ;;
esac
STUB
chmod +x "$work/klt-stub"
mkdir -p "$pdk" "$work/home"

# build_fixture -> a pristine scratch checkout: the runner, both library
# directories with their requests and committed netlists, and a records/
# directory holding only toolchain.json.
build_fixture() {
  rm -rf "$repo"
  local lib
  for lib in "${libs[@]}"; do
    mkdir -p "$smoke/$lib/netlist"
    cp "$root/flow/smoke/$lib/synth.json" "$root/flow/smoke/$lib/par.json" "$smoke/$lib/"
    cp "$root/flow/smoke/$lib/netlist/smoke_lut4_synth.v" "$smoke/$lib/netlist/"
  done
  mkdir -p "$rec" "$repo/flow"
  cp "$root/flow/smoke/run-smoke.sh" "$smoke/"
  cp "$root/flow/report-paths.sh" "$repo/flow/"
  echo '{"_comment": "not a stage record"}' > "$rec/toolchain.json"
  # The runner's PDK preamble, stubbed: $PDK_ROOT resolves to a directory
  # outside the checkout and setup-pdk.sh --verify succeeds.
  echo '{ "smoke_variant": "gf180mcuD" }' > "$repo/flow/pdk.json"
  echo "pdk_root_resolve() { echo '$pdk'; }" > "$repo/flow/pdk-root.sh"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$repo/flow/setup-pdk.sh"
  chmod +x "$repo/flow/setup-pdk.sh"
  echo "klt() { '$work/klt-stub' \"\$@\"; }" > "$repo/flow/klt.sh"
  git -c init.defaultBranch=main init -q "$repo"
}

# files -> every file under the scratch checkout except git's and klt's own
# directories, relative to the checkout root, sorted.
files() {
  ( cd "$repo" && find . \( -path ./.git -o -name .klt \) -prune -o -type f -print \
      | sed 's#^\./##' | sort )
}

# run_runner [VAR=value ...] -> the scratch runner, from an unrelated working
# directory, in a clean environment plus the given assignments. Leaves the
# exit status in RUN_RC and the output in $work/stdout and $work/stderr.
run_runner() {
  local rc=0
  rm -f "$work/klt.log"
  files > "$work/files.before"
  ( cd "$work" && env -u PDK_ROOT -u PDK -u CIEL_PDK_ROOT HOME="$work/home" PATH="$PATH" \
      KLT_LOG="$work/klt.log" KLT_ROOT="$work" "$@" \
      timeout 60 bash "$smoke/run-smoke.sh" ) > "$work/stdout" 2> "$work/stderr" || rc=$?
  RUN_RC=$rc
}

# prior <record-name> -> a record from an earlier run: content no stage of this
# run produces.
prior() { printf '{"prior": "%s", "note": "recorded by an earlier run"}\n' "$1"; }
# seed <record-name>... -> such records, remembering each one's inode and
# modification time, so a rewrite that happens to reproduce the same bytes is
# still caught.
seed() {
  local r
  : > "$work/seeded"
  for r in "$@"; do
    prior "$r" > "$rec/$r"
    printf '%s %s\n' "$r" "$(stat -c '%i %y' "$rec/$r")" >> "$work/seeded"
  done
}

# expected_record <record-name> -> what the runner must publish for it: the
# stub's document, with the checkout prefix made repo-relative and the PDK
# root symbolic.
expected_record() {
  local lib="${1%%.*}" cmd request
  case "$1" in
    *.synth.json) cmd=synthesize request=synth.json ;;
    *.par.json) cmd=place-and-route request=par.json ;;
    *) fail "no such record kind: $1" ;;
  esac
  echo '{'
  if [[ "$cmd" == synthesize ]]; then
    printf '  "netlist_path": {"scope": "repo", "path": "flow/smoke/%s/.klt/synthesize/run-current/smoke_lut4_synth.v"},\n' "$lib"
  fi
  cat <<EOF
  "schema_version": 1,
  "command": "$cmd",
  "status": "ok",
  "request": "flow/smoke/$lib/$request",
  "netlist": "flow/smoke/$lib/netlist/smoke_lut4_synth.v",
  "layer_map": "\$PDK_ROOT/gf180mcuD/libs.tech/klayout/tech/gf180mcu.map"
}
EOF
}

record_suffix() { if [[ $1 == synthesize ]]; then echo synth; else echo par; fi; }

all_stages_ok() {
  printf '%s\n' 'mcu7t5v0 synthesize exit=0' 'mcu7t5v0 place-and-route exit=0' \
    'mcu9t5v0 synthesize exit=0' 'mcu9t5v0 place-and-route exit=0'
}
all_stage_calls() {
  printf '%s\n' 'mcu7t5v0 synthesize' 'mcu7t5v0 place-and-route' \
    'mcu9t5v0 synthesize' 'mcu9t5v0 place-and-route'
}

# ---- assertions ----------------------------------------------------------

# expect_status_lines [line...] -> the runner logged exactly these
# "<library> <stage> exit=<status>" lines, in this order.
expect_status_lines() {
  local want got
  want="$(printf '%s\n' "$@")"
  got="$(grep ' exit=' "$work/stdout" || true)"
  [[ "$got" == "$want" ]] || fail "status log:
--- got ---
$got
--- want ---
$want"
}

# expect_calls [line...] -> klt saw exactly these "<library> <command>" stage
# calls, in this order, and one provenance scan.
expect_calls() {
  local want got
  want="$(printf '%s\n' "$@")"
  got="$(grep -v '^scan' "$work/klt.log" || true)"
  [[ "$got" == "$want" ]] || fail "klt stage calls:
--- got ---
$got
--- want ---
$want"
  [[ "$(grep -c '^scan ' "$work/klt.log" || true)" -eq 1 ]] || fail "expected one provenance scan"
}

# expect_failure <library> <command> <status> <context> -> the runner exited
# non-zero; klt's own error output, and the runner's note naming the record it
# did not rewrite, both reached stderr.
expect_failure() {
  [[ $RUN_RC -ne 0 ]] || fail "$4: runner exited 0 although $1 $2 exited $3"
  grep -qF "stub $2 failure" "$work/stderr" || fail "$4: klt's error document did not reach stderr"
  grep -qF "run-smoke: $1 $2 failed; records/$1.$(record_suffix "$2").json not rewritten" "$work/stderr" \
    || fail "$4: stderr does not say the $1 $2 record was left alone"
}

expect_intact() { # <record-name>... -> each prior record is still there, byte for byte, and was not rewritten
  local r
  for r in "$@"; do
    [[ -e "$rec/$r" ]] || fail "prior record $r is gone"
    prior "$r" | cmp -s - "$rec/$r" \
      || fail "prior record $r was rewritten (now $(wc -c < "$rec/$r") bytes): $(head -c 120 "$rec/$r")"
    [[ "$(stat -c '%i %y' "$rec/$r")" == "$(awk -v r="$r" '$1 == r { $1 = ""; sub(/^ /, ""); print }' "$work/seeded")" ]] \
      || fail "prior record $r was rewritten in place (its inode or mtime changed)"
  done
}

expect_absent() { # <record-name>... -> no such record exists
  local r
  for r in "$@"; do
    [[ ! -e "$rec/$r" ]] || fail "$r was written although its stage did not succeed: $(head -c 120 "$rec/$r")"
  done
}

# expect_published <record-name>... -> each record is at its existing path,
# parses as JSON, and is the normalized stub document.
expect_published() {
  local r
  for r in "$@"; do
    [[ -f "$rec/$r" ]] || fail "record $r was not published"
    jq -e . "$rec/$r" > /dev/null || fail "record $r does not parse as JSON"
    expected_record "$r" | cmp -s - "$rec/$r" \
      || fail "record $r is not the normalized stub document:
$(cat "$rec/$r")"
  done
}

# expect_netlist_untouched <library> -> the committed netlist was not staged
# over: its content is still the checkout's copy.
expect_netlist_untouched() {
  cmp -s "$smoke/$1/netlist/smoke_lut4_synth.v" "$root/flow/smoke/$1/netlist/smoke_lut4_synth.v" \
    || fail "netlist for $1 was staged over: $(cat "$smoke/$1/netlist/smoke_lut4_synth.v")"
}

# expect_scanned [<kind>:<record-name>]... -> the provenance scan received
# exactly these records, and each already carried the content this case
# expects of it at the end (published = the normalized stub document, prior =
# the pre-seeded record): the scan sees what gets committed, not raw klt output.
expect_scanned() {
  local item kind name lines=() want got
  for item in "$@"; do
    kind="${item%%:*}" name="${item#*:}"
    case "$kind" in
      published) lines+=("scanned $name $(expected_record "$name" | sha256sum | cut -d' ' -f1)") ;;
      prior) lines+=("scanned $name $(prior "$name" | sha256sum | cut -d' ' -f1)") ;;
      *) fail "expect_scanned: unknown kind '$kind'" ;;
    esac
  done
  got="$( (grep '^scanned ' "$work/klt.log" || true) | sort)"
  want="$(printf '%s\n' "${lines[@]}" | sort)"
  [[ "$got" == "$want" ]] || fail "records handed to the provenance scan:
--- got ---
$got
--- want ---
$want"
}

# expect_files_added [<record-name>...] -> the run created exactly these
# records under the checkout and removed no file: a failed stage's output was
# discarded, not left beside the records.
expect_files_added() {
  local want got before after
  if [[ $# -eq 0 ]]; then want=""; else want="$(printf '%s\n' "$@" | sed "s#^#$rec_rel/#" | sort)"; fi
  got="$(comm -13 "$work/files.before" <(files))"
  [[ "$got" == "$want" ]] || fail "files the run created (expected only: ${*:-none}):
$got"
  [[ -z "$(comm -23 "$work/files.before" <(files))" ]] \
    || fail "files the run removed:
$(comm -23 "$work/files.before" <(files))"
  # records/ holds exactly its records: no scratch directory was left behind.
  before="$(sed -n "s#^$rec_rel/##p" "$work/files.before")"
  after="$(find "$rec" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort)"
  [[ "$after" == "$(printf '%s\n' "$before" "$@" | sed '/^$/d' | sort)" ]] \
    || fail "records/ holds more than its records (scratch left behind?):
$after"
}

# ---- sections ------------------------------------------------------------

# 1. place-and-route fails with a prior record in place: exit non-zero, the
# other library still runs both stages, the prior record survives byte for byte.
par_fails_prior_record() {
  local mode
  for mode in stderr partial; do
    build_fixture
    seed mcu7t5v0.par.json
    run_runner KLT_FAIL_LIB=mcu7t5v0 KLT_FAIL_STAGE=place-and-route KLT_FAIL_MODE=$mode
    expect_failure mcu7t5v0 place-and-route 17 "KLT_FAIL_MODE=$mode"
    expect_status_lines 'mcu7t5v0 synthesize exit=0' 'mcu7t5v0 place-and-route exit=17' \
      'mcu9t5v0 synthesize exit=0' 'mcu9t5v0 place-and-route exit=0'
    expect_intact mcu7t5v0.par.json
    expect_published mcu7t5v0.synth.json mcu9t5v0.synth.json mcu9t5v0.par.json
    expect_calls "$(all_stage_calls)"
    expect_scanned prior:mcu7t5v0.par.json published:mcu7t5v0.synth.json \
      published:mcu9t5v0.synth.json published:mcu9t5v0.par.json
    expect_files_added mcu7t5v0.synth.json mcu9t5v0.synth.json mcu9t5v0.par.json
  done
}

# 2. the same failure with no prior record: the final path stays absent.
par_fails_no_prior_record() {
  local mode
  for mode in stderr partial; do
    build_fixture
    run_runner KLT_FAIL_LIB=mcu7t5v0 KLT_FAIL_STAGE=place-and-route KLT_FAIL_MODE=$mode
    expect_failure mcu7t5v0 place-and-route 17 "KLT_FAIL_MODE=$mode, no prior record"
    expect_absent mcu7t5v0.par.json
    expect_published mcu7t5v0.synth.json mcu9t5v0.synth.json mcu9t5v0.par.json
    expect_files_added mcu7t5v0.synth.json mcu9t5v0.synth.json mcu9t5v0.par.json
  done
}

# 3. synthesis fails while a netlist from an earlier run is in place: no netlist
# staging and no place-and-route for that library, both stages for the other,
# and the synthesis record is left as it was (present or absent).
synth_fails() {
  local prior_record
  for prior_record in present absent; do
    build_fixture
    if [[ $prior_record == present ]]; then seed mcu7t5v0.synth.json mcu7t5v0.par.json; fi
    run_runner KLT_FAIL_LIB=mcu7t5v0 KLT_FAIL_STAGE=synthesize KLT_FAIL_STATUS=3
    expect_failure mcu7t5v0 synthesize 3 "prior record $prior_record"
    expect_status_lines 'mcu7t5v0 synthesize exit=3' \
      'mcu9t5v0 synthesize exit=0' 'mcu9t5v0 place-and-route exit=0'
    expect_calls 'mcu7t5v0 synthesize' 'mcu9t5v0 synthesize' 'mcu9t5v0 place-and-route'
    expect_netlist_untouched mcu7t5v0
    expect_published mcu9t5v0.synth.json mcu9t5v0.par.json
    if [[ $prior_record == present ]]; then
      expect_intact mcu7t5v0.synth.json mcu7t5v0.par.json
      expect_scanned prior:mcu7t5v0.par.json prior:mcu7t5v0.synth.json \
        published:mcu9t5v0.synth.json published:mcu9t5v0.par.json
      expect_files_added mcu9t5v0.synth.json mcu9t5v0.par.json
    else
      expect_absent mcu7t5v0.synth.json mcu7t5v0.par.json
      expect_files_added mcu9t5v0.synth.json mcu9t5v0.par.json
    fi
  done
}

# 4. wherever the failure falls: the last library, or both libraries.
failure_position() {
  build_fixture
  run_runner KLT_FAIL_LIB=mcu9t5v0 KLT_FAIL_STAGE=place-and-route
  expect_failure mcu9t5v0 place-and-route 17 "last library"
  expect_status_lines 'mcu7t5v0 synthesize exit=0' 'mcu7t5v0 place-and-route exit=0' \
    'mcu9t5v0 synthesize exit=0' 'mcu9t5v0 place-and-route exit=17'
  expect_absent mcu9t5v0.par.json
  expect_published mcu7t5v0.synth.json mcu7t5v0.par.json mcu9t5v0.synth.json
  expect_calls "$(all_stage_calls)"
  expect_files_added mcu7t5v0.synth.json mcu7t5v0.par.json mcu9t5v0.synth.json

  build_fixture
  run_runner KLT_FAIL_LIB='mcu*' KLT_FAIL_STAGE=place-and-route KLT_FAIL_MODE=partial
  expect_failure mcu7t5v0 place-and-route 17 "both libraries"
  expect_failure mcu9t5v0 place-and-route 17 "both libraries"
  expect_status_lines 'mcu7t5v0 synthesize exit=0' 'mcu7t5v0 place-and-route exit=17' \
    'mcu9t5v0 synthesize exit=0' 'mcu9t5v0 place-and-route exit=17'
  expect_absent mcu7t5v0.par.json mcu9t5v0.par.json
  expect_published mcu7t5v0.synth.json mcu9t5v0.synth.json
  expect_calls "$(all_stage_calls)"
}

# 5. synthesis exits 0 but leaves no netlist: the netlist from an earlier run
# is not routed, place-and-route is skipped for that library, exit non-zero.
netlist_missing() {
  local previous="$smoke/mcu7t5v0/.klt/synthesize/run-previous" prior_record
  for prior_record in present absent; do
    build_fixture
    mkdir -p "$previous"
    echo '// previous run' > "$previous/smoke_lut4_synth.v"
    if [[ $prior_record == present ]]; then seed mcu7t5v0.par.json; fi
    run_runner KLT_NO_NETLIST_LIB=mcu7t5v0
    [[ $RUN_RC -ne 0 ]] || fail "runner exited 0 although the current synthesis netlist was missing"
    grep -qF 'run-smoke: mcu7t5v0 netlist stage failed; place-and-route skipped' "$work/stderr" \
      || fail "no netlist: stderr does not say place-and-route was skipped"
    expect_calls 'mcu7t5v0 synthesize' 'mcu9t5v0 synthesize' 'mcu9t5v0 place-and-route'
    expect_netlist_untouched mcu7t5v0
    expect_published mcu7t5v0.synth.json mcu9t5v0.synth.json mcu9t5v0.par.json
    if [[ $prior_record == present ]]; then
      expect_intact mcu7t5v0.par.json
    else
      expect_absent mcu7t5v0.par.json
    fi
    expect_files_added mcu7t5v0.synth.json mcu9t5v0.synth.json mcu9t5v0.par.json
  done
}

# 6. both libraries succeed: four normalized records at their existing paths,
# both netlists staged from the klt run, one clean scan, exit 0.
all_stages_succeed() {
  local lib
  build_fixture
  run_runner
  [[ $RUN_RC -eq 0 ]] || fail "all stages ok: expected exit 0, got $RUN_RC: $(cat "$work/stderr")"
  expect_status_lines "$(all_stages_ok)"
  expect_calls "$(all_stage_calls)"
  expect_published mcu7t5v0.synth.json mcu7t5v0.par.json mcu9t5v0.synth.json mcu9t5v0.par.json
  expect_scanned published:mcu7t5v0.synth.json published:mcu7t5v0.par.json \
    published:mcu9t5v0.synth.json published:mcu9t5v0.par.json
  expect_files_added mcu7t5v0.synth.json mcu7t5v0.par.json mcu9t5v0.synth.json mcu9t5v0.par.json
  for lib in "${libs[@]}"; do
    [[ "$(cat "$smoke/$lib/netlist/smoke_lut4_synth.v")" == "// netlist left by the klt stub for $lib" ]] \
      || fail "netlist for $lib was not staged from this run's synthesis"
  done
  [[ "$(cat "$rec/toolchain.json")" == '{"_comment": "not a stage record"}' ]] \
    || fail "toolchain.json, which is not a stage record, was rewritten"
}

# 7. a failed provenance scan on its own still makes the runner exit non-zero.
scan_fails() {
  build_fixture
  run_runner KLT_SCAN_FAIL=1
  [[ $RUN_RC -ne 0 ]] || fail "scan failure: runner exited 0 although the provenance scan failed"
  expect_status_lines "$(all_stages_ok)"
  expect_published mcu7t5v0.synth.json mcu7t5v0.par.json mcu9t5v0.synth.json mcu9t5v0.par.json
}

# Each section runs in its own subshell with errexit on, so one failing section
# does not hide the state of the others.
sections=(par_fails_prior_record par_fails_no_prior_record synth_fails failure_position
  netlist_missing all_stages_succeed scan_fails)
failed=()
set +e
for section in "${sections[@]}"; do
  rc=0
  ( set -e; "$section" )
  rc=$?
  if [[ $rc -ne 0 ]]; then echo "section $section: FAILED" >&2; failed+=("$section"); fi
done
set -e
[[ ${#failed[@]} -eq 0 ]] || fail "${#failed[@]} of ${#sections[@]} sections failed: ${failed[*]}"
echo "ok"
