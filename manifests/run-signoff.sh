#!/usr/bin/env bash
# Render this block's T1 tier verdict (and its item 9 and 10 attestations) with the
# pinned klt, or verify the committed copies still reproduce.
#
#   manifests/run-signoff.sh           # regenerate envelope, manifest pin, record
#   manifests/run-signoff.sh --check   # regenerate to temp files, fail on any drift
#
# CI runs --check (.github/workflows/signoff.yml). `klt signoff --manifest`
# exits 3 when the report rendered but some T1 item is unmet, which is the
# honest state today, so 0 and 3 are both "ran clean"; anything else fails.
#
# klt pin: `klt signoff --attest` (items 9 and 10) is not in any PyPI release yet
# (0.7.0 is the newest), so the pin is a klayout-tools commit, run through a
# throwaway uvx environment. See manifests/README.md.
set -euo pipefail

KLT_COMMIT="fc02bdf0b6aa62e3553927511ee2de328fd1d186"
KLT_SPEC="git+https://github.com/2AMLogic/klayout-tools@${KLT_COMMIT}"

cd "$(dirname "${BASH_SOURCE[0]}")/.."
klt() { uvx --quiet --from "$KLT_SPEC" klt "$@"; }

MANIFEST="manifests/gf180-fpga.json"
TIERS_DOC="manifests/design-evidence-tiers.md"
RECORD="manifests/gf180-fpga.signoff.json"
# item number : inventory : envelope
ATTESTED=(
  "9:verification/signoff/item9-inventory.json:verification/signoff/item9-testbenches.json"
  "10:verification/signoff/item10-inventory.json:verification/signoff/item10-repo-hygiene.json"
)

mode="write"
[[ "${1:-}" == "--check" ]] && mode="check"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

render() { # $1 = manifest, $2 = output
  local rc=0
  klt signoff --manifest "$1" --tiers-doc "$TIERS_DOC" --format json > "$2" || rc=$?
  if [[ $rc -ne 0 && $rc -ne 3 ]]; then
    echo "::error::klt signoff exited $rc (expected 0 or 3): manifest, tier doc or cited evidence is broken" >&2
    exit 1
  fi
}

if [[ "$mode" == "check" ]]; then
  for entry in "${ATTESTED[@]}"; do
    IFS=: read -r item inventory envelope <<< "$entry"
    rc=0
    klt signoff --attest "$item" --inventory "$inventory" --check "$envelope" --format json > "$tmp/attest-check-$item.json" || rc=$?
    if [[ $rc -ne 0 ]]; then
      cat "$tmp/attest-check-$item.json" >&2
      echo "::error::item $item envelope $envelope no longer reproduces from $inventory (exit $rc). Run manifests/run-signoff.sh and commit the result." >&2
      exit 1
    fi
  done
  render "$MANIFEST" "$tmp/fresh.json"
  if ! cmp -s "$tmp/fresh.json" "$RECORD"; then
    echo "::error::Fresh klt signoff output differs from the committed record $RECORD - it is stale. Run manifests/run-signoff.sh and commit the result." >&2
    diff <(python3 -I -m json.tool "$tmp/fresh.json") <(python3 -I -m json.tool "$RECORD") || true
    exit 1
  fi
  echo "Committed item 9 and 10 envelopes and signoff record reproduce."
else
  for entry in "${ATTESTED[@]}"; do
    IFS=: read -r item inventory envelope <<< "$entry"
    klt signoff --attest "$item" --inventory "$inventory" -o "$envelope" --format json > /dev/null
    python3 -I - "$MANIFEST" "$item" "$envelope" <<'PY'
import json, sys
manifest_path, item, envelope_path = sys.argv[1:4]
m = json.load(open(manifest_path))
# The manifest pins the hash of the artifact the envelope is bound to (the
# inventory), i.e. the envelope's own provenance.input.content_hash.
pin = json.load(open(envelope_path))["provenance"]["input"]["content_hash"]
m["evidence"][item] = {"file": envelope_path, "content_hash": pin}
m["evidence"] = dict(sorted(m["evidence"].items(), key=lambda kv: int(kv[0])))
with open(manifest_path, "w") as f:
    json.dump(m, f, indent=2)
    f.write("\n")
PY
  done
  render "$MANIFEST" "$RECORD"
  echo "Wrote item 9 and 10 envelopes, $MANIFEST pins and $RECORD."
fi
