# gf180-fpga — agent instructions

Open-source canary block: a small open-bitstream eFPGA tile on the gf180mcu
PDK, tile-scoped, designed and verified by AI agents. A port of
`sky130-fpga`. **Digital.**

- **PDK**: gf180mcu (open PDK). Digital: cocotb + Icarus, Yosys, OpenROAD,
  with a FABulous-style tile/fabric description and nextpnr for mapping
  user designs onto the fabric. Layout, DRC, LVS and STA through
  klayout-tools (`klt`). A dense, regular logic tile is exactly the
  workout `klt` place-and-route exists to be stressed by — expect and
  welcome friction there.
- **Routing density on gf180mcu is the risk.** The switch matrix is the
  most routing-dense structure there is, and gf180mcu routes at a coarser
  pitch than the sky130 tile was built on, with a layer count set by the
  metal-stack option chosen. Whether the inherited
  tile closes at all, at what area, and on which metal-stack option, is the
  question this repo exists to answer. Report congestion and area honestly;
  do not quietly shrink the tile to make it route — that is a spec change.
- **The tile is the scope, not the FPGA.** One LUT4-class tile plus a 2×2
  to 4×4 demonstration fabric. Decline proposals to grow the fabric, add
  tile types or widen the routing before the tile is verified; record the
  proposal in an issue and move on.
- **Scope discipline: designed once.** `sky130-fpga` is the master by
  lineage. Its architecture (tile spec, framework choice, decision records)
  is inherited and cited, not re-argued. Its PDK-independent material —
  tile RTL, the FABulous tile/fabric description, bitstream-level test
  logic — is taken as stamped copies under `rtl/common/` (and the matching
  test directory) via `reuse.lock.json` at a pushed commit, never
  re-written. A vendored file diverges only with a decision record. What is
  re-derived here is device-level and physical: placement, routing, DRC/LVS
  and timing. Findings that bear on the master (a description defect, a
  test gap) are filed on `sky130-fpga`.
- **Friction protocol (the canary's job)**: every time klayout-tools is
  awkward, missing a capability, or wrong for what you need, file an issue at
  `2AMLogic/klayout-tools` describing the tool gap generically — that tracker
  is scoped to the tool, so keep design-specific detail out of it and describe
  the gap, not the design.
- **Verification is the product**: no claim without a testbench.
  Functional claims come from bitstream-level tests on the simulated
  fabric. Timing claims come only from characterized gf180mcu data — no
  number inherited from sky130 or from FABulous's placeholder BEL timing.
  Recorded results are append-only evidence.
- Spec changes go through `spec/` with a decision record; agents do not relax
  the ratified spec to make results pass.
