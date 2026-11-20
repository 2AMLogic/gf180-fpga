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
# Case inventory: (a)-(j) are the original net (issue #109, added by
# PR #122) -- the five divergence assertions plus the pin-parser
# fail-loudly paths they can ride on. (k)-(r) (issue #126) extend the
# same net to the assertions it did not cover: both arms of the
# staleness check, the bench-set scans (unstamped, ghost,
# both-run-and-excluded) and the remaining workflow-parsing paths
# (block scalar, missing run line). (g) and (p) were retargeted to the
# shared setup-icarus action when the single CI Icarus pin moved there
# (#154), and (s)-(t) extend the net to the new action-parsing paths
# (no default, action file deleted). With them every ERROR: site in
# inventory.py -- 18 distinct sites -- is netted by the 20 cases.
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
action="$work/.github/actions/setup-icarus/action.yml"
benches="$work/verification/item9/benches.json"
invmd="$work/verification/item9/INVENTORY.md"

fail() { echo "FAIL: $*" >&2; exit 1; }

# (Re)copy every file inventory.py reads, pristine. Called before every
# case so each perturbation starts from the baseline and the cases are
# independent and order-insensitive.
stage_fixture() {
  rm -rf "$work/verification" "$work/rtl" "$work/flow" "$work/.github"
  mkdir -p "$work/verification/item9" "$work/verification/signoff" \
           "$work/flow" "$work/.github/workflows" \
           "$work/.github/actions/setup-icarus"
  cp "$root/verification/item9/inventory.py" "$inv"
  cp "$root/verification/item9/benches.json" "$root/verification/item9/INVENTORY.md" \
     "$work/verification/item9/"
  cp "$root/verification/signoff/item9-inventory.json" "$attested"
  cp "$root/.github/workflows/verification.yml" "$wf"
  cp "$root/.github/actions/setup-icarus/action.yml" "$action"
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

# (g) the action's icarus-version input renamed; the guard can no longer
# find the one place the CI pin is declared
stage_fixture
sed -i 's/^\([ \t]*\)icarus-version:/\1icarus-version-old:/' "$action"
expect_fail "(g) icarus-version input renamed" "icarus-version input not found"

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

# (k) INVENTORY.md modified -- the rendered-text arm of the guard's
# primary staleness assertion
stage_fixture
printf 'x' >> "$invmd"
expect_fail "(k) INVENTORY.md appended a byte" "is stale; run verification/item9/inventory.py"

# (l) INVENTORY.md absent -- the file-missing arm of the same assertion
stage_fixture
rm "$invmd"
expect_fail "(l) INVENTORY.md deleted" "is stale; run verification/item9/inventory.py"

# (m) a stamped tb_*.v neither run nor excluded -- the module docstring's
# stated purpose: a newly stamped bench cannot be silently left out
stage_fixture
mkdir -p "$work/verification/common"
: > "$work/verification/common/tb_perturb_unstamped.v"
expect_fail "(m) unstamped tb_*.v created on disk" "stamped bench neither run nor excluded"

# (n) a listed bench that is not on disk; perturbed via excluded[] so
# exactly one assertion fires -- perturbing runs[] would also trip the
# attested-set comparison and the case would pass with the wrong
# assertion doing the work
stage_fixture
jq '.excluded += [{"bench":"verification/common/tb_nonexistent.v","status":"x","reason":"y"}]' "$benches" > "$benches.new"
mv "$benches.new" "$benches"
expect_fail "(n) ghost bench in excluded" "listed bench not on disk"

# (o) a bench both run and excluded -- contradictory benches.json
stage_fixture
jq '.excluded += [{"bench":"verification/common/tb_lut4_slice.v","status":"x","reason":"y"}]' "$benches" > "$benches.new"
mv "$benches.new" "$benches"
expect_fail "(o) bench both run and excluded" "both run and excluded"

# (p) the action's icarus-version default emptied. An absent default
# line is the separate (s) path; `default: ""` is what reaches the
# empty-value branch
stage_fixture
sed -i 's/^\([ \t]*\)default:.*/\1default: ""/' "$action"
expect_fail "(p) icarus-version default emptied" "has an empty value"

# (q) the 'Stamped benches' run line made a block scalar
stage_fixture
sed -i 's@^\([ \t]*\)run: python3 -I verification/runner.py --vvp verification/item9/benches.json$@\1run: |\n\1python3 -I verification/runner.py --vvp verification/item9/benches.json@' "$wf"
expect_fail "(q) 'Stamped benches' run made a block scalar" "is not a single-line command"

# (r) the 'Stamped benches' run line removed outright; the scan runs to
# the next '- name:' and reports the step has no run: line
stage_fixture
sed -i '\|^[ \t]*run: python3 -I verification/runner.py --vvp verification/item9/benches.json$|d' "$wf"
expect_fail "(r) 'Stamped benches' run line removed" "has no run: line"

# (s) the action's icarus-version default line removed; the input block
# scan ends without a default to assert the attested pin against
stage_fixture
sed -i '/^\([ \t]*\)default:/d' "$action"
expect_fail "(s) icarus-version default removed" "has no default"

# (t) the shared action deleted outright; the guard has no pin source
stage_fixture
rm "$action"
expect_fail "(t) setup-icarus action deleted" "action.yml not found"

echo "test-inventory-guard: baseline + 20 perturbation cases passed"
