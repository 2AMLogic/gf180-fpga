# measurements

Append-only characterization records. Nothing here is edited after the fact;
a re-run lands as a new record.

## item5/ — T1 item 5 (issue #27)

Routed tile `layout/logic_tile_routed.def`, library `gf180mcu_fd_sc_mcu7t5v0`,
variant `gf180mcuD`, all 15 shipped corners. Tools: klt 0.9.1.dev112,
OpenROAD `26Q3-1510-g6cb3f2b704`. Period **20 ns** on `clk` (spec row 5
fallback), I/O delays 0, ideal clock; pre-registered in a comment on #27
before the first run and not changed.

| File | What |
| --- | --- |
| `item5/sta-lef-only.{request,report}.json` | `klt sta`, one request, no parasitics |
| `item5/extract.report.json`, `item5/logic_tile_routed.spef` | `klt extract --parasitics --spef` from the routed GDS (`--def-net-names --def-net-connections`) |
| `item5/sta-spef.{request,report}.json` | `klt sta` with that SPEF |
| `item5/functional-item9.result.json` | per-bench pass/fail of the stamped plain-Verilog benches (`verification/runner.py --vvp verification/item9/benches.json`) |

Run `klt sta` from the repo root: repo-scoped paths in the request resolve
against the working directory.

### Result (as found)

**Item 5 is not met.** Setup fails at two corners; the other 13 are clean.

- LEF-only: 15/15 `constrained`; hold slack >= 0.031 ns everywhere; setup
  violated at `ss_125C_1v62` (WNS -25.41 ns, 20 endpoints) and `ss_n40C_1v62`
  (WNS -24.08 ns, 20 endpoints). Tightest passing corner: `tt_025C_1v80`
  (+2.36 ns).
- SPEF-annotated: same picture. `ss_125C_1v62` -25.87 ns, `ss_n40C_1v62`
  -24.46 ns, `tt_025C_1v80` +2.14 ns; hold slack >= 0.040 ns.
- The 1.8 V-flavour ss corners are the supply-corner low end (1.62 V). The
  period was not relaxed or re-tuned after seeing this; a spec or period
  change needs a decision record.
- **The SPEF annotation is partial: 333 of 369 nets.** The 36 unannotated
  nets are slice-internal hierarchical nets (e.g. `g_slice[0].u_slice/_00_`);
  the reader warns that the SPEF's flattened names are not found
  (918 reader warnings, see `spef_annotation` in the report). The SPEF run is
  therefore a lower bound on parasitic impact, not a full post-route claim.
- **Functional:** the 23 stamped bench runs pass (0 failures, negative control
  fails as required). `klt functional-verification` takes only a cocotb
  testbench, so it was not used; the plain-Verilog runner's result is cited
  instead. This is a tool-capability gap, not a substitute for the cocotb
  report the item text names.
