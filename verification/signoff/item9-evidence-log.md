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
