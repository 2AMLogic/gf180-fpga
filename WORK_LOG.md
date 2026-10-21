# Work Log

Chronological record of merged PRs and closed issues (maintained by the Guide role; newest first).

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
