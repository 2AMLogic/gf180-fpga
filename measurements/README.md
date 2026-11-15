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

## Extract record shape — convention for future records (2026-11-15)

A `klt extract --parasitics --spef` record committed **alongside its SPEF**
keeps the summary and the design-relevant per-net data, and cites the SPEF
for the RC network and coupling capacitances instead of repeating them.
Measured against `origin/main` @ `7c3822b`
(`measurements/item5/extract.report.json`, 369 nets, 12,354 `coupled`
entries = 6,177 distinct coupling pairs): the record is 4,151,181 bytes and
`parasitics.nets` is 93.8% of it — the report without that key is 258,448
bytes. Applying this convention yields a **~650 KB JSON (650,899 bytes
measured) + the ~344 KB SPEF** for a 369-net tile, an 84.3% reduction — not
the ~260 KB of dropping the key outright; the per-net data kept below is
deliberate.

**Kept** (per extract record committed with a SPEF beside it):

- the top-level report outside `parasitics.nets`: the summary scalars
  (`r_count`, `total_resistance_ohm`, `model`, …), the findings lists
  (`warnings`, `dead_metal`, `missing_flavour_markers`), the
  `parasitics.integrity` aggregate, and `provenance` (tool versions).
- per net: its summary scalars (`net`, `net_id`, `resistance_ohm`,
  `capacitance_ff`, `inductance_nh`, `rc_model`, …), `by_layer` (per-layer
  R/C — not expressible in SPEF), and `integrity.capacitance` (varies per
  net).
- a `coupling_by_layer_pair` histogram. The one thing in `coupled` the SPEF
  does not carry is `levels`, the metal-layer pairs each coupling capacitor
  spans (10 distinct values across all 12,354 entries in the measured
  record) — on this repo, per-layer coupling attribution is the routing
  density evidence, so it survives as a global histogram (each pair counted
  once; a pair spanning several level pairs contributes its capacitance
  divided evenly across them):

  ```json
  "coupling_by_layer_pair": {
    "0-1": { "pairs": 1328, "cap_ff": 28.402517 },
    "1-2": { "pairs": 3976, "cap_ff": 23.701433 },
    "2-3": { "pairs": 1744, "cap_ff": 24.208681 },
    "3-4": { "pairs": 53,   "cap_ff": 5.715547 }
  }
  ```

**Dropped** (and why each is safe):

- `coupled[].net` / `coupled[].capacitance_ff` — each of the 6,177 distinct
  pairs is already in the SPEF's two-terminal `*CAP` rows, verified
  bit-for-bit (max absolute difference 0.0 fF over all pairs); the JSON
  records every pair twice, once per side.
- `coupled[].lateral_levels` — `[]` for all 12,354 entries in the measured
  record.
- the five constant per-net `integrity` sub-keys (`open`, `islands`,
  `orphan_nodes`, `suspicious_resistors`, `short_candidates`) —
  byte-identical across all 369 nets because `rc_model == "lumped"` and
  `segments == []` everywhere, so every check renders the same
  `not_applicable` reason; the aggregate already lives in top-level
  `parasitics.integrity` (~300 bytes).
- per-net `terminals` / `segments` / `pin_order` / `hub_net` — empty or
  SPEF-expressible under the lumped model.

**Scope and obligations:**

- Forward-looking only. This does not reverse the append-only rule at the
  top of this file: nothing under `measurements/item5/` is edited, and the
  measured record stays byte-identical.
- A record with **no** SPEF beside it keeps `parasitics.nets` in full — the
  per-net RC network would otherwise have no copy.
- A future `--distributed-rc` record (`segments` non-empty) keeps per-net
  `integrity` in full — the constant-sub-key collapse above no longer holds
  once the model is distributed.
- Applying this to an actual record waits on a klt report-shape flag or a
  documented post-filter; the gap is filed upstream at
  [2AMLogic/klayout-tools#5816](https://github.com/2AMLogic/klayout-tools/issues/5816).
  Until one of those lands, the next extract run knows the obligation exists
  and commits the full-shape record.
