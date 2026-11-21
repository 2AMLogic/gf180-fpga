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

**Superseded (stream-bound):** `item5/extract.report.json`,
`item5/logic_tile_routed.spef`, `item5/setup-paths.md`,
`item5/sta-lef-only.request.json`, `item5/sta-lef-only.report.json`,
`item5/sta-spef.request.json`, `item5/sta-spef.report.json`. Three of the
seven carry the pins in the table above; the other four carry no stream pin of
their own and are bound transitively or by path — `item5/logic_tile_routed.spef`
through `item5/extract.report.json`, which produced it; `item5/setup-paths.md`
through the two STA reports it transcribes row for row (it landed on `item5/`
after these records were written — PR #87, 2026-11-14 — and its `## Provenance`
pins those reports by bytes while carrying no supersession disclosure of its
own; `item5/summarize_sta.py` regenerates it from them, see below); and the two
request records through the reports they produced, each of which also names
the superseded stream directly by path — both set `"def":
"../../layout/logic_tile_routed.def"`, which resolves today to the committed
24 µm DEF the runs never measured, and the SPEF request also names
`"spef": "logic_tile_routed.spef"`. This is a
positive list, not a census: what puts a file under this disclosure is the
binding stated above — it measures the pinned stream, or is derived from a
record that did — not its presence in this list. `item5/` keeps growing (PR #87
added two files mid-review, and #90 will index both in the file table above),
so no here-and-now count claims to be complete.

**Not superseded: `item5/functional-item9.result.json`.** It carries no
`provenance` block at all — the string occurs nowhere in the file, so it has no
layout pin — and it is an RTL run: 23 bench runs, 22 of them over
`verification/common/tb_*.v` and the remaining one
`rtl/common/fabulous/tb_lut4_ff_bel_equiv.v`, at `commit 3d3345d5…`, Icarus
13.0 / Verilator 5.050. T1 item 9 grades **met** cited to a different file
(`verification/signoff/item9-testbenches.json`), so nothing in this
supersession bears on it. What generalises is the list's own criterion, read in
both directions: a record under `item5/` sits outside this disclosure only when
it names no layout input at all — no `provenance.input` pin and no
`def`/`spef`/`gds` path — which describes `functional-item9.result.json` alone
among the `item5/` JSON files; everything else measures the pinned stream or is
derived from a record that did. (A bare `provenance.input is null` test would
misfire here: it is true of the two request records too, which carry no
`provenance` block either but are requests **for** the superseded runs, bound
by the stream path they set — an absent key and a null value read the same to
`jq`.)

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
the SPEF, `item5/extract.report.json`, the two `item5/sta-*.request.json`
records and this README are cited by no manifest entry. `item5/summarize_sta.py --check` does regenerate-and-compare
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
- **Functional:** the 23 stamped bench runs pass in the plain-Verilog runner
  (0 failures, negative control fails as required; `item5/functional-item9.result.json`).
  Additionally (re-run 2026-11-05, klt 0.9.0 via `testbench.verilog_top`, the
  path klayout-tools#4996 pointed to), the six benches that need no plusargs
  were run through `klt functional-verification`; requests and reports are under
  `item5/func/` (`lut4_slice`, `logic_tile`, `logic_tile_gapfill`,
  `logic_tile_routed`, `switch_matrix`, `lut4_ff_bel_equiv`): 6/6 `pass`. The
  bitstream-level benches (`tb_logic_tile_bitstream.v`, driven by `+bin= +map=
  +wiring=`) cannot be expressed as a request because the Verilog-bench form has
  no plusargs field (filed as 2AMLogic/klayout-tools#5006), so they remain
  covered only by the runner result above. The tool reports one synthetic test
  per bench, not per-case rows.

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

- the top-level report outside `parasitics.nets`: the summary scalars under
  `parasitics` (`parasitics.r_count`, `parasitics.total_resistance_ohm`,
  `parasitics.total_capacitance_ff`, …), the root findings lists
  (`warnings`, `dead_metal`, `missing_flavour_markers`), the
  `parasitics`-level lists (`parasitics.metals_without_coefficient`,
  `parasitics.overlap_pairs_without_coefficient`, `parasitics.critical_nets`,
  `parasitics.parasitics_nets` — all empty in the measured record), the
  `parasitics.integrity` and `parasitics.substrate_dc_tie` aggregates, the
  `parasitics.model` prose, and `provenance` (tool versions).
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
- per-net `terminals` / `segments` / `pin_order` — empty under the lumped
  model; `hub_net` is derivable by a constant rule (`<net>__par`, 369/369
  in the measured record) and has no consumer once the RC network is cited
  to the SPEF.

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
