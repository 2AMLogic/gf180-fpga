#!/usr/bin/env bash
# CLI regression check for verification/runner.py (issues #86, #211).
#
#   verification/test-runner-cli.sh
#
# Asserts three invariants after retiring --dut/--broken/--module/--toplevel:
#   1. Every retired flag (including bare `--broken`, which argparse would
#      otherwise accept as a unique prefix of `--broken-only` and silently
#      skip the good leg) is rejected as a usage error (exit 2) before any
#      simulator runs or result file is written.
#   2. The explicit single-leg spellings (`--broken-only`, `--good-only`)
#      still execute only the requested leg against a scratch copy of
#      verification/smoke and pass.
#   3. (issue #211) A --vvp table that cannot yield a verdict -- no entries,
#      or a `cases_from` entry whose index holds no cases -- is rejected the
#      same way: exit 2 during table expansion, before any simulator runs or
#      result file is written, naming the table or index. Either one used to
#      print OVERALL: PASS and exit 0. That the committed table still expands
#      and passes is CI's own step (verification.yml "Stamped benches"), which
#      needs the real simulator; the table cases here run against the stub.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runner="$root/verification/runner.py"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

# Stage a clean scratch copy of verification/smoke so no repo sim_build/ is
# touched, plus a stub iverilog to prove rejected flags and tables fail before
# simulation.
mkdir -p "$work/smoke/negative_control" "$work/stub-bin"
cp "$root/verification/smoke/smoke.v" "$root/verification/smoke/test_smoke.py" "$work/smoke/"
cp "$root/verification/smoke/negative_control/smoke_broken.v" "$work/smoke/negative_control/"
cat > "$work/stub-bin/iverilog" <<EOF
#!/usr/bin/env bash
echo "iverilog invoked: \$*" >> "$work/sim-attempted"
exit 99
EOF
chmod +x "$work/stub-bin/iverilog"

expect_rejected() {
  local label="$1" flag="$2"
  shift 2
  local result_json="$work/rejected.json"
  rm -f "$result_json" "$work/sim-attempted"
  local out rc
  out="$(PATH="$work/stub-bin:$PATH" python3 -I "$runner" "$work/smoke" --result "$result_json" "$@" 2>&1)" && rc=0 || rc=$?
  [[ "$rc" -eq 2 ]] \
    || fail "[$label]: expected exit 2, got $rc; output: $out"
  grep -qF -- "unrecognized arguments" <<<"$out" \
    || fail "[$label]: stderr missing 'unrecognized arguments'; output: $out"
  grep -qF -- "$flag" <<<"$out" \
    || fail "[$label]: stderr does not name '$flag'; output: $out"
  [[ ! -e "$work/sim-attempted" ]] \
    || fail "[$label]: simulator was invoked before CLI rejection ($(cat "$work/sim-attempted"))"
  [[ ! -e "$result_json" ]] \
    || fail "[$label]: result file was written despite CLI rejection"
  echo "ok [$label] exit 2, rejected before simulation"
}

expect_rejected "retired bare --broken" "--broken" --broken
expect_rejected "retired --broken with arg" "--broken" --broken "$work/smoke/negative_control/smoke_broken.v"
expect_rejected "retired --dut" "--dut" --dut "$work/smoke/smoke.v"
expect_rejected "retired --module" "--module" --module test_smoke
expect_rejected "retired --toplevel" "--toplevel" --toplevel smoke
expect_rejected "prefix --good" "--good" --good

# A --vvp table with no verdict to report is rejected like a usage error
# (issue #211): exit 2, a diagnostic naming the offending input, nothing
# simulated, no result file. The cases are scratch copies of the committed
# item-9 table with one fact changed each; `cases_from` resolves against the
# repo, so an absolute path is how a table reaches the scratch index.
expect_table_rejected() {
  local label="$1" table="$2"
  shift 2
  local result_json="$work/rejected.json"
  rm -f "$result_json" "$work/sim-attempted"
  local out rc
  out="$(PATH="$work/stub-bin:$PATH" python3 -I "$runner" --vvp "$table" --result "$result_json" 2>&1)" && rc=0 || rc=$?
  [[ "$rc" -eq 2 ]] \
    || fail "[$label]: expected exit 2, got $rc; output: $out"
  for want in "$@"; do
    grep -qF -- "$want" <<<"$out" \
      || fail "[$label]: output lacks '$want'; output: $out"
  done
  [[ ! -e "$work/sim-attempted" ]] \
    || fail "[$label]: simulator was invoked before the table was rejected ($(cat "$work/sim-attempted"))"
  [[ ! -e "$result_json" ]] \
    || fail "[$label]: result file was written despite the rejected table"
  echo "ok [$label] exit 2, rejected before simulation"
}

# no entries at all: the run that reported "0/0 bench runs passed" as a pass
jq '.runs = []' "$root/verification/item9/benches.json" > "$work/empty.json"
expect_table_rejected "empty runs array" "$work/empty.json" \
  "bench table $work/empty.json lists no runs"

# the other entries kept: only the corpus index redirected to a whitespace-only
# file, which silently dropped the 15 bitstream cases. The valid benches come
# first, so the stub staying untouched proves the table is rejected before any
# of them runs.
printf ' \n\t\n\n' > "$work/blank-index.txt"
jq --arg idx "$work/blank-index.txt" \
  '.runs |= map(if .cases_from then .cases_from = $idx else . end)' \
  "$root/verification/item9/benches.json" > "$work/blank-index.json"
expect_table_rejected "valid benches plus a whitespace-only corpus index" "$work/blank-index.json" \
  "bench table $work/blank-index.json" "index $work/blank-index.txt holds no cases"

# Explicit single-leg flags must still run only the requested leg and pass.
check_single_leg() {
  local flag="$1" want_leg="$2"
  local result_json="$work/${want_leg}.json"
  rm -f "$result_json"
  python3 "$runner" "$work/smoke" "$flag" --result "$result_json" >/dev/null
  python3 -I - "$result_json" "$want_leg" <<'PY'
import json, sys
path, want_leg = sys.argv[1], sys.argv[2]
r = json.load(open(path))
assert r["overall"] == "pass", f"overall={r['overall']!r}"
legs = list(r["legs"].keys())
assert legs == [want_leg], f"expected legs [{want_leg!r}], got {legs!r}"
assert r["legs"][want_leg]["ok"] is True, f"leg {want_leg!r} not ok: {r['legs'][want_leg]!r}"
PY
  echo "ok [$flag] passed with legs=[$want_leg]"
}

check_single_leg --broken-only negative_control
check_single_leg --good-only good
