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
