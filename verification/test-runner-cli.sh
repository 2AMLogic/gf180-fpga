#!/usr/bin/env bash
# CLI regression check for verification/runner.py (issue #86).
#
#   verification/test-runner-cli.sh
#
# Asserts two invariants after retiring --dut/--broken/--module/--toplevel:
#   1. Every retired flag (including bare `--broken`, which argparse would
#      otherwise accept as a unique prefix of `--broken-only` and silently
#      skip the good leg) is rejected as a usage error (exit 2) before any
#      simulator runs or result file is written.
#   2. The explicit single-leg spellings (`--broken-only`, `--good-only`)
#      still execute only the requested leg against a scratch copy of
#      verification/smoke and pass.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runner="$root/verification/runner.py"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

# Stage a clean scratch copy of verification/smoke so no repo sim_build/ is
# touched, plus a stub iverilog to prove rejected flags fail before simulation.
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
