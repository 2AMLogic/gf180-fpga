# Block manifest and tier-verdict record

This block's T1 state is graded by `klt signoff --manifest`, not read by hand.

- `gf180-fpga.json` — the block manifest: `block: gf180-fpga`, `kind: digital`
  (an eFPGA tile, RTL to GDS), and one evidence citation per T1 item. Items 1,
  2, 9 and 10 (attested), item 4 (`layout/records/lvs.json`, a `klt lvs` report; see `layout/README.md`), item 11 (`layout/records/erc.json` + `lvs.json` + `step0-par.json`, a compound citation; see `layout/README.md`) and item 6 (`not_applicable`: `spec.json` plus
  `item6-na-statement.json`, no statistical row) are cited today; every other
  item is `no_evidence` until its
  evidence lands (tracker: #6). Each evidence PR adds its citation here and
  regenerates the record in the same diff.
- The T1 checklist is no longer vendored here: it comes from the pinned klt
  alone (`klt_spec` in `flow/pdk.json`), whose wheel bundles the ladder as
  package data when `--tiers-doc` is omitted. The document is
  [`docs/design-evidence-tiers.md` in `2AMLogic/klayout-tools`](https://github.com/2AMLogic/klayout-tools/blob/v0.9.0/docs/design-evidence-tiers.md)
  at the tag the pin names (v0.9.0 today); the revision actually graded
  against is identified by `source_doc` / `source_doc_content_hash` in the
  record. Vendoring it was removed by operator ruling (2026-11-23); see
  ADR-0006.
- `gf180-fpga.signoff.json` — the verdict of record: the output of
  `klt signoff --manifest manifests/gf180-fpga.json --format json`.
- `run-signoff.sh` — regenerates the item 1, 2, 9 and 10 envelopes, the manifest's
  pins and the record; `--check` is what CI runs and fails on any drift.

Item 9 is attested the same way from `verification/signoff/item9-inventory.json`
into `verification/signoff/item9-testbenches.json` (log:
`verification/signoff/item9-evidence-log.md`).

Item 10 is attested by `klt signoff --attest 10` from
`verification/signoff/item10-inventory.json`; the envelope it produces is
`verification/signoff/item10-repo-hygiene.json`. The manifest pins the
inventory's hash, so editing a file the inventory lists (README, LICENSE, the
workflows) makes `--check` fail until the envelope is re-attested.

Item 2 is attested by `klt signoff --attest 2 --input layout/logic_tile_routed.gds`
into `layout/records/item2-attest.json`, with `layout/run-par.sh` as the
recorded generator. Writing (`run-signoff.sh`) passes the committed stream's hash as
the regenerated hash only after `layout/run-par.sh --check` returns `match`.
`run-signoff.sh --check` (the `signoff` CI job) does not re-run place-and-route,
since that job has no gf180mcu PDK or OpenROAD: it re-attests from the committed
stream and confirms the envelope still binds to it. The regeneration claim itself
is verified wherever the PDK is set up, with `layout/run-par.sh --check`.

Write mode (`run-signoff.sh` with no flag) requires the pinned gf180mcu PDK on the
host: item 1's inventory declares a `local_only` check that re-runs
`flow/tile/run-synth.sh --check`. It runs `flow/setup-pdk.sh --verify` first and
exits 2 with a message naming the PDK, before modifying any envelope, manifest pin
or record. `--check` (CI) needs no PDK and is unchanged.

## klt pin

The pin is the PyPI release `klayout-tools==0.9.0` (`klt 0.9.0`, tag `v0.9.0`,
commit `5dbbad05ff42`), run via `uvx --from` the `klt_spec` in `flow/pdk.json` (see `flow/klt.sh`); `--attest`
(items 1, 2, 9, 10) ships in it. The committed record embeds the producing build, so regenerate
with exactly that pin, and move the pin only together with a regenerated record.
