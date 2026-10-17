# gf180-fpga

A small open-bitstream eFPGA tile on the
[gf180mcu](https://github.com/google/gf180mcu-pdk) open PDK — one LUT4-class
logic tile and a small demonstration fabric — designed by AI agents driving
[klayout-tools](https://github.com/2AMLogic/klayout-tools), the
[FABulous](https://github.com/FPGA-Research-Manchester/FABulous) fabric
description format, and the open-source cocotb + Icarus, Yosys, nextpnr and
OpenROAD flow.

**Status: just opened, specification phase.** Nothing is designed in this
repo yet.

**Built agent-native.** Every specification, decision record, testbench, and
line of documentation here is produced by AI agents working from a ratified
spec and an append-only evidence trail — not human-authored work that agents
merely assisted with. Verification is the product: every claim traces to a
recorded result. Where the agents hit friction with the open-source tooling —
most often [klayout-tools](https://github.com/2AMLogic/klayout-tools) — that
friction is filed as a public issue against the tool itself, so the fix
benefits everyone using gf180mcu, not just this repo.

## Why this block, on this PDK

This is a **port, not a new design.** [sky130-fpga](https://github.com/2AMLogic/sky130-fpga)
carries the same tile on sky130: a ratified tile spec (4× LUT4, one output
flip-flop per LUT, no carry chain in v1, a FABulous-style switch matrix with
4 general-purpose tracks per edge, a 2×2 to 4×4 single-tile-type
demonstration fabric, an open bitstream), its framework choice, and a
physical-design and timing-characterization path. The architecture is the
constant; **the PDK is the variable.**

What changes on gf180mcu is everything physical:

- **A different standard-cell library and metal stack.** The tile is placed
  and routed with the gf180mcu standard cells, at a coarser routing pitch
  than sky130, on whichever of the PDK's metal-stack options the spec
  chooses. A switch matrix is the
  most routing-dense structure on a die, so the tile's area, its routing
  congestion and whether it closes at all are the central question.
- **Timing is re-earned.** No sky130 timing number transfers. Every timing
  claim here comes from characterized gf180mcu data at its own corners.
- **Larger devices, longer wires.** At 180 nm the balance between cell
  delay and wire delay in the switch matrix differs from 130 nm, which is
  exactly what a port is meant to expose.

## Target specification (DRAFT — engineering to ratify, see issue #2)

Port parity: the architectural rows are `sky130-fpga`'s ratified tile spec,
unchanged. The physical and timing rows are re-derived here.

| Parameter | Fallback | Target | Stretch |
|---|---|---|---|
| Logic tile | 4× LUT4 + 1 FF per LUT, no carry (inherited) | same | carry chain as a later tile revision |
| Routing | 4 tracks/edge, FABulous-style switch matrix (inherited) | same | — |
| Demonstration fabric | 2×2 tiles | 2×2 to 4×4, single tile type | — |
| Bitstream | open, documented, FABulous-generated (inherited) | same | — |
| Tile physical design | DRC/LVS clean on the chosen metal stack | DRC/LVS clean, routed without congestion overrides | on the smallest available metal stack |
| Timing | setup/hold-clean at all library corners at a relaxed clock | setup/hold-clean at all library corners, Fmax reported from characterized data | SDF-annotated gate-level re-simulation |

Maturity ladder: framework and port plan → tile spec ratified → tile RTL
and fabric description passing bitstream-level tests → tile layout
DRC/LVS-clean → tile timing characterized → demonstration fabric assembled
and re-verified → shuttle seat → measured silicon.
**Current position: pre-spec.**

## Tool flow

- **Fabric description**: FABulous tile/fabric format, as in `sky130-fpga`.
- **Verification**: cocotb + Icarus, bitstream-level tests on the simulated
  fabric.
- **Synthesis and mapping**: Yosys; nextpnr for mapping user designs onto
  the fabric.
- **Physical design**: OpenROAD place-and-route; layout, DRC, LVS and STA
  through klayout-tools (`klt`).

## Repo layout

```
spec/          ratified spec + decision records + porting plan
rtl/           tile RTL + fabric description (shared material under rtl/common/)
verification/  cocotb bitstream-level testbenches + results
layout/        tile GDS, routed DEF, DRC/LVS reports (klayout-tools driven)
measurements/  silicon characterization (empty until tape-out)
```

## License

Apache License 2.0 — see [LICENSE](LICENSE).
