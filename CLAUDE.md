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

<!-- BEGIN LOOM ORCHESTRATION -->
This repository uses [Loom](https://github.com/rjwalters/loom) for AI-powered development orchestration — see the Loom repository for the full guide (roles, labels, worktrees, configuration). When installed, Loom also writes a locally-substituted copy of that guide to `.loom/CLAUDE.md`.

Work is coordinated through `loom:` labels on issues and pull requests, and the same roles run either under `loom-daemon` or by hand in an attended session — daemon mode is optional. Create the labels once with `.loom/scripts/sync-labels.sh` (an install ships `.github/labels.yml` but does not create the labels on the forge). A pull request ready for review carries `loom:review-requested`; Judge reviews it and applies `loom:pr` (approved) or `loom:changes-requested`; Doctor fixes a `loom:changes-requested` pull request and returns it to `loom:review-requested`. Only a `loom:pr` pull request gets merged, and always via this repo's merge script (`.loom/scripts/merge-pr.sh`) — never a raw forge merge command such as `gh pr merge`. Full state machine: `.loom/docs/label-state-machine.md`.
<!-- END LOOM ORCHESTRATION -->

<!-- BEGIN REPO-SKILLS -->
This repository has [Repo Skills](https://github.com/rjwalters/repo) v0.24.3 installed —
general repository hygiene and environment commands invoked as `/repo:<command>`. Run
`/repo:help` for the command list, or see `.claude/skills/repo/SKILL.md` for the full
guide. Hygiene commands apply safe, reversible fixes by default and report each
change; run with `--ask` to review first, and `--prune` to allow irreversible
removals. Managed by `install.sh` — edit outside the markers only.
<!-- END REPO-SKILLS -->
