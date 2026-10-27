# Block manifest and tier-verdict record

This block's T1 state is graded by `klt signoff --manifest`, not read by hand.

- `gf180-fpga.json` — the block manifest: `block: gf180-fpga`, `kind: digital`
  (an eFPGA tile, RTL to GDS), and one evidence citation per T1 item. Only
  item 10 is cited today; every other item is `no_evidence` until its
  evidence lands (tracker: #6). Each evidence PR adds its citation here and
  regenerates the record in the same diff.
- `design-evidence-tiers.md` — the checklist the grader parses, vendored
  byte-identical from `2AMLogic/klayout-tools` at commit
  `fc02bdf0b6aa62e3553927511ee2de328fd1d186` (`docs/design-evidence-tiers.md`,
  sha256 `a26b90262320d0fbd32b3f549a02b6300832706041797a559d8bf6bdb62efdc7`).
  To bump it, copy the new revision over this file, update the commit and hash
  here and in `run-signoff.sh`, and regenerate.
- `gf180-fpga.signoff.json` — the verdict of record: the output of
  `klt signoff --manifest manifests/gf180-fpga.json --tiers-doc
  manifests/design-evidence-tiers.md --format json`.
- `run-signoff.sh` — regenerates the item 10 envelope, the manifest's item 10
  pin and the record; `--check` is what CI runs and fails on any drift.

Item 10 is attested by `klt signoff --attest 10` from
`verification/signoff/item10-inventory.json`; the envelope it produces is
`verification/signoff/item10-repo-hygiene.json`. The manifest pins the
inventory's hash, so editing a file the inventory lists (README, LICENSE, the
workflows) makes `--check` fail until the envelope is re-attested.

## klt pin

`--attest` is not in any PyPI release (0.7.0 is the newest), so the pin is the
klayout-tools commit `fc02bdf0b6aa62e3553927511ee2de328fd1d186`
(`0.7.1.dev1772+gfc02bdf0b6aa`), run via `uvx --from git+...@<commit>`. The
committed record embeds the producing build, so regenerate with exactly that
pin. When a release containing `--attest` ships, move the pin to it.
