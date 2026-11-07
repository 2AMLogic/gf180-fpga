# Work Log

Chronological record of merged PRs and closed issues (maintained by the Guide role; newest first).

### 2026-11-06

- **PR #70**: fix: fail fast in run-signoff write mode when the PDK is absent
- **PR #68**: fix: carry over item 2 claim in run-signoff write mode and correct README status
- **Issue #69** (closed): run-signoff.sh write mode: item 1 attestation needs the PDK (flow/tile/run-synth.sh --check)
- **Issue #67** (closed): Let run-signoff.sh write on hosts without the PDK, then correct the stale README status
- **PR #61**: refactor(flow): single-source the klayout-tools pin in flow/pdk.json
- **Issue #58** (closed): Single-source the klayout-tools pin: three places hardcode 0.9.0, three scripts use unpinned host klt

### 2026-11-05

- **PR #60**: feat(measurements): record item 5 STA at 15 corners; setup fails at two ss corners
- **PR #57**: feat(signoff): supply ERC of the routed tile, cited as T1 item 11
- **PR #56**: feat(drc): commit tile DRC report (46 MV tap-distance violations, item 3 unmet)
- **PR #54**: feat(signoff): gate-level LVS of the routed tile, cited as T1 item 4
- **PR #52**: feat(signoff): attest T1 item 2 from routed GDS, bump klt pin to 0.9.0
- **Issue #30** (closed): T1 item 11 (power delivery): klt erc supply spec for the routed tile, PDN evidence and power_connectivity match
- **Issue #24** (closed): T1 item 4 (LVS clean): klt lvs of the routed tile against its gate-level netlist with power_connectivity graded
- **Issue #22** (closed): T1 item 2 (layout): routed logic_tile_routed GDS on gf180mcuD via the routing-closure ladder, with 2x2 abutment check

### 2026-11-02

- **PR #49**: feat: route logic_tile_routed on gf180mcu 7-track with committed records and stream
- **PR #48**: feat: cite T1 item 1 attestation in manifest and signoff record
- **Issue #21** (closed): T1 item 1 (design sources): synthesized gf180mcu_fd_sc_mcu7t5v0 gate-level netlist of logic_tile_routed with item-1 attestation

### 2026-11-01

- **PR #46**: Bump Repo Skills 0.24.7 -> 0.25.1

### 2026-10-28

- **PR #43**: build: pin klayout-tools to the 0.8.0 release and re-attest signoff

### 2026-10-27

- **Issue #42** (closed): Bump klayout-tools pin fc02bdf0b6aa → 0.8.0
- **PR #40**: feat(signoff): cite item 9 testbench attestation from the block manifest
- **PR #39**: feat(signoff): cite T1 item 6 as not_applicable in the block manifest
- **Issue #34** (closed): Cite the item-9 attestation envelope from the #5 manifest once PR #10 merges
- **Issue #26** (closed): T1 item 6 (Monte Carlo): record that no ratified gf180-fpga spec row is statistical
- **PR #10**: feat: grade T1 state with klt signoff and gate the verdict record in CI
- **Issue #5** (closed): Signoff scaffolding: block manifest, committed klt signoff record, and CI (T1 item 10)
- **PR #36**: fix(verification): reject negative controls that fail to compile
- **PR #33**: feat: run stamped plain-Verilog benches from a cold start and attest item 9
- **PR #32**: feat(flow): synthesized gf180mcu 7t tile netlist and T1 item-1 attestation
- **PR #31**: feat(manifests): add ratified spec row list and item 6 not-applicable statement
- **Issue #25** (closed): T1 item 9 (testbenches shipped): wire the stamped bitstream-level testbenches into the runner and CI, then attest item 9
- **Issue #35** (closed): Follow-on from PR #33: negative control should not pass on a compile error

### 2026-10-21

- **PR #17**: Bump Repo Skills 0.24.3 -> 0.24.7

### 2026-10-20

- **PR #14**: ci: run reuse-lock vendored-file guard with a negative control
- **PR #12**: fix: wire package.json check/test/lint scripts to the verification harness
- **Issue #13** (closed): Wire spec/check_reuse_lock.py into CI: ADR-0002 names it the vendored-file guard but nothing runs it
- **Issue #11** (closed): Wire or remove no-op package.json check/test/lint scripts (always-green gate)

### 2026-10-17

- **PR #8**: docs: ratify gf180mcu target spec and vendor sky130-fpga tile material
- **PR #9**: feat: pin gf180mcu PDK and add klt flow smoke for both std-cell libraries
- **PR #7**: feat(verification): add cocotb+Icarus harness, smoke negative control, RTL lint and CI
- **PR #1**: chore(loom): Install Loom 0.19.1181
- **Issue #2** (closed): Draft and ratify the target spec
- **Issue #3** (closed): Pin the gf180mcu PDK and prove the digital flow runs on both standard-cell libraries
- **Issue #4** (closed): Testbench harness and RTL lint skeleton: cocotb + Icarus runner, negative control, CI (T1 item 9)
