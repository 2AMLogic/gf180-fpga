#!/usr/bin/env bash
# PDK-free test of the record path rewrite the smoke, tile synthesis and
# place-and-route record writers share, flow/report-paths.sh (issue #205).
#
#   flow/test-report-paths.sh
#
# The rewrite is what turns a klt JSON report into committed evidence: a
# symbolic $PDK_ROOT, no per-run scratch prefix, repo-relative paths otherwise.
# It has to recognise the PDK root before the checkout prefix, because the
# default install target is inside the checkout (flow/.pdk-root): stripped
# checkout-first, a checkout-local layer map loses the head of its path and
# the record says flow/.pdk-root/... where an external PDK says $PDK_ROOT/....
#
# Nothing is downloaded and no PDK, klt or yosys is needed. Sections 1-6 run
# the rewrite as a text filter over fixture roots. Sections 7-8 read the
# committed records as fixtures and never write them. Section 9 checks that the
# three writers delegate. Section 10 copies flow/tile/run-synth.sh into a
# scratch checkout and runs the copy against a fixture PDK store and a stub
# klt, which is how the writer's own call -- its scratch argument, its
# redirections and its provenance scan -- is exercised without the HDL tools.
#
# SC2016 is deliberate: the expected records carry a literal $PDK_ROOT, which
# only single quotes preserve.
# shellcheck disable=SC2016
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

# These prefixes appear only in report text. The writer test below uses real
# temporary directories.
checkout=/checkout
local_pdk="$checkout/flow/.pdk-root"
external_pdk=/external-pdk
scratch=/scratch
layer_map="gf180mcuD/libs.tech/klayout/tech/gf180mcu.map"

# report <pdk_root> -> the issue's sample: a layer-map path and a request path
report() {
  cat <<EOF
{
  "layer_map": {
    "path": "$1/$layer_map"
  },
  "request": {
    "path": "$checkout/layout/par.json",
    "scope": "repo"
  }
}
EOF
}

want='{
  "layer_map": {
    "path": "$PDK_ROOT/gf180mcuD/libs.tech/klayout/tech/gf180mcu.map"
  },
  "request": {
    "path": "layout/par.json",
    "scope": "repo"
  }
}'

# synth_report <pdk_root> <scratch> -> what a klt run from a scratch tree laid
# out like the checkout leaves behind: scratch-absolute paths and a PDK path
synth_report() {
  cat <<EOF
{
  "netlist_path": {
    "path": "$2/flow/tile/.klt/synthesize/run-0/logic_tile_routed_synth.v",
    "scope": "repo"
  },
  "rtl": {
    "path": "$2/rtl/common/logic_tile.v"
  },
  "request": {
    "path": "$2/flow/tile/synth.json"
  },
  "layer_map": {
    "path": "$1/$layer_map"
  }
}
EOF
}

synth_want='{
  "netlist_path": {
    "path": "flow/tile/.klt/synthesize/run-0/logic_tile_routed_synth.v",
    "scope": "repo"
  },
  "rtl": {
    "path": "rtl/common/logic_tile.v"
  },
  "request": {
    "path": "flow/tile/synth.json"
  },
  "layer_map": {
    "path": "$PDK_ROOT/gf180mcuD/libs.tech/klayout/tech/gf180mcu.map"
  }
}'

# shellcheck disable=SC1091  # the file under test is located at run time
source "$root/flow/report-paths.sh"

# ---------------------------------------------------------------- 1. a PDK inside the checkout
out="$(report_path_rewrite "$checkout" "$local_pdk" <<<"$(report "$local_pdk")")"
[[ "$out" == "$want" ]] || fail "checkout-local PDK: record is not the reference form: $out"

# Only the PDK directory itself and its children take the symbolic prefix.
out="$(report_path_rewrite "$checkout" "$local_pdk" -- <<EOF
["$local_pdk", "$local_pdk/map", "$local_pdk-backup/map", "$checkout/flow/Xpdk-root/map"]
EOF
)"
[[ "$out" == '["$PDK_ROOT", "$PDK_ROOT/map", "flow/.pdk-root-backup/map", "flow/Xpdk-root/map"]' ]] \
  || fail "PDK directory boundary: $out"

# ---------------------------------------------------------------- 2. an external PDK
out="$(report_path_rewrite "$checkout" "$external_pdk" <<<"$(report "$external_pdk")")"
[[ "$out" == "$want" ]] || fail "external PDK: record is not the reference form: $out"

# ---------------------------------------------------------------- 3. negative control
# The expressions the three writers carried before #205, checkout prefix
# first, on the same input: they must still show the defect, or sections 1-2
# would pass for the wrong reason.
out="$(report "$local_pdk" | sed -e "s#$checkout/##g" -e "s#$local_pdk#\$PDK_ROOT#g")"
[[ "$out" == *'"path": "flow/.pdk-root/gf180mcuD/'* ]] \
  || fail "negative control: the checkout-first order no longer shows the defect: $out"

# ---------------------------------------------------------------- 4. the synthesis writer's scratch prefix
for pdk in "$local_pdk" "$external_pdk"; do
  out="$(report_path_rewrite "$checkout" "$pdk" "$scratch" <<<"$(synth_report "$pdk" "$scratch")")"
  [[ "$out" == "$synth_want" ]] || fail "scratch prefix (pdk=$pdk): record is not the reference form: $out"
done

# The scratch prefix is stripped only where a scratch directory is passed:
# the smoke and P&R writers pass none, so a scratch path must survive them.
in="$(synth_report "$external_pdk" "$scratch")"
out="$(report_path_rewrite "$checkout" "$external_pdk" <<<"$in")"
[[ "$out" == "$(synth_report '$PDK_ROOT' "$scratch")" ]] \
  || fail "a scratch path was stripped without a <scratch> argument: $out"

# A scratch directory under the checkout loses its own prefix first.
nested="$checkout/tmp/run-0"
out="$(report_path_rewrite "$checkout" "$local_pdk" "$nested" <<<"$(synth_report "$local_pdk" "$nested")")"
[[ "$out" == "$synth_want" ]] || fail "scratch inside the checkout: record is not the reference form: $out"

# The checkout and scratch arguments are literal directories, too.
out="$(report_path_rewrite '/repo.v1' '/pdk[0]#1' '/scratch.v1' <<'EOF'
["/repo.v1/a", "/repoXv1/a", "/other/repo.v1/a", "/scratch.v1/b", "/scratchXv1/b", "/pdk[0]#1/map", "/pdk0#1/map"]
EOF
)"
[[ "$out" == '["a", "/repoXv1/a", "/other/repo.v1/a", "b", "/scratchXv1/b", "$PDK_ROOT/map", "/pdk0#1/map"]' ]] \
  || fail "literal directory names: $out"

# ---------------------------------------------------------------- 5. in place
# The smoke and P&R writers rewrite the record where klt wrote it.
mkdir -p "$work/rec"
report "$local_pdk" > "$work/rec/a.json"
report "$local_pdk" > "$work/rec/b.json"
out="$(report_path_rewrite "$checkout" "$local_pdk" -- "$work"/rec/*.json)"
[[ -z "$out" ]] || fail "in place: wrote to stdout as well: $out"
for f in a b; do
  [[ "$(cat "$work/rec/$f.json")" == "$want" ]] \
    || fail "in place: $f.json was not rewritten: $(cat "$work/rec/$f.json")"
done
[[ "$(ls "$work/rec")" == $'a.json\nb.json' ]] || fail "in place: left a file behind: $(ls "$work/rec")"

printf '["%s/build--/layout/par.json", "--/file"]\n' "$checkout" > "$work/no-scratch.json"
report_path_rewrite "$checkout" "$local_pdk" -- "$work/no-scratch.json"
jq -e '. == ["build--/layout/par.json", "--/file"]' "$work/no-scratch.json" > /dev/null \
  || fail "no scratch argument: --/ in a directory name was stripped"

# ---------------------------------------------------------------- 6. a refused call rewrites nothing
# An empty <pdk_root> would otherwise become an empty pattern, which prefixes
# every line of the record with $PDK_ROOT.
report "$local_pdk" > "$work/guard.json"
out="$(report_path_rewrite "" "$local_pdk" < "$work/guard.json" 2>"$work/stderr")" \
  && fail "an empty <repo> was accepted"
[[ -z "$out" ]] || fail "an empty <repo> rewrote the input"
grep -q 'report_path_rewrite: <repo> and <pdk_root> are required' "$work/stderr" \
  || fail "an empty <repo>: no diagnostic: $(cat "$work/stderr")"
out="$(report_path_rewrite "$checkout" "" < "$work/guard.json" 2>"$work/stderr")" \
  && fail "an empty <pdk_root> was accepted"
[[ -z "$out" ]] || fail "an empty <pdk_root> rewrote the input"
grep -q 'report_path_rewrite: <repo> and <pdk_root> are required' "$work/stderr" \
  || fail "an empty <pdk_root>: no diagnostic: $(cat "$work/stderr")"

# Files must follow --; without it the first would be read as <scratch>.
cp "$work/rec/b.json" "$work/rec/c.json"
cp "$work/rec/b.json" "$work/rec/d.json"
report_path_rewrite "$checkout" "$local_pdk" "$work/rec/c.json" "$work/rec/d.json" 2>"$work/stderr" \
  && fail "files without -- were accepted"
grep -q 'report_path_rewrite: expected -- before' "$work/stderr" \
  || fail "files without --: no diagnostic: $(cat "$work/stderr")"
cmp -s "$work/rec/c.json" "$work/rec/d.json" || fail "files without --: a file was rewritten"
rm "$work/rec/c.json" "$work/rec/d.json"

# ---------------------------------------------------------------- 7. committed evidence is left alone
# Every committed record is already in final form, so the rewrite its own
# writer applies must return it unchanged from either PDK location.
for pdk in "$local_pdk" "$external_pdk"; do
  for rec in "$root/layout/records/step0-par.json" "$root"/flow/smoke/records/mcu*.json; do
    out="$(report_path_rewrite "$root" "$pdk" < "$rec")"
    [[ "$out" == "$(cat "$rec")" ]] || fail "$rec is changed by the rewrite (pdk=$pdk)"
  done
  rec="$root/flow/tile/records/synth.json"
  out="$(report_path_rewrite "$root" "$pdk" "$scratch" < "$rec")"
  [[ "$out" == "$(cat "$rec")" ]] || fail "$rec is changed by the rewrite (pdk=$pdk)"
done

# ---------------------------------------------------------------- 8. committed evidence round-trips
# Put back what the P&R writer stripped -- the checkout prefix on every
# repo-relative path, and a real PDK root in place of $PDK_ROOT -- and the
# rewrite must reproduce the committed record byte for byte from either PDK
# location: the issue's check, on the real record.
record="$root/layout/records/step0-par.json"
for pdk in "$local_pdk" "$external_pdk"; do
  sed -E -e "s#\"(layout|flow)/#\"$checkout/\\1/#g" -e "s#\\\$PDK_ROOT#$pdk#g" \
    "$record" > "$work/raw-par.json"
  jq -e --arg checkout "$checkout" --arg map "$pdk/$layer_map" \
    '.netlist.path == ($checkout + "/flow/tile/netlist/logic_tile_routed_synth.v") and .layer_map.path == $map' \
    "$work/raw-par.json" > /dev/null || fail "round trip: netlist or layer map was not expanded (pdk=$pdk)"
  report_path_rewrite "$checkout" "$pdk" < "$work/raw-par.json" | cmp -s - "$record" \
    || fail "round trip: the P&R record did not come back byte for byte (pdk=$pdk)"
done

# ---------------------------------------------------------------- 9. the three writers delegate
for w in flow/smoke/run-smoke.sh flow/tile/run-synth.sh layout/run-par.sh; do
  grep -q 'report-paths\.sh' "$root/$w" || fail "$w does not source flow/report-paths.sh"
  grep -q 'report_path_rewrite ' "$root/$w" || fail "$w does not call report_path_rewrite"
  grep -q 'PDK_ROOT#g' "$root/$w" && fail "$w carries its own \$PDK_ROOT substitution again"
done

# ---------------------------------------------------------------- 10. the synthesis writer, end to end
# run-synth.sh derives everything from its own location, so the copy is the
# one exercised. pdk-root.sh and setup-pdk.sh --verify read only
# <root>/<variant>/SOURCES and the library directories (flow/test-pdk-root.sh),
# so a store of nearly empty directories stands in for the 3.6 GB one.
tree="$work/e2e"
external_pdk="$work/external-pdk"
mkdir -p "$tree/flow/tile" "$tree/rtl" "$work/home"
cp "$root/flow/report-paths.sh" "$root/flow/pdk-root.sh" "$root/flow/setup-pdk.sh" \
   "$root/flow/pdk.json" "$tree/flow/"
cp "$root/flow/tile/run-synth.sh" "$root/flow/tile/synth.json" "$tree/flow/tile/"
git init -q "$tree"

rev="$(jq -er .open_pdks_revision "$tree/flow/pdk.json")"
mapfile -t variants < <(jq -er '.variants[]' "$tree/flow/pdk.json")
mapfile -t libs < <(jq -er '.libraries[]' "$tree/flow/pdk.json")

# mkstore <root>
mkstore() {
  local v l
  for v in "${variants[@]}"; do
    mkdir -p "$1/$v"
    printf 'open_pdks %s\n' "$rev" > "$1/$v/SOURCES"
    for l in "${libs[@]}"; do mkdir -p "$1/$v/libs.ref/$l"; done
  done
}
mkstore "$tree/flow/.pdk-root"
mkstore "$external_pdk"

# klt stub. `synthesize` writes the netlist klt would and prints a report
# carrying the host-absolute paths klt would record: inside the scratch run
# dir ($PWD), in the checkout itself (the rtl symlink, resolved), and under
# $PDK_ROOT. `env-provenance scan` logs its call and fails should any of
# those three prefixes have survived in the record.
cat > "$tree/flow/klt.sh" <<'EOF'
klt() {
  case "$1" in
    synthesize)
      mkdir -p .klt/synthesize/run-0
      : > .klt/synthesize/run-0/logic_tile_routed_synth.v
      rtl="$(cd ../../rtl && pwd -P)"
      printf '%s\n' "$(cd ../.. && pwd)" > "$KLT_SCRATCH_LOG"
      cat <<JSON
{
  "netlist_path": {
    "path": "$PWD/.klt/synthesize/run-0/logic_tile_routed_synth.v",
    "scope": "repo"
  },
  "rtl": {
    "path": "$rtl/common/logic_tile.v",
    "scope": "external"
  },
  "request": {
    "path": "$PWD/synth.json"
  },
  "layer_map": {
    "path": "$PDK_ROOT/gf180mcuD/libs.tech/klayout/tech/gf180mcu.map"
  }
}
JSON
      ;;
    env-provenance)
      printf '%s\n' "$*" >> "$KLT_CALL_LOG"
      leak=( -e "$PDK_ROOT/" -e "$REPO_ROOT/" )
      [[ -s "$KLT_SCRATCH_LOG" ]] && leak+=( -e "$(cat "$KLT_SCRATCH_LOG")/" )
      if grep -F "${leak[@]}" "$3"; then
        echo "klt stub: a host-absolute path survived in $3" >&2
        return 1
      fi
      ;;
    *) echo "klt stub: unexpected call: $*" >&2; return 2 ;;
  esac
}
EOF

RUN_RC=0
run_writer() {  # run_writer [VAR=value ...] -> RUN_RC
  local rc=0
  rm -rf "$tree/flow/tile/records" "$tree/flow/tile/netlist" "$work/klt-calls"
  rm -f "$work/klt-scratch"
  ( cd "$tree" && env -u PDK_ROOT -u CIEL_PDK_ROOT "HOME=$work/home" "PATH=$PATH" \
      "REPO_ROOT=$tree" "KLT_CALL_LOG=$work/klt-calls" "KLT_SCRATCH_LOG=$work/klt-scratch" \
      "$@" timeout 30 bash flow/tile/run-synth.sh ) >"$work/stdout" 2>"$work/stderr" || rc=$?
  RUN_RC=$rc
}

record="$tree/flow/tile/records/synth.json"
e2e_want='{
  "netlist_path": {
    "path": "flow/tile/.klt/synthesize/run-0/logic_tile_routed_synth.v",
    "scope": "repo"
  },
  "rtl": {
    "path": "rtl/common/logic_tile.v",
    "scope": "external"
  },
  "request": {
    "path": "flow/tile/synth.json"
  },
  "layer_map": {
    "path": "$PDK_ROOT/gf180mcuD/libs.tech/klayout/tech/gf180mcu.map"
  }
}'

# check_writer <label>
check_writer() {
  [[ $RUN_RC -eq 0 ]] || fail "run-synth.sh, $1: expected exit 0, got $RUN_RC: $(cat "$work/stderr")"
  [[ -f "$record" ]] || fail "run-synth.sh, $1: no record written"
  [[ "$(cat "$record")" == "$e2e_want" ]] \
    || fail "run-synth.sh, $1: unexpected record: $(cat "$record")"
  [[ -f "$tree/flow/tile/netlist/logic_tile_routed_synth.v" ]] \
    || fail "run-synth.sh, $1: the netlist was not pinned"
  grep -qxF "env-provenance scan $record" "$work/klt-calls" \
    || fail "run-synth.sh, $1: the record was not provenance-scanned: $(cat "$work/klt-calls")"
}

# 10a. the PDK at the default install target, inside the checkout
run_writer
check_writer "checkout-local PDK"

# 10b. an external PDK: the same record
run_writer "PDK_ROOT=$external_pdk"
check_writer "external PDK"

# 10c. mktemp under the checkout ($TMPDIR): the scratch prefix still goes
mkdir -p "$tree/tmp"
run_writer "TMPDIR=$tree/tmp"
check_writer "scratch inside the checkout"

echo "ok"
