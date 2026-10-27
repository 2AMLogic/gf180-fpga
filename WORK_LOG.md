# Work Log

Chronological record of merged PRs and closed issues (maintained by the Guide role; newest first).

### 2026-10-27

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
