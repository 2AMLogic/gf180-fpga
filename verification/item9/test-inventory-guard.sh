#!/usr/bin/env bash
# Regression net for the item-9 inventory guard (issue #109).
#
#   verification/item9/test-inventory-guard.sh
#
# verification/item9/inventory.py --check (the CI guard at
# .github/workflows/verification.yml) carries divergence assertions whose
# correctness was established by a one-fact-at-a-time perturbation matrix
# that, before this script, existed only in PR transcripts (#107, #100).
# Nothing committed re-ran it, so a refactor of the guard or of the
# workflow lines it scans could weaken an assertion while --check kept
# printing "inventory up to date" -- the always-green shape this net
# exists to prevent.
#
# The script copies every file the guard reads into a scratch tree,
# asserts the exit-0 baseline, then perturbs one fact per case and
# requires --check to exit 1 AND to name the diverged field on stderr.
# The substring matters, not just the exit code: case (j) fires two
# assertions (measured), so an exit-1-only check would pass with the
# wrong assertion doing the work.
#
# Hermetic: no PDK, no Icarus, no network. inventory.py reads only JSON,
# Markdown, YAML and tb_*.v filenames and resolves ROOT from its own
# location, so a copied tree is a complete stand-in. Nothing outside the
# scratch tree is read or written; the checkout is byte-identical before
# and after a run.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

inv="$work/verification/item9/inventory.py"
attested="$work/verification/signoff/item9-inventory.json"
wf="$work/.github/workflows/verification.yml"

fail() { echo "FAIL: $*" >&2; exit 1; }

# (Re)copy every file inventory.py reads, pristine. Called before every
# case so each perturbation starts from the baseline and the cases are
# independent and order-insensitive.
stage_fixture() {
  rm -rf "$work/verification" "$work/rtl" "$work/flow" "$work/.github"
  mkdir -p "$work/verification/item9" "$work/verification/signoff" \
           "$work/flow" "$work/.github/workflows"
  cp "$root/verification/item9/inventory.py" "$inv"
  cp "$root/verification/item9/benches.json" "$root/verification/item9/INVENTORY.md" \
     "$work/verification/item9/"
  cp "$root/verification/signoff/item9-inventory.json" "$attested"
  cp "$root/.github/workflows/verification.yml" "$wf"
  cp "$root/flow/pdk.json" "$work/flow/"
  (cd "$root" && find verification/common rtl/common -type f -name 'tb_*.v' -print0 \
    | xargs -0 -r cp --parents -t "$work")
}

# expect_fail <case-label> <required stderr substring>
# --check must exit non-zero AND stderr must name the diverged field.
# Substring, not exact match: case (j) legitimately emits two ERROR lines.
expect_fail() {
  local label="$1" want="$2" out rc
  out="$(python3 -I "$inv" --check 2>&1 1>/dev/null)" && rc=0 || rc=$?
  [[ "$rc" -ne 0 ]] \
    || fail "[$label]: expected --check to fail, it exited 0"
  grep -qF -- "$want" <<<"$out" \
    || fail "[$label]: --check exited $rc but its stderr lacks the required substring '$want'; observed stderr:
$out"
  echo "ok [$label] exit $rc, matched: $want"
}

# Baseline: an unperturbed copy must pass. A baseline that does not pass
# first would make every later "exit 1" meaningless.
stage_fixture
out="$(python3 -I "$inv" --check 2>"$work/baseline.stderr")" \
  || fail "[baseline]: expected --check to pass, exited $? with: $(cat "$work/baseline.stderr")"
grep -q "inventory up to date" <<<"$out" \
  || fail "[baseline]: --check passed but did not report 'inventory up to date'"
echo "ok [baseline] exit 0, inventory up to date"

# (a) a bench added to the attested set
stage_fixture
jq '.testbenches += ["verification/common/tb_perturb_ghost.v"]' "$attested" > "$attested.new"
mv "$attested.new" "$attested"
expect_fail "(a) bench added to attested testbenches" "testbenches diverge from"

# (b) an element of the attested cold-start argv changed
stage_fixture
jq '.cold_start.argv[1] = "-X"' "$attested" > "$attested.new"
mv "$attested.new" "$attested"
expect_fail "(b) cold_start.argv element changed" "cold_start.argv diverges from"

# (c) the workflow's 'Stamped benches' run line changed
stage_fixture
sed -i 's|run: python3 -I verification/runner.py --vvp verification/item9/benches.json$|run: python3 -I verification/runner.py --vvp verification/item9/benches.json --perturbed|' "$wf"
expect_fail "(c) 'Stamped benches' run line changed" "'Stamped benches' run line diverges from"

# (d) wrong attested PDK revision
stage_fixture
jq '.pins.pdk.revision = "0000000000000000000000000000000000000000"' "$attested" > "$attested.new"
mv "$attested.new" "$attested"
expect_fail "(d) wrong pins.pdk.revision" "pins.pdk.revision diverges from"

# (e) wrong attested Icarus pin
stage_fixture
jq '.pins.tools.icarus = "12.0"' "$attested" > "$attested.new"
mv "$attested.new" "$attested"
expect_fail "(e) wrong pins.tools.icarus" "pins.tools.icarus diverges from"

# (f) an unpinned tool added to the attested pins
stage_fixture
jq '.pins.tools.verilator = "5.0"' "$attested" > "$attested.new"
mv "$attested.new" "$attested"
expect_fail "(f) extra pins.tools key (verilator)" "pins a tool the cold start never invokes: verilator"

# (g) the ICARUS_VERSION env key renamed
stage_fixture
sed -i 's/^\([ \t]*\)ICARUS_VERSION:/\1ICARUS_VERSION_OLD:/' "$wf"
expect_fail "(g) ICARUS_VERSION env key renamed" "ICARUS_VERSION env line not found"

# (h) cocotb re-added to the attested pins -- the exemption #103 deleted
# must stay deleted; re-adding it must fail like any other unpinned tool
stage_fixture
jq '.pins.tools.cocotb = "2.0"' "$attested" > "$attested.new"
mv "$attested.new" "$attested"
expect_fail "(h) cocotb re-added to pins.tools" "pins a tool the cold start never invokes: cocotb"

# (i) the 'Stamped benches' step renamed
stage_fixture
sed -i 's/name: Stamped benches/name: Renamed benches/' "$wf"
expect_fail "(i) 'Stamped benches' step renamed" "'Stamped benches' step not found"

# (j) the icarus pin removed entirely; also trips the divergence check,
# so only the substring match distinguishes the missing-pin path
stage_fixture
jq 'del(.pins.tools.icarus)' "$attested" > "$attested.new"
mv "$attested.new" "$attested"
expect_fail "(j) icarus pin removed" "is missing a pin for icarus"

echo "test-inventory-guard: baseline + 10 perturbation cases passed"
