# ADR-0004: Defer a standalone gf180mcu FPGA configuration

- **Status**: Accepted — ratified upon the merge of the pull request closing
  issue #145.
- **Date**: 2026-11-19
- **Related**: #145, ADR-0001, #27, #143, #144; siblings `sky130-fpga` #325
  and `sg13g2-fpga` #139 (issues, not ADRs) ask the same question. All
  numbers below are read from committed records at `939645c` (`origin/main`,
  2026-11-19), measured with klt 0.9.0 unless noted.

## Context

The ratified scope (ADR-0001) is one LUT4-class logic tile plus a 2×2–4×4
demonstration fabric. A standalone FPGA of a few hundred to ~1000 LUTs with
I/O would need at least one tile type that does not exist here (programmable
I/O), configuration storage and a load path (the tile takes a flat parallel
158-bit `cfg[157:0]` port, `rtl/common/rtl/logic_tile_routed.v`), and a
fabric far larger than the demonstration. `CLAUDE.md` declines new tile
types before the tile is verified, and a spec change goes through a decision
record — this one.

What the committed evidence says today, from the measured routed tile:

- Tile dies at 117.60 × 113.68 µm = 13,368.8 µm² (core 11,261.4 µm², DEF
  `UNITS DISTANCE MICRONS 2000`, `DIEAREA 235200 × 227360`;
  `layout/logic_tile_routed.def`, `layout/README.md`, run dated 2026-11-14).
  4 LUT4s per tile (`spec/target-spec.md`), 158 configuration bits per tile.
  Routing closes at ladder step 0 (0 overflow, 0 detailed-route DRC, 0
  antenna), DRC clean, LVS clean, 2×2 seam abutment checked
  (`layout/records/`, T1 7 met / 1 n/a / 3 unmet per
  `manifests/gf180-fpga.signoff.json`).
- The worst setup path at every one of the 15 corners starts at a
  configuration input (`cfg[132]`); the two low-voltage SS corners fail at a
  20 ns clock by ~24–26 ns (`measurements/item5/setup-paths.md`,
  ss_125C_1v62 −25.87 ns SPEF / ss_n40C_1v62 −24.46 ns, 20 violations each),
  pending the operator decision parked on #27. No config-clock rate is
  characterized.
- The only assembly evidence is the seam-local 2×2 abutment check: no routed
  multi-tile array exists, and the recorded route is one seed, one floorplan
  at 63–64% utilization — no utilization sweep.

Extrapolating the *measured* tile to the requested range (method: abut
complete-logic-tile die outlines, N tiles → 4·N LUT4s; die margins overlap
in a real array, so the tile-only footprint is an upper bound):

| LUT4s | Tiles | Tile-only footprint |
|---|---|---|
| 256 | 64 | ≈ 0.86 mm² |
| 512 | 128 | ≈ 1.71 mm² |
| 1024 | 256 | ≈ 3.42 mm² |

The area is therefore plausible for a small standalone part on gf180mcu, but
it is an unverified extrapolation: it assumes routing density at array scale
holds, which nothing yet measures, and it excludes the pads, I/O tiles,
config storage and loading logic a standalone part adds.

## Decision

**A standalone gf180mcu configuration is out of scope for now — deferred,
not rejected.** This repo keeps the ratified scope of ADR-0001 (tile +
demonstration fabric) and does not specify a standalone product, a grid, an
I/O count or package pins. The deferral is not about area: the extrapolation
above says ~1000 LUT4s would fit in ≈ 3.4 mm². It is about evidence — every
input a standalone spec would need to be more than a guess is still unmet:

- The tile is not verified: T1 items 5 (corner verification), 7 (post-layout
  verification) and 8 (characterization report) are unmet, and item 5 waits
  on the #27 operator decision about the failing configuration-input setup
  path — the exact path a standalone part's power-up load would drive.
- The demonstration fabric is not assembled or bitstream-tested at array
  scale; a 2×2 seam check is not routing evidence for a 64–256-tile array.
- The I/O tile, configuration storage and serial load path do not exist;
  specifying them today would ratify numbers with no characterized data
  behind them, which ADR-0001 and `CLAUDE.md` forbid.

**What would warrant reconsideration.** Reopen this decision when (1) item 5
is resolved and T1 items 7 and 8 are met — the `CLAUDE.md` "tile is
verified" condition that unlocks new tile types; (2) the ratified 2×2–4×4
demonstration fabric is routed and passes bitstream-level tests, giving
array-scale routing and config-distribution evidence; and (3) a config-load
path is characterized on gf180mcu. Only then can a standalone record cite
measured per-LUT cost (#143) and characterized timing instead of an upper
bound. This record answers gf180mcu only; the sibling questions
(`sky130-fpga` #325, `sg13g2-fpga` #139) are not answered by it, and no
record is named shared unless cross-linked.

## Alternatives considered

- **In scope now, grid + I/O + package specified**: rejected. It would write
  LUT/I/O/pin counts ahead of the tile's verification, on a single-seed
  route with a failing config-path corner — precisely the relaxation of
  evidence-before-claim the ratified spec exists to prevent.
- **Reject outright**: rejected; the area extrapolation is favourable and
  the missing pieces are all items this repo is already structured to
  produce, so the question is deferred with named conditions, not closed.

## Consequences

- No standalone grid, I/O, configuration-storage or package row is added to
  `spec/target-spec.md`; the ratified fabric size is unchanged.
- Proposals to build a standalone configuration before the reconsideration
  conditions above are met are declined by this record and re-filed as
  issues.
- The per-LUT cost estimate (#143) and the timed blinky (#144) proceed
  independently; neither is gated by this decision.
