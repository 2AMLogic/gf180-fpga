#!/usr/bin/env bash
# PDK-free test of manifests/run-signoff.sh write mode for item 2: an unchanged
# routed stream carries the regeneration claim over; a changed one requires
# layout/run-par.sh --check (stubbed here to fail). klt is stubbed too.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

mkdir -p "$work"/{manifests,flow,layout/records}
cp "$root/manifests/run-signoff.sh" "$work/manifests/"
printf 'stream-v1' > "$work/layout/logic_tile_routed.gds"
h="sha256:$(sha256sum "$work/layout/logic_tile_routed.gds" | cut -d' ' -f1)"
printf '{"provenance":{"input":{"content_hash":"%s"}}}\n' "$h" > "$work/layout/records/item2-attest.json"
printf '{"evidence":{}}\n' > "$work/manifests/gf180-fpga.json"
printf '#!/usr/bin/env bash\nexit 1\n' > "$work/layout/run-par.sh"; chmod +x "$work/layout/run-par.sh"
# stub klt: --attest writes an envelope bound to the stream/inventory; signoff renders {}
cat > "$work/flow/klt.sh" <<'STUB'
klt() {
  local out="" input="" i=("$@")
  for ((k=0;k<${#i[@]};k++)); do
    case "${i[k]}" in -o) out="${i[k+1]}";; --input|--inventory) input="${i[k+1]}";; esac
  done
  if [[ "$1 $2" == "signoff --attest" ]]; then
    mkdir -p "$(dirname "$out")"
    printf '{"provenance":{"input":{"content_hash":"sha256:%s"}}}\n' "$(sha256sum "$input" | cut -d' ' -f1)" > "$out"
  else echo '{}'; fi
}
STUB
# items 1, 9, 10 inventories (content irrelevant to the stub)
mkdir -p "$work/flow/tile/attest" "$work/verification/signoff"
for f in flow/tile/attest/item1.json verification/signoff/item9-inventory.json verification/signoff/item10-inventory.json; do echo '{}' > "$work/$f"; done

fail() { echo "FAIL: $*" >&2; exit 1; }

# unchanged stream: write mode must succeed without run-par.sh
out="$(cd "$work" && manifests/run-signoff.sh 2>&1)" || fail "unchanged stream: write mode failed: $out"
grep -q 'carried over from the existing envelope' <<<"$out" || fail "no carry-over line: $out"

# changed stream: write mode must fail and name layout/run-par.sh
printf 'stream-v2' > "$work/layout/logic_tile_routed.gds"
if out="$(cd "$work" && manifests/run-signoff.sh 2>&1)"; then fail "changed stream: write mode succeeded"; fi
grep -q 'layout/run-par.sh' <<<"$out" || fail "error does not name layout/run-par.sh: $out"

# missing envelope: falls through to the strict path
printf 'stream-v1' > "$work/layout/logic_tile_routed.gds"; rm "$work/layout/records/item2-attest.json"
if (cd "$work" && manifests/run-signoff.sh >/dev/null 2>&1); then fail "missing envelope: write mode succeeded"; fi
echo "ok"
