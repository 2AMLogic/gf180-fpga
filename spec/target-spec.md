# Target spec: gf180mcu LUT4-class tile + demonstration fabric

- **Status**: Ratified by `spec/decisions/0001-ratify-target-spec.md` (issue #2).
- **Date**: 2026-10-17
- **Architecture**: inherited from `2AMLogic/sky130-fpga` @
  `42a8db00e138aa892a388b077a8ae2ea2ccab511`; see `spec/porting-plan.md`.
- **PDK pin read**: open_pdks `f6eeac7dad085ffcc829ccfd721f7b4ce39edcf7`
  (the `gf180mcuA`–`D` installs under the ciel root on the authoring host).
  Library, corner and layer facts below were read from that install; #3 owns
  the PDK pin itself and its smoke runs.

No number in this spec comes from sky130 or from FABulous's placeholder BEL
timing. Where a value can only come from a run that has not happened, the row
says so and names the run; it does not guess.

## Architectural rows (inherited, unchanged)

| Parameter | Fallback | Target | Stretch |
|---|---|---|---|
| Logic tile | 4× LUT4 + 1 output FF per LUT, no carry | same | carry chain as a later tile revision (a spec change) |
| Routing | 4 general-purpose tracks/edge, FABulous-style switch matrix | same | — |
| Bitstream | open, documented, FABulous-generated | same | — |

## Parameters

Each row: target / fallback / stretch / binding condition / evidence plan.

### 1. Standard-cell library and track height

| | |
|---|---|
| Target | `gf180mcu_fd_sc_mcu7t5v0` (7-track; site `GF018hv5v_mcu_sc7`, 0.56 × 3.92 µm) |
| Fallback | `gf180mcu_fd_sc_mcu9t5v0` (9-track; site `GF018hv5v_green_sc9`, 0.56 × 5.04 µm) |
| Stretch | none |
| Binding condition | The library is chosen once per tile and must be used for every cell in the tile; switching to the fallback is allowed only when the 7-track tile fails the routing-closure ladder below, and is recorded with the measured congestion that forced it. |
| Evidence | #3 proves the flow runs on both libraries; the tile place-and-route record reports area, utilization and congestion on the target library, and on the fallback if the ladder reaches it. |

### 2. Supply flavour

| | |
|---|---|
| Target | 5.0 V flavour of the library (nominal corner `tt_025C_5v00`; `ss_*_4v50` and `ff_*_5v50` bound it) |
| Fallback | 3.3 V flavour (nominal `tt_025C_3v30`; `ss_*_3v00`, `ff_*_3v60`) |
| Stretch | none |
| Binding condition | Both libraries use 5 V-rated devices (`nfet_05v0`/`pfet_05v0`, from `klt pdk cells`) and ship liberty at three supply flavours (1.8 V, 3.3 V, 5.0 V nominal). The flavour selects the *nominal* corner; the timing claim in row 5 is made at **all** shipped corners regardless, so a flavour change does not shrink the claim. |
| Evidence | Liberty files named in "Corners"; supply recorded in each timing record. |

### 3. Metal-stack option and switch-matrix routing layers

Verified from the PDK's `nom` tech LEF (`gf180mcu*/libs.ref/gf180mcu_fd_sc_mcu7t5v0/techlef`):

| Variant | Routing metals | Pitch (µm), M1…top |
|---|---|---|
| `gf180mcuA` | 3 | 0.56, 0.56, **4.000** (M3 is the coarse top metal) |
| `gf180mcuB` | 4 | 0.56, 0.56, 0.56, **0.9** |
| `gf180mcuC` | 5 | 0.56, 0.56, 0.56, 0.56, **0.9** |
| `gf180mcuD` | 5 | 0.56, 0.56, 0.56, 0.56, **0.9** |

C and D carry identical LEF pitches and widths; any difference between them
(for example top-metal thickness) is not visible in the LEF and was **not
verified here**.

| | |
|---|---|
| Target | `gf180mcuD` (5 metals). Switch-matrix signal routing may use **Metal2–Metal4** (all 0.56 µm pitch); Metal1 is reserved for in-cell wiring and rails; Metal5 (0.9 µm) is reserved for power distribution and global/clock/config distribution. |
| Fallback | same stack, Metal5 also allowed for switch-matrix signals. |
| Stretch | a 4-metal stack (`gf180mcuB`), i.e. the smallest stack that still closes. Only claimed if a run closes on it. |
| Binding condition | The stack is fixed per tile; the layer budget above is part of the claim. `gf180mcuA` is out of range: it has only two fine-pitch layers. Moving the target to a stack with fewer fine layers is a spec change. |
| Evidence | Routed tile on the stack, with per-layer utilization and the physical switch-matrix pitch recorded in the layout record (sibling gap G3, item a). |

The physical pitch of the switch matrix is **not** ratified as a µm value
here: the stack's pitches above are the inputs, and the achieved pitch is a
measured result of the placement and routing run.

### Routing-closure fallback ladder (open question 2)

Whether the inherited 4-track switch matrix routes on this stack **cannot be
decided by a spec**. It is deferred to the first routed-tile run, with this
pre-named ladder. Each step is taken only after the previous one fails, and
each is recorded with measured congestion; the first three are recorded results
and do not change the spec, the last is a spec change that needs its own
decision record:

1. Lower floorplan utilization (larger tile area, same cell set). Area is
   reported as measured.
2. Allow Metal5 for switch-matrix signals (row 3 fallback).
3. Use the 9-track library (row 1 fallback).
4. **Spec change, never quiet**: reduce tracks per edge, depopulate the
   switch matrix, or drop to a different tile. Not available to agents without
   a decision record.

The experiment: run `klt` place-and-route on the vendored `logic_tile_routed`
at the target library/stack, report overflow/DRC and per-layer utilization,
step down the ladder on failure.

### 4. Tile area budget and aspect ratio

| | |
|---|---|
| Target | A rectangle that abuts in a grid (edge pins on matching positions on opposite edges) with aspect ratio between 1:2 and 2:1; area reported as measured, with utilization and congestion. |
| Fallback | same rectangle at a lower utilization (ladder step 1). |
| Stretch | none |
| Binding condition | **No µm² ceiling is ratified.** A ceiling set before a routed tile exists would be a guess, and a ceiling chosen afterwards to fit the result would be quiet relaxation. The measured area of the first closing tile is recorded as the figure of record in its own record; a ceiling for later revisions needs a decision record that cites it. The tile may not be reduced below the cell set of the vendored RTL to improve area. |
| Evidence | Tile layout record: die/core area, utilization, aspect ratio, abutment check on a 2×2 assembly. |

### 5. Timing

| | |
|---|---|
| Claim shape (inherited from ADR-0002/0003, numbers not) | Setup- and hold-clean (0 violations, 0 TNS) at every shipped liberty corner of the chosen library, both without parasitics (LEF-only) and with parasitics extracted from the routed tile, against a stated clock period on `clk`. |
| Fallback | a relaxed period of **20 ns** (a chosen reference, not a sky130 result). |
| Target | a period pre-registered in the characterization issue *before* the run, no looser than the fallback. The period is not tuned after seeing results. |
| Stretch | an Fmax figure, ratified only if bisected from characterized gf180mcu data. |
| Binding condition | The claim covers the tile BEL logic that the run actually timed; switch-matrix timing is claimed only if the routed composed tile is what was timed. No Fmax or MHz number is ratified here. |
| Evidence | `klt sta` over the routed DEF with the extracted SPEF at every corner in "Corners"; records under `measurements/` are append-only and name the klt version and engine. |

### 6. Corners

See "Corners" below. The claim in row 5 is made at all of them.

### 7. Demonstration fabric size

| | |
|---|---|
| Fallback | 2×2 |
| Target | 2×2 to 4×4 of the one tile type (2×2 required; larger only by assembling the same verified tile) |
| Stretch | none; nothing beyond 4×4 and no second tile type (scope rule) |
| Binding condition | The fabric is assembled only from a DRC/LVS-clean, timing-characterized tile. |
| Evidence | Assembled-fabric layout and bitstream-level tests on the assembly. |

### 8. Signoff

| | |
|---|---|
| Fallback | DRC and LVS clean on the tile on the chosen stack. |
| Target | DRC and LVS clean on the tile **and** on the assembled fabric, routed without congestion overrides; ERC and antenna reported. |
| Stretch | SDF-annotated gate-level re-simulation of the routed tile. |
| Binding condition | Cleanliness is the result of `klt` DRC/LVS on the final GDS with the gf180mcu decks of #3's PDK pin; waivers are not part of "clean". |
| Evidence | Committed `klt` signoff records (#5). |

## Corners

The chosen library's shipped liberty set, **15 corners per library**, from
`gf180mcuD/libs.ref/<lib>/lib/<lib>__<corner>.lib` at open_pdks
`f6eeac7…` (`<lib>` = `gf180mcu_fd_sc_mcu7t5v0`; the 9-track library ships the
identical 15 names):

| Process | Temp | 1.8 V flavour | 3.3 V flavour | 5.0 V flavour |
|---|---|---|---|---|
| ff | 125 °C | `ff_125C_1v98` | `ff_125C_3v60` | `ff_125C_5v50` |
| ff | −40 °C | `ff_n40C_1v98` | `ff_n40C_3v60` | `ff_n40C_5v50` |
| ss | 125 °C | `ss_125C_1v62` | `ss_125C_3v00` | `ss_125C_4v50` |
| ss | −40 °C | `ss_n40C_1v62` | `ss_n40C_3v00` | `ss_n40C_4v50` |
| tt | 25 °C | `tt_025C_1v80` | `tt_025C_3v30` | `tt_025C_5v00` |

Files are named `gf180mcu_fd_sc_mcu7t5v0__<corner>.lib`. There are no
`ccsnoise` variants in this PDK.

### What `klt sta` can and cannot run (probe, 2026-10-17)

Single local request per library, scratch directory outside the repo, `klt
0.7.1.dev1757+ge7cca478ef21`, OpenROAD `26Q3-1510-g6cb3f2b704`,
`PDK_ROOT=<ciel root>`, variant `gf180mcuD`. The design was a two-cell toy
(`inv_1` into `dffq_1`), `verilog` mode (`geometry_source: netlist_estimate`),
20 ns clock, I/O delays 0, `pdk.corners` listing all 15.

| Capability | Result |
|---|---|
| Load all 15 liberty corners of `mcu7t5v0` in one request | **ran**, `status: ok`, 15/15 `timing_status: constrained` |
| Same for `mcu9t5v0` | **ran**, 15/15 constrained |
| Corner resolution via `find_pdk()` for the gf180mcu variants | **ran** (`klt pdk list/cells/corners`) |
| STA on a routed DEF with extracted SPEF, any corner | **not run**: needs a routed tile; later issue |
| LEF-only STA of a routed DEF | **not run**: same |
| Propagated-clock / post-CTS timing | **not run** |
| SDF generation / gate-level SDF re-simulation | **not run** |

Slack values from the toy are not data about the tile (its hold slacks reflect
zero I/O delay on an ideal clock) and are not recorded as results. Without
`input_delay_ns`/`output_delay_ns` the same request reported every corner as
`unconstrained` with `status: ok`; the documented `timing_status` field makes
this visible, so it was not filed as a tool gap. No klayout-tools gap was
found while scoping.

## Maturity ladder position

Framework and port plan → **target spec ratified (this document)** → tile RTL
and fabric description passing bitstream-level tests in this repo → tile
layout DRC/LVS-clean → tile timing characterized → fabric assembled and
re-verified → shuttle seat → measured silicon. Nothing past the spec is
claimed.
