# T1 item 5 — bounded timing iteration (issue #161)

Evidence-only record: a fresh baseline, the stage-by-stage anatomy of the
worst setup path at `ss_125C_1v62`, and six bounded variants at the
pre-registered 20 ns period across all 15 shipped corners. Nothing here
replaces the committed tile, changes a spec row, or answers the decision
pending on #27; it produces the measured evidence that decision waits on.

- **Date**: 2026-11-21. **Host**: dispatch worker `loom-worker-1` (shared).
  All runs local and serial, in a scratch tree built by
  [`run-all.sh`](run-all.sh) laid out like this repo (the `run-synth.sh`
  discipline); nothing under `layout/`, `flow/` or `rtl/` was written.
- **Tools**: `klt 0.9.0` (the `flow/pdk.json` pin, via `flow/klt.sh`/uvx),
  KLayout `0.30.12`, OpenROAD `26Q3-1510-g6cb3f2b704`, PDK `gf180mcuD`
  at open_pdks `f6eeac7…` (`flow/setup-pdk.sh --verify` clean). Every
  report's `provenance.klt_version` is `0.9.0`.
- **Graded constraint set** (every `sta-*` request, all variants): the
  pre-registered set, byte-identical to `item5-24um/sta-lef-only.request.json`
  — 20 ns on `clk`, I/O delays 0, ideal clock, all 15 corners,
  `geometry_source: routed`. No `false_path_from`, period change or corner
  removal on any graded run.

## 1. Baseline and path anatomy

**Baseline.** The committed stream is already freshly measured: #160's
`item5-24um` records (2026-11-20, klt 0.9.0, fleet OpenROAD `26Q4-1310`)
re-ran the committed 24 µm stream at all 15 corners — setup fails only at
`ss_125C_1v62` (−25.41 ns LEF / −25.92 ns SPEF) and `ss_n40C_1v62`
(−24.08 / −24.50), 20 violating endpoints each, hold clean everywhere. The
layout, constraints and tool pin match this issue's runs, so those records
are the baseline. As a control, variant **v0** re-ran the identical graded
request on this host's engine: **bit-identical at all 15 corners**
(`reports/v0/`), so the 26Q3 engine here and 26Q4 fleet engine agree on this
design and every variant delta below is attributable to the variant.

**Per-stage anatomy at `ss_125C_1v62`.** No released klt carries the
per-stage path fields of 2AMLogic/klayout-tools#5783 — probed at the pin
(`0.9.0`) and at the latest release (`0.9.2`, still latest on PyPI as of
2026-11-21; #5783 closed 2026-11-18, after that release). That fact is
recorded in a comment on that issue. What a released klt *does* carry is its
own `report_checks` delay fingerprint (emitted around `read_spef`), so the
`anatomy` phase ran the committed stream at the single corner
`ss_125C_1v62` with the committed `item5-24um` SPEF and preserved klt's
engine output verbatim
(`reports/anatomy/sta-spef.report.json`,
`reports/anatomy/worst-setup-path-ss125-{lef,spef}.txt`; request
`requests/sta-anatomy.request.json`). The worst setup path:

| # | stage (pin) | cell (drive) | stage delay, LEF (ns) | cumulative (ns) |
|---|---|---|---:|---:|
| 1 | `u_sm/_248_/Z` | `mux4_1` | 10.814 | 10.814 |
| 2 | `g_slice[2].u_slice/_08_/Z` | `mux4_1` | 9.567 | 20.382 |
| 3 | `g_slice[2].u_slice/_12_/Z` | `mux4_2` | 8.157 | 28.539 |
| 4 | `g_slice[2].u_slice/_13_/Z` | `mux2_2` | 5.454 | 33.993 |
| 5 | `u_sm/_259_/Z` (n_out[0]) / `u_sm/_229_/Z` (w_out[3]) | `mux4_1` | 7.906 | 41.899 |
| 6 | `u_sm/_260_/ZN` / `u_sm/_230_/ZN` | `nor2_1` | 2.356 | 44.255 |
| 7 | `u_sm/_261_/ZN` / `u_sm/_231_/ZN` | `aoi21_1` | 1.157 / 1.663 | 45.412 / 45.918 |

- **Path**: `cfg[132]` (input) → `n_out[0]` LEF-only, arrival 45.412 ns;
  `cfg[132]` → `w_out[3]` SPEF-annotated, arrival 45.918 ns (slack
  −25.412 / −25.918 against the 20 ns period). **7 logic levels**,
  cfg-decode mux in the switch matrix → the LUT4 slice's internal mux tree
  → the switch-matrix output mux → `nor2`/`aoi21` output gating.
- **Which cells dominate**: the four `mux4` stages are 36.44 ns of the
  45.92 ns arrival (**79 %**); every stage is minimum- or near-minimum
  drive (`_1`, one `_2` each on mux4/mux2). The same engine output shows
  each `u_sm` output gate drives exactly its one output port (the
  `KLT_DRIVER_NET` list: fanout 1 each), so the output drivers are not
  fanout-limited.
- **Net vs cell delay**: the same path shape moves 45.412 → 45.918 ns
  LEF→SPEF, i.e. routed parasitics add ~0.51 ns (~1.1 %). The failure is
  **cell delay at the 1.62 V corner**, not interconnect.
- Slew/fanout per stage are exactly the #5783 fields no release carries;
  recorded as absent (comment linked above).

**Worst non-`cfg` path at both failing corners** (from #160's committed
diagnostic runs `item5-24um/sta-noncfg-*`, same stream/constraints/pin):
`s_in[0]` → `n_out[0]` at −24.83 / −23.62 ns (LEF-only) and `s_in[0]` →
`w_out[3]` at −25.34 / −24.05 ns (SPEF) at `ss_125C_1v62` / `ss_n40C_1v62`.
Excluding every `cfg[*]` startpoint does **not** close either corner — the
datapath fails too, through the same slice/output-mux structure.

**Endpoint census** (klt engine output, this run): 20 setup-violating
endpoints at `ss_125C_1v62`, all `output_setup` checks, arrivals
45.32–45.92 ns — a uniform wall, not one outlier path.

## 2. The six variants

Every graded STA request is the committed constraint set; variants change
only what the named knob controls. P&R seed 1 and the explicit floorplan
(core 106.40 × 105.84 µm, core area = 11261.4 µm²) are held fixed everywhere.

| variant | one change from base | synth cell area (µm²) | util (%) | in-flow P&R STA (its own corner) |
|---|---|---:|---:|---|
| v1 | synthesis: `pdk.corner ss_125C_1v62`, `clock_period_ns 20` (ABC `-D 20000`); P&R as committed (tt) | 6497.79 | 62.42 | +18.39 ns (tt, idle) |
| v2 | P&R `pdk.corner ss_125C_1v62` on the committed netlist | 6809.51 | 64.33 | **+3.60 ns, TNS 0 — repair never engaged** |
| v3 | v1 + v2 together | 6497.79 | 62.42 | +3.39 ns, TNS 0 — idle |
| v4 | v2 + `input/output_delay_ns 0` in the P&R request, so `repair_timing` sees the failing `output_setup` paths | 6809.51 | 68.13 | −25.12 ns, TNS −454.9 — engaged |
| v5 | v3 + the same I/O delays | 6497.79 | 65.65 | −25.10 ns, TNS −452.5 — engaged |
| v6 | the 9-track library `gf180mcu_fd_sc_mcu9t5v0` (synthesis tt/period-null and P&R tt as committed, library swapped; same core = 190 × 21 sites of 0.56 × 5.04 µm; tapcell 24 µm) | 8419.22 | 78.37 | +18.70 ns (tt, idle) |

Committed baseline (v0): core area 11261.4 µm², synth cell area 6809.51 µm²,
util 64.33 %, 0 route DRC violations — all variants share core area
11261.4 µm² and closed routing with **0 DRC violations**.

**Why v2 did nothing, measured.** The committed P&R constraints carry no
output delay, so in-flow STA has no `output_setup` checks at the output
ports; at the slow corner its worst path is an internal one with +3.60 ns
slack (`worst_slack_ns`; `corners[ss_125C_1v62].setup_slack_ns` = +3.08 ns)
and TNS 0, so `repair_timing` had nothing to fix and the routed
result is bit-identical to baseline at **all 15 corners**. Adding I/O
delays 0 (v4/v5) makes in-flow STA see the graded condition (−25.1 ns, TNS
−455) and repair then recovers ~2.9–3.0 ns. This confirms — this time by
switching the one constraint set on and off — the constraint-set-difference
hypothesis `measurements/README.md` records for why
`layout/records/step0-par.json` reports +3.08 ns where `klt sta` reports
−25.41 ns: the in-flow run was never shown the output paths.

## 3. Graded results — all 15 corners, 20 ns period (worst setup slack, ns, LEF-only)

| corner | v0 | v1 | v2 | v3 | v4 | v5 | v6 | v6+SPEF |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `ff_125C_1v98` | 9.917 | 9.994 | 9.917 | 9.994 | 10.604 | 10.737 | 10.992 | 10.932 |
| `ff_125C_3v60` | 14.868 | 14.912 | 14.868 | 14.912 | 15.337 | 15.372 | 15.545 | 15.511 |
| `ff_125C_5v50` | 16.284 | 16.315 | 16.284 | 16.315 | 16.677 | 16.687 | 16.803 | 16.763 |
| `ff_n40C_1v98` | 12.302 | 12.374 | 12.302 | 12.374 | 12.847 | 12.920 | 13.159 | 13.115 |
| `ff_n40C_3v60` | 16.440 | 16.476 | 16.440 | 16.476 | 16.771 | 16.800 | 16.895 | 16.872 |
| `ff_n40C_5v50` | 17.378 | 17.405 | 17.378 | 17.405 | 17.663 | 17.673 | 17.732 | 17.714 |
| **`ss_125C_1v62`** | **−25.412** | −25.067 | −25.412 | −25.067 | −22.506 | −22.390 | **−19.852** | **−20.029** |
| `ss_125C_3v00` | 6.863 | 6.992 | 6.863 | 6.992 | 7.963 | 8.048 | 8.793 | 8.721 |
| `ss_125C_4v50` | 11.839 | 11.913 | 11.839 | 11.913 | 12.653 | 12.672 | 13.219 | 13.170 |
| **`ss_n40C_1v62`** | **−24.075** | −23.894 | −24.075 | −23.894 | −21.961 | −21.797 | **−18.153** | **−18.305** |
| `ss_n40C_3v00` | 10.682 | 10.785 | 10.682 | 10.785 | 11.517 | 11.519 | 12.161 | 12.112 |
| `ss_n40C_4v50` | 14.319 | 14.376 | 14.319 | 14.376 | 14.919 | 14.924 | 15.325 | 15.290 |
| `tt_025C_1v80` | 2.361 | 2.508 | 2.361 | 2.508 | 3.500 | 3.589 | 4.379 | 4.295 |
| `tt_025C_3v30` | 13.659 | 13.720 | 13.659 | 13.720 | 14.201 | 14.251 | 14.551 | 14.511 |
| `tt_025C_5v00` | 15.723 | 15.764 | 15.723 | 15.764 | 16.163 | 16.175 | 16.373 | 16.345 |

Per-variant aggregates (worst corner in every case `ss_125C_1v62`): TNS
−465.41 (v0) / −458.85 (v1, v3) / −465.41 (v2) / −408.00 (v4) / −403.07
(v5) / −340.79 (v6); violating endpoints 20 at each of the same two
corners in every run; **worst hold slack ≥ +0.028 ns everywhere** (v6 LEF
+0.028, v6 SPEF +0.034). The 13 passing corners stay clean in every
variant — and improve monotonically with each knob that helps.

**Best variant, SPEF-annotated (v6).** `klt extract` on v6's routed stream
(1001 parasitic nets, same as the committed 24 µm stream) then the graded
SPEF run (`requests/sta-v6-spef.request.json`): `ss_125C_1v62` −20.029 ns,
`ss_n40C_1v62` −18.305 ns, hold ≥ +0.034 ns — the rightmost column above.
SPEF annotation is partial exactly as in #160 (333 of 369 design nets; the
same 36 slice-internal hierarchical nets unannotated), so it is a lower
bound on parasitic impact, not a post-route claim.

## 4. Outcome

**No variant closes 15/15 at 20 ns.** The best is v6 (the 9-track
library), still −19.85 ns LEF / −20.03 ns SPEF at `ss_125C_1v62` (and
−18.15 / −18.31 at `ss_n40C_1v62`) — a remaining gap of ~20 ns at the
binding corner. The limiter is **cell delay at 1.62 V through the fixed
7-level `cfg`→slice→output-mux structure**: synthesis mapping at the slow
corner recovers 0.35 ns (ABC's own wireload-free estimate of the slice
path is already 21.4 ns against the 20 ns target), P&R repair — once it
can see the failing paths at all — recovers ~3 ns by resizing/buffering,
and swapping to the faster/taller 9-track library recovers ~5.6 ns at a
utilization cost of 64 % → 78 %. Closing the remaining ~20 ns (a ~2.3×
speedup of a 45 ns path) is not reachable by any single flow knob this
repo's requests expose; it needs either an architectural change to the
config/datapath mux structure, or the #27 decision (period, corner set, or
binding corner) — which this record now feeds with measured limits.

Findings posted on #27; no adoption issue is filed because nothing closes.

## 5. Limitations

- Per-stage slew/fanout/cell-vs-net split: not available in any released
  klt (#5783 lands after 0.9.2); the anatomy above is klt's own
  `report_checks` output, transcribed verbatim, and the LEF→SPEF arrival
  delta bounds the net-delay share (~1.1 %).
- The v6 SPEF run annotates 333/369 nets (unchanged, known #160 finding);
  both SPEF figures are lower bounds on parasitic impact.
- Variant routed DEFs/GDS/netlists are scratch artifacts under the run
  tree's `work/`, regenerated by `run-all.sh`; each graded report pins its
  DEF by `provenance.input.content_hash`, and each synth report pins its
  netlist by `netlist_sha256` (v1: `afcdf5c7c62c4994…`).
- Area is reported as measured (no target traded against): v6's
  utilization 78.37 % is the honest cost of the 9-track comparison.

## 6. Reproducing

```sh
measurements/item5-timing-iteration/run-all.sh TREE control
measurements/item5-timing-iteration/run-all.sh TREE anatomy
for V in v1 v2 v3 v4 v5 v6; do \
  measurements/item5-timing-iteration/run-all.sh TREE variant $V; done
measurements/item5-timing-iteration/run-all.sh TREE spef v6    # best variant
measurements/item5-timing-iteration/run-all.sh TREE summary
```

`TREE` is a scratch directory (safely re-created once); needs the pinned
PDK (`flow/setup-pdk.sh`), `jq`, `uvx`, `yosys`, `openroad`. One run per
phase; v3/v5 consume v1's netlist inside the same tree. Wall clock on this
host: ~23 s per 15-corner STA, ~75–105 s per P&R; the whole record, ~15
minutes of serial tool time.
