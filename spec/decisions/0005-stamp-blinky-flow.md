# ADR-0005: Stamp the sibling's blinky flow layer (`flow/common/`)

- **Status**: Accepted — ratified upon the merge of the pull request closing
  issue #144.
- **Date**: 2026-11-20
- **Related**: #144, ADR-0001, ADR-0002; sibling `sky130-fpga` #324
  (delivered by PR #337, merge `3af524c`).

## Context

Issue #144 asks for one documented command that takes a blinky from RTL to a
bitstream to a simulated blink with open tools only, from a clean clone. Per
this repo's porting doctrine the mapping flow is PDK-independent and is
designed once on the master: the deliverable to stamp is `sky130-fpga`'s
`flow/blinky.sh` and its dependency closure, landed upstream at merge
`3af524c`.

The porting plan stamped `design/` and `sim/` material but deliberately took
nothing from the sibling's `flow/` ("taking them is a decision for the
harness work, not this issue") and excluded `design/fabulous/generator.log`
("minus logs and `*results.txt`" — recorded results of sibling runs). Both
exclusions now meet the blinky deliverable:

- the flow scripts themselves must be vendored for the command to exist here;
- `flow/fabulous.sh`, which `flow/blinky.sh` runs, ends by diffing the
  normalized regenerated generator log against the committed
  `design/fabulous/generator.log` and exits nonzero on drift — it is the
  model-drift gate of the flow being stamped, not free-standing evidence of
  a sky130 physical run. (It is fabric-generation output: PDK-independent,
  derived only from the FABulous description and the pinned FABulous 2.2.0,
  both already stamped/pinned here.)

The stamped scripts address the sibling's own tree layout (`design/`,
`sim/`), which this repo deliberately does not mirror (`rtl/common/`,
`verification/common/`).

## Decision

1. **Stamp the blinky flow closure** from `sky130-fpga` at the
   `reuse.lock.json` commit into a new vendored directory `flow/common/`:
   `blinky.sh`, `tool_versions.sh`, `gate_sim_verdict.sh`, `fabulous.sh`,
   `fabulous_summary.py`, `nextpnr_io_overlay.py`, `fasm_to_bitstream.py`,
   `configmem_frames.py`, `configmem_bad_inputs.py`,
   `test_configmem_frames.py` and the shared `_modload.py`; plus `design/fabulous/nextpnr/blinky.v` and
   `blinky.pcf` (into `rtl/common/fabulous/nextpnr/`),
   `sim/bitstream_load.vh` and `sim/bitstream_corrupt.py` (into
   `verification/common/`) and the updated
   `sim/tb_logic_tile_bitstream.v` (`+design=blinky`, `+mutate`).
   `spec/check_reuse_lock.py` guards `flow/common/` like the other vendored
   trees. Path mapping gains the row `flow/` → `flow/common/`.
2. **Amend the porting plan's "minus logs" carve-out for
   `design/fabulous/generator.log` only**: it is stamped (into
   `rtl/common/fabulous/generator.log`) as the byte-held diff target of the
   flow's drift gate. Every other log/`*results.txt` exclusion stands.
3. **No vendored file is edited for this repo's layout.** The documented
   command `flow/blinky.sh` (this repo's own, not vendored) builds a
   throwaway staging tree under `flow/build/stage/` that reproduces the
   sibling's layout with symlinks into the stamped trees
   (`design/rtl` → `rtl/common/rtl`, `design/fabulous` →
   `rtl/common/fabulous`, `sim/tb_logic_tile_bitstream.v` and
   `sim/bitstream` → `verification/common/…`, `flow/*` → `flow/common/*`)
   and runs the stamped `blinky.sh` there unmodified. All generated output
   stays under the git-ignored `flow/build/`.
4. **Lock-bump drift, reported per the issue's instruction.** Moving the
   lock `42a8db0` → `3af524c` re-stamps five already-vendored `sim/`
   benches. `tb_logic_tile_bitstream.v` is the deliverable itself
   (`+design=blinky`, `+mutate`). The other four (`tb_ctrl_route.v`,
   `tb_lut_basis.v`, `tb_output_route.v`, `tb_route_diag.v`) changed in the
   sibling's `a640ac7` ("deduplicate the frame-programming bitstream loader
   into one include"), which every commit carrying the blinky deliverable
   already contains; they are re-stamped verbatim together with the new
   shared include `sim/bitstream_load.vh`. No divergence is introduced
   (`spec/check_reuse_lock.py --source <sibling checkout>` passes on all
   entries), and the four benches are excluded from this repo's item-9 runs
   (their driver inputs are not stamped), so no recorded run result here
   changes with them.

## Consequences

- `flow/common/` is vendored surface: unlisted files there fail
  `spec/check_reuse_lock.py`, and any divergence from the sibling needs its
  own decision record, as elsewhere.
- The stamped `fabulous.sh` without `FABULOUS_SKIP_TILE_REPLAY=1` would call
  `flow/generated_tile_replay.sh`, which is not stamped; the staged blinky
  path always sets the skip (upstream's own `blinky.sh` does), and running
  the sibling's wider flow here remains out of scope, as before.
- `flow/blinky.sh` writes `flow/records/blinky.json` (versions verified
  against the pins at run time, wall clock, bitstream sha256) on every
  successful run; that record — not a re-derivation — is the figure source
  for `flow/README.md` and the README pointer, and CI runs the same command
  so the claim cannot go stale silently.
- The demo is the experimental single-LOGIC4 harness (upstream's explicit
  status): a functional bitstream-level result with no timing claim, and no
  statement about the ratified fabric's routing closure.
