#!/usr/bin/env bash
# Render this block's T1 tier verdict (and its item 1, 2, 9 and 10 attestations) with the
# pinned klt, or verify the committed copies still reproduce.
#
#   manifests/run-signoff.sh           # regenerate envelope, manifest pin, record
#   manifests/run-signoff.sh --check   # regenerate to temp files, fail on any drift
#
# CI runs --check (.github/workflows/signoff.yml); for item 2 that re-attests the
# committed stream and does not re-run place-and-route (see attest_args). `klt signoff --manifest`
# exits 3 when the report rendered but some T1 item is unmet, which is the
# honest state today, so 0 and 3 are both "ran clean"; anything else fails.
#
# klt pin: klt_spec in flow/pdk.json, the PyPI release klayout-tools 0.9.0 (carries `klt signoff --attest`, incl. item 2),
# run through a throwaway uvx environment. See manifests/README.md.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
source flow/klt.sh

MANIFEST="manifests/gf180-fpga.json"
TIERS_DOC="manifests/design-evidence-tiers.md"
RECORD="manifests/gf180-fpga.signoff.json"
# item number : inventory (item 2: the committed layout stream) : envelope
ATTESTED=(
  "1:flow/tile/attest/item1.json:flow/tile/records/item1-attest.json"
  "2:layout/logic_tile_routed.gds:layout/records/item2-attest.json"
  "9:verification/signoff/item9-inventory.json:verification/signoff/item9-testbenches.json"
  "10:verification/signoff/item10-inventory.json:verification/signoff/item10-repo-hygiene.json"
)

ITEM2_ENVELOPE="layout/records/item2-attest.json"
mode="write"
[[ "${1:-}" == "--check" ]] && mode="check"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Item 2 attests the committed stream, not an inventory. The regeneration claim
# is `layout/run-par.sh --check` returning `match` (klt byte-compares the
# regenerated stream with the committed one), so the regenerated hash is the
# committed stream's hash once that check holds. Write mode gates on it (item2_gate). --check
# mode does NOT re-run place-and-route (CI has no gf180mcu PDK checkout or
# OpenROAD): it re-attests from the committed stream and confirms the envelope
# still binds to it. Whoever has the PDK verifies the regeneration claim with
# `layout/run-par.sh --check`; see layout/README.md.
# Write-mode gate for item 2. Runs in the main shell (not inside attest_args, whose
# output is read through a process substitution where `exit` would not abort).
item2_gate() { # $1 = committed stream
  local bound=""
  if [[ -f "$ITEM2_ENVELOPE" ]]; then
    bound="$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))["provenance"]["input"]["content_hash"])' "$ITEM2_ENVELOPE" 2>/dev/null || true)"
  fi
  # An unchanged stream keeps the regeneration claim already bound in the
  # committed envelope, so a host without the PDK can still re-record other
  # evidence. A changed (or unbound) stream must pass run-par.sh --check.
  if [[ -n "$bound" && "$bound" == "sha256:$(sha256sum "$1" | cut -d' ' -f1)" ]]; then
    echo "item 2: $1 is unchanged from the stream bound in $ITEM2_ENVELOPE; regeneration claim carried over from the existing envelope (layout/run-par.sh not re-run)" >&2
  else
    layout/run-par.sh --check > /dev/null \
      || { echo "::error::layout/run-par.sh --check did not match; the item 2 regeneration claim does not hold" >&2; exit 1; }
  fi
}

attest_args() { # $1 = item, $2 = inventory-or-stream
  if [[ "$1" == "2" ]]; then
    printf '%s\n' --input "$2" --generator layout/run-par.sh \
      --regenerated-hash "sha256:$(sha256sum "$2" | cut -d' ' -f1)"
  else
    printf '%s\n' --inventory "$2"
  fi
}

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
    mapfile -t aargs < <(attest_args "$item" "$inventory")
    klt signoff --attest "$item" "${aargs[@]}" --check "$envelope" --format json > "$tmp/attest-check-$item.json" || rc=$?
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
  echo "Committed item 1, 2, 9 and 10 envelopes and signoff record reproduce."
else
  for entry in "${ATTESTED[@]}"; do
    IFS=: read -r item inventory envelope <<< "$entry"
    [[ "$item" == "2" ]] && item2_gate "$inventory"
    mapfile -t aargs < <(attest_args "$item" "$inventory")
    klt signoff --attest "$item" "${aargs[@]}" -o "$envelope" --format json > /dev/null
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
  echo "Wrote item 1, 2, 9 and 10 envelopes, $MANIFEST pins and $RECORD."
fi
