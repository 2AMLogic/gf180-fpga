# measurements

Append-only characterization records. Nothing here is edited after the fact;
a re-run lands as a new record.

## item5/ — T1 item 5 (issue #27)

Routed tile `layout/logic_tile_routed.def`, library `gf180mcu_fd_sc_mcu7t5v0`,
variant `gf180mcuD`, all 15 shipped corners. Tools: klt 0.9.1.dev112,
OpenROAD `26Q3-1510-g6cb3f2b704`. Period **20 ns** on `clk` (spec row 5
fallback), I/O delays 0, ideal clock; pre-registered in a comment on #27
before the first run and not changed. **The routed stream these records were
measured on is no longer the committed one** — read "Superseded binding"
below before attributing any number here to the tile now in `layout/`.

| File | What |
| --- | --- |
| `item5/sta-lef-only.{request,report}.json` | `klt sta`, one request, no parasitics |
| `item5/extract.report.json`, `item5/logic_tile_routed.spef` | `klt extract --parasitics --spef` from the routed GDS (`--def-net-names --def-net-connections`) |
| `item5/sta-spef.{request,report}.json` | `klt sta` with that SPEF |
| `item5/functional-item9.result.json` | per-bench pass/fail of the stamped plain-Verilog benches (`verification/runner.py --vvp verification/item9/benches.json`) |

Run `klt sta` from the repo root: repo-scoped paths in the request resolve
against the working directory.

### Superseded binding: these records are bound to the pre-#83 stream (noted 2026-11-14)

**The stream these item 5 timing records were measured on is no longer the
committed one.** They were recorded on 2026-11-05 against the 40 µm
tapcell-pitch layout; PR #83 (issue #55, `432f919`, 2026-11-14) replaced both
the routed GDS and the routed DEF with the 24 µm-pitch stream. The records are
kept exactly as recorded — evidence here is append-only — but their per-corner
numbers must **not** be attributed to the tile now in `layout/`.

The binding is two distinct pins across three files:

| Pin (`provenance.input.content_hash`, role `layout`) | Measured against | Now committed |
| --- | --- | --- |
| `item5/extract.report.json` — the **GDS** | `sha256:d71889f0…b582d634a` | `ecf5be0a…2f56b662` (`layout/logic_tile_routed.gds`) |
| `item5/sta-lef-only.report.json` **and** `item5/sta-spef.report.json` — the **DEF** | `sha256:460a41c9…52a07620` | `0b8fa71b…529a388c` (`layout/logic_tile_routed.def`) |

The two STA reports are pinned to the superseded DEF **independently**; they are
not stale merely by inheritance from the SPEF. `item5/logic_tile_routed.spef`
carries no `provenance` block of its own and is bound only through
`item5/extract.report.json`, which produced it.

**Superseded (stream-bound), these four and only these four:**
`item5/extract.report.json`, `item5/logic_tile_routed.spef`,
`item5/sta-lef-only.report.json`, `item5/sta-spef.report.json`.

**Not superseded: `item5/functional-item9.result.json`.** Its `provenance` is
`null` — it carries no layout pin at all — and it is an RTL run: 23 bench runs
over `verification/common/tb_*.v` at `commit 3d3345d5…`, Icarus 13.0 /
Verilator 5.050. T1 item 9 grades **met** cited to a different file
(`verification/signoff/item9-testbenches.json`), so nothing in this
supersession bears on it. The same exclusion applies to any other record under
`item5/` whose `provenance.input` is `null`: it is an RTL run, not a
measurement of the stream.

**No T1 claim rests on the superseded records, and no gate noticed the drift.**
`manifests/gf180-fpga.signoff.json` grades item 5 `unmet` with `citation: null`
and `detail.failed_citations` = the two `item5` STA reports; `t1_met_count` is 7
(items 1, 2, 3, 4, 9, 10, 11). Item 5 is `unmet` against either stream, so this
disclosure moves no grade. Nothing detected the change because **the gate pins
these measurement files' own bytes, not the layout stream they were measured
against.** `manifests/gf180-fpga.json` cites and byte-pins exactly two files
under `measurements/` — `evidence["5"]` is `item5/sta-lef-only.report.json`
(`sha256:b707b647…fe48de2`) and `item5/sta-spef.report.json`
(`sha256:8fc10711…23848d3`) — and CI's `signoff` job, via
`manifests/run-signoff.sh --check`, re-renders `klt signoff --manifest` (which
grades item 5 from those two reports) and `cmp`s the result against the
committed `manifests/gf180-fpga.signoff.json`. Editing either report's bytes
therefore **does** fail that job. What nothing checks is the other direction: no
gate compares those reports' own `provenance.input.content_hash` against the
live `layout/` stream, so replacing the stream left every pinned hash intact and
the gate silent. Everything else under `measurements/` sits outside that gate:
the SPEF, `item5/extract.report.json` and this README are cited by no manifest
entry. `item5/summarize_sta.py --check` does regenerate-and-compare
`item5/setup-paths.md` against the two committed reports, but nothing in CI
invokes it, and it too reads only the reports — never the stream they were
measured on. A re-run
against `ecf5be0a…` belongs to issue #27, which owns item 5, and would land as
a new record rather than an edit to these.

### Why these numbers and `layout/records/step0-par.json` disagree (leading hypothesis, not measured)

At the same 20 ns period, OpenROAD's in-flow STA in
`layout/records/step0-par.json` (`interconnect_corner: nom`) reports every one
of its 15 corners `constrained` with `total_negative_setup_slack_ns` and
`total_negative_hold_slack_ns` both 0 — worst setup slack **+3.08 ns**, at
`ss_125C_1v62` — while the `klt sta` run below reports **-25.41 ns** WNS over
20 endpoints at that same corner: a gap of roughly 28 ns. (That comparison
crosses streams, per the supersession above: `432f919` rewrote
`step0-par.json` too, so the committed **+3.08 ns** is the post-#83 24 µm
stream's in-flow run while the `klt sta` figure is the pre-#83 40 µm stream's.
Same-stream, pre-#83 `step0-par.json` reports **+3.28 ns** at the same
`ss_125C_1v62` corner, also with TNS 0 across all 15 — a gap of ~28.7 ns rather
than ~28.5 ns, so the disagreement this subsection explains is the same order
either way.)
`layout/README.md` already disclaims the first ("a tool figure, not the timing
claim"). The leading explanation is a **constraint-set difference**, not the
liberty flavour:

- Every path that bounds a `klt sta` corner is a path to an output **port**. All
  30 worst setup paths (15 corners × 2 runs) are `check_type: output_setup` from
  startpoint `cfg[132]` to `n_out[0]` (all 15 LEF-only) / `w_out[0]` (all 15
  SPEF), the two failing corners included.
- `item5/sta-{lef-only,spef}.request.json` set `input_delay_ns: 0` **and**
  `output_delay_ns: 0`, so `klt sta` times those output ports as real
  endpoints: per-corner `constraint_completeness` is `status: "complete"` with
  `unconstrained_endpoints.count` 0 in all 15 corners of both runs.
- `layout/par.json` `constraints` is `{clock_port: "clk", clock_period_ns:
  20.0}` and **nothing else** — no input- or output-delay key.

So the in-flow run was most likely never given the output-delay constraint that
creates the `output_setup` checks bounding every `klt sta` corner, which would
make its `+3.08 ns` **optimistic rather than contradictory**.

**This is inferred from the committed records, not traced through either tool,
and it is not a timing claim.** It cannot be closed out from what is committed:
the per-corner entries in `layout/records/step0-par.json` carry only aggregate
fields (`setup_slack_ns`, `hold_slack_ns`, `total_negative_*`, and
transition/capacitance violation counts) — no endpoint and no `check_type` —
so there is nothing to diff against the `klt sta` paths without a re-run. The
decisive test is re-running one corner with the two constraint sets swapped and
seeing whether the `output_setup` violations move; recording a result that
refutes this hypothesis is as complete an outcome as one that confirms it.
Either way the `klt sta` result stands as recorded: item 5 is `unmet`.

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
