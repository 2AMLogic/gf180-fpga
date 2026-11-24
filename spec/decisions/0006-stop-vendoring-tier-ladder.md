# ADR-0006: Stop vendoring the design-evidence tier ladder

- **Status**: Accepted — operator ruling of 2026-11-23 (attended
  `/fleet:decide` session, round 20261121-r19, q103), landed by the pull
  request closing issue #89.
- **Date**: 2026-11-23
- **Related**: #89, #6, ADR-0002; upstream `2AMLogic/klayout-tools` #5041
  (the fleet-wide ruling: stop vendoring `docs/design-evidence-tiers.md`
  into chip repos).

## Context

The T1 checklist the signoff grader parses — klayout-tools'
`docs/design-evidence-tiers.md` — was vendored into this repo as
`manifests/design-evidence-tiers.md` and fed to `klt signoff` via
`--tiers-doc`, with the tag and sha256 recorded in `manifests/README.md` and
a manual bump procedure to keep it current.

That made the ladder a second, separately-pinned copy of data the repo
already pins: `klt_spec` in `flow/pdk.json` selects the klayout-tools
release, and that wheel bundles the same document as package data (used
automatically when `--tiers-doc` is omitted). The two pins drifted — the
vendored copy was byte-identical to klt v0.8.0 (`a26b9026…`, 1053 lines)
while the grader was pinned at 0.9.0, whose bundled copy is 1108 lines
(`08dcbfd2…`) with 6 of the 11 T1 items changed text. Nothing caught the
drift: the record's `t1_item_count` guard is count-granularity and both
versions have 11 items, and `klt signoff` accepts a divergent `--tiers-doc`
silently. Per-item verdicts were unaffected (the drift was latent, not a
mis-grade).

An operator ruling (2026-11-23, `/fleet:decide` round 20261121-r19, q103,
made once for the twelve repos that asked) directed the removal fleet-wide:
the pinned klayout-tools release alone selects the checklist.

## Decision

1. `manifests/design-evidence-tiers.md` is deleted; the repo holds no copy
   of the ladder.
2. No caller passes `--tiers-doc`: `manifests/run-signoff.sh` renders with
   `klt signoff --manifest … --format json` and the grader reads the ladder
   bundled in the wheel that `klt_spec` (`flow/pdk.json`) pins.
3. `manifests/README.md` and `ROADMAP.md` link the document in
   `2AMLogic/klayout-tools` at the pinned tag instead of a local file; the
   revision actually graded against stays identified by the record's
   `source_doc` / `source_doc_content_hash`.
4. The CI comparison (`manifests/run-signoff.sh --check`, the `signoff`
   job) is kept unchanged: a fresh run is still byte-compared against the
   committed record, which is what surfaces a checklist change at a pin
   bump.

This reverses the vendoring that `manifests/README.md` ratified, per the
ruling cited above; recorded evidence naming the old path or `--tiers-doc`
command (e.g. `verification/signoff/item9-evidence-log.md`) is append-only
history and is not rewritten.

## Alternatives considered

- **Re-vendor at v0.9.0 with a hash check** (fail CI when the committed
  copy diverges from the pinned wheel's): rejected by the ruling — it keeps
  the 1053-line second pin and the sync procedure the ruling removes.
- **Keep the drifted copy**: rejected; a 0.8.0 ladder under a 0.9.0 grader
  is exactly the silent divergence the record's provenance fields exist to
  expose.

## Consequences

- The graded ladder's text is no longer reviewable in a repo diff; it is
  reviewable upstream, at the tag `klt_spec` names. Reproducibility is
  unchanged: the pin selects the wheel, the wheel bundles the doc, and the
  record embeds `source_doc_content_hash` plus the producing build.
- A klt pin bump that changes the checklist changes the fresh
  `run-signoff.sh` render and fails `--check` until the record is
  regenerated — by design (move the pin only together with a regenerated
  record).
- In-repo review of a proposed checklist change happens through an
  upstream PR to `2AMLogic/klayout-tools`, not here.
