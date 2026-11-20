# T1 item 9 -- attestation evidence log

Append-only. Add dated entries below; do not edit earlier ones.

## 2026-10-27 -- cited from the real block manifest (#34)

The envelope `item9-testbenches.json` (first committed in #33) was graded
against a temporary manifest because `manifests/` was not yet on `main`. That
note is superseded, not edited away: `manifests/gf180-fpga.json` now cites it
under `evidence["9"]`, pinned to the inventory hash
`sha256:f08810d1ab0c79c693cd6586d4b37bbfff076e2eca949af384245901ba9271ed`
(unchanged from #33 -- same 10 attested benches).

- Command: `manifests/run-signoff.sh` (runs `klt signoff --attest 9` and
  `klt signoff --manifest manifests/gf180-fpga.json`), then
  `manifests/run-signoff.sh --check` to confirm it reproduces.
- Result in `manifests/gf180-fpga.signoff.json`: item 9 `met`, item 10 `met`,
  `t1_met_count` 2.
- klt build: the envelope was first produced by `0.8.1.dev55+g879d39bad82b`;
  the script pins `0.7.1.dev1772+gfc02bdf0b6aa`. Attestation reproduces under
  the pin with an identical inventory hash and verdict, so the item 9 envelope
  was regenerated under the pin (only `provenance.klt_version` differs) and the
  item 10 envelope re-attested, keeping a single klt build in the record.

### Deferred: 7 benches still excluded

`verification/item9/INVENTORY.md` lists 7 benches as "not runnable: input
missing". sky130-fpga#221 is closed, but `reuse.lock.json` still pins
sky130-fpga `42a8db00e138`, so the missing inputs are not vendored here.
Extending the inventory needs a normal `reuse.lock.json` re-stamp; files are
not vendored by hand. Deferral cites 2AMLogic/sky130-fpga#221; the re-stamp is
a separate change.

### 2026-10-27: klt pin moved to klayout-tools 0.8.0

The pin moved from the dev commit `fc02bdf0b6aa` (`0.7.1.dev1772+gfc02bdf0b6aa`)
to the PyPI release `klayout-tools==0.8.0` (tag `v0.8.0`, `c572046be644`).
`manifests/run-signoff.sh` regenerated the item 9 and 10 envelopes and the
signoff record; `--check` then reproduces. The inventory hashes, the tier
verdicts and the vendored tiers doc (sha256 unchanged) are identical to before.
The differences are the build block (`version`/`package_version` `0.8.0`,
`git_tag` `v0.8.0`, `is_release` true, new `grading_ruleset_id`),
`provenance.klt_version` in both envelopes, and the item 10 hygiene hash of
`.github/workflows/verification.yml`, which this change edits. No evidence was
relaxed. The entries above are historical and still name the old build.

### 2026-11-15: unverifiable cocotb tools pin removed from the attested inventory (#103)

`pins.tools` in `item9-inventory.json` dropped the `"cocotb": "2.0.1"` key:
the attested cold-start argv (`verification/runner.py --vvp`) invokes only
`iverilog`/`vvp` and never loads cocotb, so the `passed: true` `pin`/`tools`
check asserted a dependency the attested command cannot load. The known-stale
exemption that #100 added to `verification/item9/inventory.py` for exactly
this key was removed in the same commit, leaving the unconditional guard that
`pins.tools` carries only tools the cold start invokes.

- Inventory hash moved from
  `sha256:f08810d1ab0c79c693cd6586d4b37bbfff076e2eca949af384245901ba9271ed`
  to `sha256:c79267c1ea5b1a9029357ae571aa25970da1e72e37d16fdefdfce2adda9aa499`
  (pure two-line textual deletion; re-derived with `sha256sum`, not copied).
- Command: `klt signoff --attest 9 --inventory
  verification/signoff/item9-inventory.json -o
  verification/signoff/item9-testbenches.json --format json` (the pinned
  klayout-tools 0.9.0 via `flow/klt.sh`; `attest item 9: cold_start ok in
  85.9s`), then the `manifests/run-signoff.sh:121-133` inline pin rewrite for
  `manifests/gf180-fpga.json`, then `klt signoff --manifest
  manifests/gf180-fpga.json --tiers-doc manifests/design-evidence-tiers.md
  --format json > manifests/gf180-fpga.signoff.json` (exit 3: some T1 items
  unmet, the honest state before and after this change; `t1_met_count` stays
  7).
- Result: item 9 stays `met` with `10/10 attestation checks passed`; the
  `pin`/`tools` check value is now `{"icarus": "13.0"}` with no cocotb under
  any `passed: true` check. All four pins of the inventory hash
  (`manifests/gf180-fpga.json:45`, `manifests/gf180-fpga.signoff.json:431`
  and `:440`, `verification/signoff/item9-testbenches.json:107`) were
  rewritten to the new hash and stay equal. `provenance.klt_version` stays
  `0.9.0`.
- Items 2 and 10 envelopes re-attested to byte-identical files (cmp-verified
  against the committed copies), so only the item 9 envelope moved.
  `manifests/run-signoff.sh --check` then exits 0: "Committed item 1, 2, 9
  and 10 envelopes and signoff record reproduce." (live, 2026-11-15).
- Scope note: the monolithic `manifests/run-signoff.sh` write mode could not
  complete on the dispatch host used for this regeneration — item 1's
  `local_only` freshness leg (`flow/tile/run-synth.sh --check`) hangs in the
  yosys `abc` pass (yosys-abc idle at 0% CPU waiting on the yosys pipe for
  20+ minutes, and twice killed at klt's fixed 300s `DEFAULT_YOSYS_TIMEOUT_S`
  budget), reproducibly and independently of this change; item 1's committed
  envelope is unchanged by this regeneration. The item 9, manifest-pin and
  record steps above are the exact commands write mode runs, executed
  individually, and the check-mode reproduction covers the whole evidence
  set. This entry is historical and still names the old inventory hash for
  the run it describes.

### 2026-11-20: the two CI Icarus builds share one composite action and one pin (#154)

`verification.yml` and `signoff.yml` each carried an identical 18-line
cache-and-build recipe for Icarus Verilog and declared the version
independently (`ICARUS_VERSION: "13.0"` in both `env:` blocks), so the pins
could drift apart with no check noticing — the item-9 guard read only the
verification workflow's pin. Both jobs now call
`.github/actions/setup-icarus/action.yml` (cache lookup, build on a miss,
PATH setup); the action's `icarus-version` input default is the one CI pin,
the cache key `icarus-13.0-ubuntu-24.04` is unchanged, and the action
exports `ICARUS_VERSION` so verification's two result checks compare the
observed simulator version against the shared pin instead of a hardcoded
`"13.0"`.

- `verification/item9/inventory.py` now reads the pin from the action
  (`icarus_pin()`, fail-loudly: missing file, missing input, missing
  default, empty default) and still asserts the attested
  `pins.tools.icarus` against it independently.
  `verification/item9/test-inventory-guard.sh` cases (g) and (p) were
  retargeted to the action and (s)/(t) added for the new paths — baseline
  plus 20 cases, live 2026-11-20. `INVENTORY.md` was regenerated (the pin
  source line names the action now); `item9-inventory.json` itself is
  unchanged.
- Item 10 inventory hash moved from
  `sha256:fc4bbb86801aa01289ba82f8a875a9bbbf8ee1f1870b68fbb84766c783eb8404`
  to `sha256:9c235d5a0e8ff03010555d541ff3e868a588e468cb83491ad29ddcaad7c24ebc`
  (hygiene list gained `.github/actions/setup-icarus/action.yml` and the
  description line names it; re-derived with `sha256sum`, not copied).
- Command: the exact `manifests/run-signoff.sh` write-mode steps for the
  affected item, run individually on this PDK-equipped host (item 1's
  `local_only` leg not re-run; its envelope is unchanged):
  `klt signoff --attest 10 --inventory
  verification/signoff/item10-inventory.json -o
  verification/signoff/item10-repo-hygiene.json --format json` (pinned
  klayout-tools 0.9.0 via `flow/klt.sh`), then the
  `manifests/run-signoff.sh:121-133` inline pin rewrite for
  `manifests/gf180-fpga.json`, then `klt signoff --manifest
  manifests/gf180-fpga.json --tiers-doc
  manifests/design-evidence-tiers.md --format json >
  manifests/gf180-fpga.signoff.json` (exit 3: some T1 items unmet, the
  honest state before and after).
- Result: item 10 stays `met`, now `8/8 attestation checks passed`; items
  1, 2 and 9 envelopes and their inputs are untouched; `t1_met_count`
  stays 7. All four pins of the inventory hash were checked equal after
  the rewrite. `manifests/run-signoff.sh --check` then exits 0:
  "Committed item 1, 2, 9 and 10 envelopes and signoff record reproduce"
  (live, 2026-11-20; `attest item 9: cold_start ok in 70.1s`, Icarus
  13.0 on PATH). No evidence was relaxed; the entries above are
  historical.
