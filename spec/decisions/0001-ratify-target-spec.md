# ADR-0001: Ratify the gf180mcu target spec

- **Status**: Accepted — ratified upon the merge of the pull request closing
  issue #2.
- **Date**: 2026-10-17
- **Related**: #2, `spec/target-spec.md`, `spec/porting-plan.md`,
  `reuse.lock.json`. Sibling records are cited by their sibling numbers
  (`sky130-fpga` ADR-0001 is the framework choice; it is a different record
  from this one).

## Context

The README carried a DRAFT target table. This port keeps the sibling's
architecture and re-derives everything physical. The spec must be fixed before
any placement, routing or timing run so results cannot move it.

## Decision

1. **Ratify `spec/target-spec.md`**: the library, supply, metal-stack,
   area/aspect, timing, corner, fabric-size and signoff rows exactly as written
   there, including the pre-named routing-closure ladder and the rule that no
   µm² ceiling and no Fmax figure are ratified yet.
2. **Inherit** the sibling's architecture and ADR-0001 (framework) unchanged,
   and the timing claim *shape* from its ADR-0002/0003 without any number. The
   sibling's ADR-0004, 0005 and 0006 are **Proposed** at the commit read
   (`42a8db00e138aa892a388b077a8ae2ea2ccab511`); they are inherited as
   Proposed and are not decided here.
3. **Stamp** the PDK-independent RTL, FABulous description and bitstream-level
   test material as vendored copies (173 files, `reuse.lock.json`), verified by
   `spec/check_reuse_lock.py`. A vendored file diverges only with a decision
   record.
4. **Resolve the open questions as follows**:

| Question | Resolution |
|---|---|
| Does pinned FABulous generate a gf180mcu fabric out of the box? | **Deferred**, not run. No copied file references a PDK, so no change is expected. Confirmed by a generator run in the harness work (#4); any change to a vendored file then needs a decision record. |
| Will the 4-track matrix route on the chosen stack? | **Deferred** to the first routed-tile run, with the experiment and ladder in `target-spec.md`. Steps 1–3 are recorded results; step 4 is a spec change. |
| What does the sibling's incomplete bitstream-level verification mean for claims? | **Inherited.** No functional claim until bitstream-level tests pass here on the stamped set; the stand-in matrix status travels with the vendored RTL (see `porting-plan.md`). |

## Alternatives considered

- **Choose numbers by analogy to sky130** (period, area): rejected; the
  repo's rule is that no sky130 number transfers.
- **Ratify an area ceiling now**: rejected; a ceiling set before a routed tile
  is a guess and one set after is a quiet relaxation.
- **Ratify an Fmax**: rejected; only bisected, characterized data can back it.
- **Pick `gf180mcuA`–`C` as target stack**: A has two fine layers and is out of
  range; C is indistinguishable from D in the tech LEF, and D was the variant
  used for the scoping probe. Revisit with evidence from #3.
- **Make the first fallback a 4-metal stack**: the ladder instead starts with
  area, then layers, then library, because each step must be recorded as a
  measured result before anything architectural moves.

## Consequences

- Later issues cite `target-spec.md` rows instead of redefining them.
- Results that miss a row are reported as misses; relaxing a row requires a
  superseding decision record.
- `README.md` target table is regenerated from this spec and must stay a
  subset of it.

## Known limits

Library, corner and layer facts were read from open_pdks `f6eeac7…` as
installed on the authoring host; #3 owns the pin. C-versus-D differences beyond
the tech LEF, and a FABulous generator run, were not checked.
