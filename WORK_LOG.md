# Work Log

Chronological record of merged PRs and closed issues (maintained by the Guide role; newest first).

### 2026-11-16

- **Issue #105** (closed): Operator: confirm `signoff` is a required status check on main (carried over from #88)

### 2026-11-15

- **PR #131**: layout: stop re-running the lvs-vs-synth compare; keep the record as frozen evidence
- **PR #129**: docs: classify parasitics non-scalars outside the summary-scalars parenthetical
- **PR #127**: test(item9): net the inventory guard's remaining assertions (cases k-r)
- **Issue #126** (closed): Extend the item-9 inventory-guard net to the pre-#107 assertions it does not cover
- **Issue #125** (closed): Extract-record convention: `parasitics.model` is listed among "summary scalars" but is a nested prose object
- **Issue #106** (closed): Remove lvs-vs-synth.json: a known-mismatch LVS record that nothing cites and an extra klt lvs compare
- **Issue #109** (closed): The item-9 inventory guard's perturbation matrix lives only in PR transcripts, not in a committed regression test
- **Issue #84** (closed): measurements/item5 records are bound to the superseded 40 um GDS, and nothing says so
- **Issue #117** (closed): Extract-record convention: two imprecise labels in the keep/drop lists (paths, and hub_net's why-safe reason)
- **Issue #114** (closed): Local vs sibling ADR numbers collide: spec/porting-plan.md and spec/target-spec.md cite "ADR-0002/0003" meaning sky130-fpga's, while spec/decisions/0002 and 0003 are this repo's
- **PR #122**: test(verification): net the item-9 inventory guard with a committed perturbation-matrix regression script
- **PR #124**: docs: qualify parasitics scalars and restate hub_net's drop reason in extract-record convention
- **PR #119**: docs(spec): state the ADR citation convention and qualify sibling citations
- **PR #95**: docs(measurements): disclose that the item 5 STA records pin the pre-#83 stream
- **Issue #103** (closed): Delete the unverifiable cocotb pin from the attested item9-inventory.json and re-attest (after #100)
- **Issue #118** (closed): Remove the inert hi parameter of sig() in layout/make-request.py
- **PR #121**: fix: drop inert hi parameter of sig() in make-request.py
- **PR #116**: docs(measurements): ratify extract-record shape convention for records with a SPEF beside them
- **PR #115**: fix(signoff): drop unverifiable cocotb tools pin from attested item9 inventory
- **PR #113**: docs: supersede flow/README "retirable with no bump" conclusion for the abut-check pin rename
- **Issue #110** (closed): flow/README.md:308-311 still says the abut-check rename is "retirable with no bump at all" — measurement says it is not retirable at all
- **Issue #96** (closed): Stop committing parasitics.nets in extract records: 94% of the repo's largest file duplicates the SPEF beside it
- **PR #108**: docs: correct recorded reason for abut-check pin rename (scoping, not naming)
- **PR #107**: guard(verification): assert the item-9 inventory's copies against their owning files
- **Issue #101** (closed): Retire the abut-check pin-rename workaround: klt interface-check --pair is already in the pinned 0.9.0
- **Issue #100** (closed): item9-inventory.json hand-copies the bench set, cold-start argv and three pins; inventory.py --check verifies none of them

### 2026-11-14

- **PR #104**: ci: drop duplicate item-9 attestation step from verification workflow
- **PR #99**: docs(flow): record which closed klayout-tools fixes ship in klt 0.9.0 and 0.9.2
- **Issue #98** (closed): layout/README.md:229 abbreviates the pre-#83 GDS hash with a wrong tail (d582d634a -> b582d634a)
- **Issue #88** (closed): Remove the duplicate item-9 attestation step from verification.yml: signoff.yml already runs the identical klt check
- **Issue #82** (closed): Probe which closed klayout-tools fixes are present in the pinned klt 0.9.0 and in the latest release
- **PR #85**: fix(flow): resolve $PDK_ROOT in one helper, adopting an already-pinned ciel store
- **PR #87**: docs(item5): add setup-paths.md and its generator, read from the committed STA reports
- **PR #94**: refactor(layout): drop the inert FILLTIE argument, state tapcell master provenance
- **PR #80**: docs: roadmap as of 2026-11-13
- **PR #83**: fix(layout): tapcell pitch 40 -> 24 um clears 46 MV tap-distance violations
- **Issue #79** (closed): flow/setup-pdk.sh: adopt an already-populated ciel PDK store instead of forcing a fresh download
- **Issue #23** (closed): T1 item 3 (DRC clean): klt drc report on the routed gf180mcuD tile with deck coverage disclosed
- **Issue #81** (closed): Record the per-corner worst setup path from the committed item 5 STA reports
- **Issue #91** (closed): Remove the inert FILLTIE parameter of layout/make-request.py (and correct the README claim it backs)
- **Issue #97** (closed): flow/ scripts default PDK_ROOT to flow/.pdk-root, so agents conclude the PDK is absent when it is in the ciel store
- **Issue #55** (closed): DRC: 46 MV tap-distance violations on routed tile (tapcell pitch 40 um)

### 2026-11-12

- **PR #75**: Bump Repo Skills 0.25.10 -> 0.26.1

### 2026-11-07

- **PR #72**: Bump Repo Skills 0.25.1 -> 0.25.10

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
