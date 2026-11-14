# layout/ — routed tile (T1 item 2, issue #22; DRC item 3, issue #23)

`logic_tile_routed` placed and routed with `klt place-and-route` (OpenROAD) on
`gf180mcu_fd_sc_mcu7t5v0`, variant `gf180mcuD`, corner `tt_025C_5v00`, input
`flow/tile/netlist/logic_tile_routed_synth.v` (193 cells, 6809.51 µm²).

```bash
flow/setup-pdk.sh        # once
layout/run-par.sh        # regenerate par.json, run klt, rewrite records + stream
layout/run-par.sh --check  # klt place-and-route --check -> match
```

Run from the repo root inside `run-par.sh`: OpenROAD only mounts the
invocation directory, so the request cannot sit above the netlist.
Single local run; not a grid.

## Files

| File | Content |
|---|---|
| `make-request.py` | emits `par.json` for a given core size (pin windows included) |
| `par.json` | the request: explicit floorplan, `power.pdn: true`, preset `gf180mcu_7t_6M`, tapcell pitch 24 µm (`power.tapcell.distance_um`; the master is **not** pinned here — see below), `library.route_layers` Metal2–Metal4, `io` Metal3/Metal2 |
| `records/step0-par.json` | the `klt place-and-route` response (ladder step 0) |
| `records/abutment.json` | `klt interface-check` 2×2 seam results |
| `logic_tile_routed.gds` / `.def` | routed stream and DEF consumed by items 3, 4, 11 |
| `logic_tile_routed_routed.v` | as-built gate-level netlist (for LVS) |
| `abut-check.py` | drives the abutment check (see below) |
| `drc/tile.drc.json` | `klt drc` report on `logic_tile_routed.gds` (T1 item 3; **clean** on the curated deck, see below) |

`par.json` pins the tapcell *pitch* and nothing else about the tap cells: the
only key `klt.place_and_route.request/1` accepts under `power.tapcell` is
`distance_um`. The tapcell **master** is chosen by klt from its built-in
per-cell-library table, keyed on `pdk.cell_library` — for
`gf180mcu_fd_sc_mcu7t5v0` that is `gf180mcu_fd_sc_mcu7t5v0__filltie` (with
endcap `gf180mcu_fd_sc_mcu7t5v0__endcap`), the effective value klt reports back
as `power.tapcell_master` in `records/step0-par.json`. `flow/README.md`
tabulates the same per-library value for the two smoke libraries. So the master
this tile is built with is attested by the response, not held by the request;
klt 0.9.0 would let the request pin it (`library.tapcell.master`, which takes
precedence over the built-in table), and whether this repo should do so is
issue #93.

## Result: ladder step 0 closes, tap-distance clean (2026-11-14, klt 0.9.0)

Re-run of the same floorplan with the tapcell pitch brought under the MV
tap-distance limit (issue #55). **The floorplan is unchanged** — same die, same
core, same 190 × 27 site grid, same pin windows — so this is the step-0 result
re-measured with denser well ties, not a smaller tile. Ladder steps 1–3 are
still **not taken** and step 4 was never in play; the tile cell set is unchanged.

| | | prior (40 µm) |
|---|---|---|
| Stage reached | `route`, status `ok` | `route`, `ok` |
| Die / core area | 13368.8 µm² (117.60 × 113.68) / 11261.4 µm² (106.40 × 105.84) | *unchanged* |
| Utilization (post-route) | 64.33 % | 63.20 % |
| Aspect (die) | 1.03 : 1 (inside 1:2–2:1) | 1.03 : 1 |
| Global-route overflow | 0 (H 0, V 0); 367 routed nets, 0 unrouted | 0; 367, 0 |
| Detailed-route DRC | 0 (per iteration 206 → 88 → 107 → 1 → 0) | 0 (205 → 115 → 95 → 0) |
| Antenna violations | 0 | 0 |
| Global-route layer usage | Metal1 0 %, Metal2 44.4 %, Metal3 35.3 %, Metal4 3.2 % | 44.6 / 33.8 / 3.8 %, Metal5 0 % |
| PDN | `power.placed.status` `complete`; **58 tapcells**, 54 endcaps | 29 tapcells, 54 endcaps |
| Wirelength | 18.1 mm (route-stage estimate) | 17.8 mm |
| Worst-case Comp-to-tap distance | **11.67 µm** (nwell) / 11.55 µm (psub), limit 15 µm | 19.75 / 19.66 µm |

Area did not change and was not made to change: `floorplan.method` is
`explicit`, so the die and core are inputs, not results. The cost of the denser
ties is paid in **utilization** (63.20 % → 64.33 %) and wirelength (+1.3 %), not
in µm². Per spec row 4 no µm² ceiling is ratified; 11261 µm² core remains the
figure of record. Congestion stayed low (peak layer 44.4 %, Metal4 nearly
unused), so the extra 29 tie cells did not make the switch matrix the limit.
This is still one seed (`seed: 1`) at one floorplan, not a utilization sweep.

### Tapcell pitch and MV tap distance

`power.tapcell.distance_um` is **24 µm** (`layout/run-par.sh`, passed through
`make-request.py`). It is not the DRM limit and must not be read as one:
OpenROAD's `tapcell -distance` is the *staggered tap-column spacing*, and the
worst-case Comp-to-tap distance it yields comes out at **about half** of it. The
relationship was measured, not assumed, with `klt tap-distance` on the routed
stream:

| `distance_um` | measured worst-case Comp→tap | vs 15 µm limit | `comp.tap_distance.*.mv.1` |
|---|---|---|---|
| 40 (prior) | 19.75 µm (nwell), 19.66 µm (psub) | **over** | 46 violations |
| 24 (now) | 11.67 µm (nwell), 11.55 µm (psub) | 22 % under | 0 |

So 24 µm was chosen as "roughly twice under the limit", for margin on a
relationship that is approximate (tap columns quantize to the site grid, and the
rule is Euclidean and 2-D, measured to taps in neighbouring rows too). One
re-run was needed, not a search: 40 µm was measured first, the ~D/2 relation
read off it, and 24 µm hit 11.67 µm against a predicted ~11.9 µm.

Reproducing the two measurements above (they are diagnostics, not committed
evidence — the committed verdict is `drc/tile.drc.json`):

```bash
source flow/klt.sh
klt tap-distance layout/logic_tile_routed.gds --max-distance-um 15 \
  --subject '22/0 & 31/0 & 21/0' --taps '22/0 & 32/0 & 21/0' --island '21/0'  # nwell, DF.13
klt tap-distance layout/logic_tile_routed.gds --max-distance-um 15 \
  --subject '22/0 & 32/0 - 21/0' --taps '22/0 & 31/0 - 21/0'                  # psub, DF.14
```

### Layer budget (spec row 3: signals on Metal2–Metal4)

**The budget is now enforced by the request, not evidenced after the fact.**
`par.json` carries `library.route_layers` `Metal2`–`Metal4`, and the response
echoes `applied.signal_layers: "Metal2-Metal4"`. The routed DEF has signal wire
segments on Metal1 (842, in-cell pin access stubs), Metal2 (2910), Metal3 (1130),
Metal4 (126) and **none on Metal5**; Metal5 appears only in the PDN
(`SPECIALNETS`).

This replaced an after-the-fact check, and the change was not cosmetic. klt
could not cap the signal layers when the 2026-11-02 run was made — it always
opened the library's whole Metal2–Metal5 range (2AMLogic/klayout-tools#4802) —
so that run's compliance was luck, not construction. **The first 24 µm run
proved it: with the range uncapped, the denser ties pushed one 7.84 µm segment
of net `w_in[1]` onto Metal5**, which is spec row 3's *fallback* (ladder step 2),
not its target. #4802 has since landed in klt 0.9.0, so capping the router holds
ladder step 0 by construction instead. Taking the cap cost nothing: the tile
still routes with 0 overflow, 0 unrouted nets and 0 detailed-route DRC.

Reproducibility: `run-par.sh --check` returns `match`. Stream SHA-256
`ecf5be0a2415d1ef744c227c6086a36ff2009b7dfe76907a166f1eea2f56b662`
(`logic_tile_routed.gds`). `--check` verifies the request inputs (netlist,
liberty) against the record; it does not re-run the flow, and no second full run
was byte-compared.

STA in the response (15 liberty corners, post-route, 20 ns clock) shows 0
setup/hold violations, worst setup slack 3.08 ns (was 3.28 ns). That is a tool
figure, not the timing claim: spec row 5 needs parasitics from a pre-registered
run (separate item).

**Engine pin.** This run is klt `0.9.0` with KLayout pinned to `0.30.12`
(`klayout_spec` in `flow/pdk.json`). The pin was added here: `flow/klt.sh`
pinned klt but not its engine, so uvx resolved a freshly released KLayout
`0.30.13` and the first re-run of this tile carried
`provenance.klayout_version_mismatch: true` — klt's own warning that report
counts may differ from the pairing it was tested against. Every record committed
in this repo was made on `0.30.12`; the pin keeps it that way. The merged GDS
was byte-identical under both engine versions, so nothing here rests on the
difference.

## Superseded: first closing run (2026-11-02, tapcell 40 µm, klt 0.8.1.dev1073+gbe5754378ff3)

Kept as history (recorded evidence is append-only). **The stream and records
this section describes are no longer the committed ones**: its 40 µm tapcell
pitch is what issue #55 fixed, and its `d71889f0…` GDS is replaced by the
`ecf5be0a…` stream above. Its DRC result is kept in the DRC section below.

The tile routed on the target library and stack with no ladder step needed, so
steps 1–3 (lower utilization, Metal5 for signals, 9-track library) were **not
taken** and step 4 was never in play. The tile cell set is unchanged.

| | |
|---|---|
| Stage reached | `route`, status `ok` |
| Die / core area | 13368.8 µm² (117.60 × 113.68) / 11261.4 µm² (106.40 × 105.84) |
| Utilization (post-route) | 63.20 % |
| Aspect (die) | 1.03 : 1 (inside 1:2–2:1) |
| Global-route overflow | 0 (H 0, V 0); 367 routed nets, 0 unrouted |
| Detailed-route DRC | 0 (violations per iteration 205 → 115 → 95 → 0) |
| Antenna violations | 0 |
| Global-route layer usage | Metal1 0 %, Metal2 44.6 %, Metal3 33.8 %, Metal4 3.8 %, Metal5 0 % |
| PDN | `power.placed.status` `complete`; 29 tapcells, 54 endcaps |
| Wirelength | 17.8 mm (route-stage estimate) |

Layer budget (spec row 3: signals on Metal2–Metal4). `klt` cannot cap the
signal layers: it always opens Metal2–Metal5 (gap filed as
2AMLogic/klayout-tools#4802). The budget is therefore evidenced after the
fact: global-route Metal5 demand is 0, and the routed DEF has signal wire
segments on Metal1 (842, in-cell pin access stubs), Metal2 (2745), Metal3
(1016), Metal4 (100) and none on Metal5; Metal5 appears only in the PDN
(`SPECIALNETS`). So the closing run is also within the Metal2–Metal4 budget.

Congestion is low (peak layer 44.6 %, Metal4 almost unused), which says the
switch matrix is not the limit on this stack at this size. That is one seed
(`seed: 1`) at one floorplan, not a utilization sweep: the 63 % is the
floorplan chosen here, not the densest the tile closes at. Per spec row 4 no
µm² ceiling is ratified; 11261 µm² core is the figure of record for this
first closing tile.

Reproducibility, as recorded at the time: `run-par.sh --check` returned
`match` against stream SHA-256
`d71889f054b5087bd607cfc69a02e23e60b7c6601f6be586c91ca02b582d634a`
(`logic_tile_routed.gds`). That stream is no longer committed, so this
particular `--check` claim is historical and does not re-run today; the live one
is in the current section above. `--check` verifies the request inputs (netlist, liberty) against the record; it does not re-run the flow, and no second full run was byte-compared.

STA in the response (15 liberty corners, post-route, 20 ns clock) shows 0
setup/hold violations. That is a tool figure, not the timing claim: spec row 5
needs parasitics from a pre-registered run (separate item).

## Pins and the 2×2 abutment check

`n_out[i]`/`s_in[i]`, `n_in[i]`/`s_out[i]`, `e_out[i]`/`w_in[i]`,
`e_in[i]`/`w_out[i]` are ordered groups in the same 4-slot window on opposite
edges. The 158 `cfg` bits and `clk` sit in bands whose mirror on the opposite
edge holds no pin of the same kind in the same window (cfg low band on N/E,
high band on S/W; clk in the gap between signal windows). `cfg` and `clk` are
per-tile and are not mated pins: a cfg/clk pin may face a different cfg pad of
a neighbour across the seam. That is not a spec requirement here but is
unverified for shorts and is left to DRC (#23) of the assembly.

`klt place-and-route` reports `pin_abutment` aligned (delta 0.0) for all four
mated groups. `records/abutment.json` is `klt interface-check` with a tile
and a copy placed one pitch over: seam N/S `0,113.68`, regex
`n_(in|out)\[\d\]`; seam E/W `117.6,0`, regex `e_(in|out)\[\d\]`. Both:
8/8 pins ok, 0 misaligned, 0 no_partner. interface-check pairs identical label
names, so `abut-check.py` renames the facing pins of the neighbour copy first
(gap: 2AMLogic/klayout-tools#4803). The two checks cover N/S and E/W seams of a
2×2; the corner relation follows from the same tile.

## Item 2 attestation

`layout/records/item2-attest.json` is `klt signoff --attest 2` over
`logic_tile_routed.gds` (stream hash pinned, generator `layout/run-par.sh`,
regenerated hash taken after `run-par.sh --check` returned `match`). It is
cited from `manifests/gf180-fpga.json`; `manifests/run-signoff.sh --check`
reports item 2 `met` (klt pin `klayout-tools==0.9.0`).

Where the claim is checked: the `signoff` CI job re-attests from the committed
stream only (it has no PDK checkout or OpenROAD), so it proves the envelope
still binds to the committed GDS. The regeneration claim (that `run-par.sh`
reproduces that stream) is verified by `layout/run-par.sh --check` on a host
with `flow/setup-pdk.sh` done, and is gated when the record is rewritten by
`manifests/run-signoff.sh`. CI does not re-prove it; no separate CI job does
yet.

## DRC (T1 item 3, issue #23): clean on the curated deck

`drc/tile.drc.json` is `klt drc --deck gf180mcu --engine curated --pdk gf180mcuD`
(klayout-tools 0.9.0, KLayout 0.30.12, PDK root from `flow/setup-pdk.sh`,
open_pdks `f6eeac7`) on `logic_tile_routed.gds`. No waivers,
`--allow-deck-errors` or `--allow-missing-host-tools`. `klt drc --check` returns
`match`.

| | | prior run |
|---|---|---|
| status | **`clean`, 0 violations** | `violations`, 46 |
| rules | none | `comp.tap_distance.{nwell,psub}.mv.1`, 23 each |
| input hash | `sha256:ecf5be0a...1eea2f56b662` (equals the committed GDS) | `sha256:d71889f0...d582d634a` |
| deck hash | `sha256:cf44de63f0a5b01c1d09c4d58e0535e990aa4b070bcaae17fd3a94a67a1d97e1` | *same deck* |
| rules checked / skipped / unmodeled | 72 / 54 / 210 | *identical* |

**What changed and what did not.** Only the tapcell pitch (40 → 24 µm, see
"Tapcell pitch and MV tap distance" above). The deck, its content hash and its
entire coverage set are byte-identical to the 46-violation run, so this is the
same deck reaching a different verdict on a changed layout — not a narrower deck
reaching a quieter one. No rule was waived, suppressed or deselected: the
`--rules` selector was not used, and `rule_counts` is empty because nothing
fired. **No new violation class appeared**: the report went from 46 violations in
exactly 2 rules to 0 in any of the 72 checked rules.

T1 item 3 now grades **`met`** in `manifests/gf180-fpga.signoff.json` (T1 met
count 6 → 7 of 11), citing this report. Scope of that verdict is the curated
deck only — see "The PDK-native deck did not run" below.

Coverage, verbatim from the report:

- `layers_in_stream_without_rules`: `0/0, 21/10, 34/10, 36/10, 42/10, 63/63, 81/10, 204/10`
- `rules_skipped` (54, none of them waivers; rules the curated deck marks
  inapplicable to this stream): `bjt.separation.comp.1`, `cap_mk.ongrid.1`,
  `comp.separation.guard_ring_mk.1`, `comp.tap_distance.nwell.lv.1`,
  `comp.tap_distance.psub.lv.1`, `diode_mk.ongrid.1`, `dnwell.ongrid.1`,
  `drc_bjt.ongrid.1`, `efuse_mk.*` (3), `esd.*` (6), `fusetop.ongrid.1`,
  `ldmos_xtor.enclosing.mvpsd.1`, `metal{1..5,top}.separation.guard_ring_mk.1`,
  `metaltop.{ongrid,space,width}.1`, `mim.*` (3), `mim_l_mk.ongrid.1`,
  `mvpsd/mvsd.*` (4), `nwell/poly2.*guard_ring_mk.1`, `pad.*` (2),
  `plfuse.*` (6), `poly2.enclosing.sab.1`, `res_mk.ongrid.1`,
  `resistor.ongrid.1`, `sab.*` (5); full list in the report
- `deck_scope`: `10.4.2 MIM Option B`, `10.7 DRC_BJT Mark Layer`, `7.12 Contact`,
  `7.13 Metaln`, `7.14 Vian`, `7.15 MetalTop`, `7.4 Nwell`, `7.5 Comp`,
  `7.7 Poly2`, `7.8 Nplus`, `7.9 Pplus`, `9.1 Bond Pad`, `EF`, `ESD`, `GR`,
  `MDN`, `MDP`, `OFFGRID`, `SB`

The curated deck lists 210 `unmodeled_rules`; it is not the full PDK deck.

**The PDK-native deck still has not run, so read "clean" as deck-scoped.**
`klt signoff` grades item 3 on `status: "clean"` alone, and this deck lists 210
`unmodeled_rules` plus the 54 skipped and 8 rule-free drawn layers quoted above
— it is not the full PDK deck. A clean curated-deck verdict is therefore
evidence that nothing in those **72** rules fires, and not evidence that the
tile passes the foundry deck. The crosscheck remains open under #23; its
envelope is also not committable yet (2AMLogic/klayout-tools#4986: `klt drc
--check` does not accept its nested shape).

What has changed since #23 recorded this as blocked: that run's `--engine both`
returned `comparison.state: engine_failed` because the host's standalone KLayout
was 0.28.16 against a deck needing >= 0.30.9. **This host now has KLayout
0.30.12**, above that floor, so the native run is no longer blocked by the
worker spec. Actually running and analysing it is out of scope here (it is a
result in its own right, and #23 owns item 3's full claim); it was not attempted
in this change.

**Reading the fix.** Both rules were the MV (15 µm) tap-distance rules, selected
because the 5V library carries Dualgate (55/0), and they were evaluated on the
placed design rather than on standalone cells — a real finding, as #23 judged.
The fix was denser well ties, **not** a floorplan or area change: the die and
core are byte-identical inputs (`floorplan.method: explicit`) and the tile cell
set is unchanged, so no spec decision was needed or taken. The fabric-level
check is #53.

## LVS (T1 item 4, issue #24)

`layout/run-lvs.sh` runs `klt lvs` (engine `klayout`, `reference.form:
gate-level-verilog`, library `gf180mcu_fd_sc_mcu7t5v0`) on the routed stream
extracted with `--abstract-cells 'gf180mcu_fd_sc_mcu7t5v0__*' --def-net-names`,
so every standard cell is a pin-only black box on both sides. This is a
cell-level connectivity compare: it checks that the routed wiring connects the
cell pins as the netlist says. It does not compare transistors inside the
library cells. Requests are `records/lvs-request.json` and
`records/lvs-vs-synth-request.json`, read on stdin from the repo root so the
repo-relative paths are the ones `--check` re-hashes.
`layout/run-lvs.sh --check` returns `match` for both reports.

| Report | Reference | Result |
|---|---|---|
| `records/lvs.json` | `layout/logic_tile_routed_routed.v` (as-built netlist of the same place-and-route run) | `status: match`, 0 errors; `power_connectivity.status: match` (16 masters, 654 instances, no findings) |
| `records/lvs-vs-synth.json` | `flow/tile/netlist/logic_tile_routed_synth.v` (pre-place-and-route synthesis netlist, #21) | `status: mismatch`, 6 circuit-level errors plus 191 `hints.rejected` (pin anchoring on a top that does not pair) |

**The cited reference is the as-built netlist, not the #21 synthesis netlist.**
The synthesis netlist is not a valid LVS reference for the routed layout: it is
hierarchical (`LUT4_SLICE`, `LOGIC_TILE_SWITCH_MATRIX`) and uses `BUF_2`/`BUF_8`,
while the placed-and-routed design carries `buf_4` that place-and-route
inserted, so the cell sets differ before any wire is compared. Deciding that the
synthesis netlist and the as-built netlist are logically equivalent is a
different check (equivalence, not LVS) and is not claimed here. What item 4
therefore establishes is layout == as-built netlist from the same run.

Warnings listed with the claim (all `severity: warning`, none an error): three
`topology` notes that the `nfet`/`pfet`/`bjt` device classes have no
counterpart because no devices are extracted (cells are abstracted);
`topology.power_only_pruned`, 8 layout circuits removed before comparing
(`endcap`, `filltie`, `fill_1/2/4/8/16/32`) because every pin of them is
power/ground and the gate-level Verilog never carries them; and
`topology.top_level_pins_anchored`, 191 top-level pins matched by name.

Power scope: `power_connectivity` checks that each cell's declared power/ground
pins reach the same net on all 654 instances. It is not a rail or PDN
continuity check; the PDN result is the place-and-route response above.

The report was made with the PDK at `$PDK_ROOT` (open_pdks `f6eeac7`, pinned in
`flow/pdk.json`) and klt `0.9.0`. `--check` re-hashes the stream, the reference
and the extraction deck; it does not re-run the compare.

## Supply ERC and power delivery (T1 item 11, issue #30)

`layout/run-erc.sh` runs `klt erc` (klt `0.9.0`, `--findings-only --compact`)
on `logic_tile_routed.gds` with `records/erc-supply-spec.json`. Item 11 cites
three artifacts together: `records/erc.json`, `records/lvs.json` (item 4,
`power_connectivity.status: match`) and `records/step0-par.json`
(`power.pdn: true`, tapcell `gf180mcu_fd_sc_mcu7t5v0__filltie`).
`layout/run-erc.sh --check` re-hashes the stream and the spec against the report.

| | |
|---|---|
| Result | `erc_status: clean`, 0 findings (no `erc.unconnected_net`, `erc.supply_short`, `erc.missing_tie`) |
| Supplies | `VDD` and `VSS`, each `kind: supply`, 1 declared island, 1 matched |
| Stackup | poly, Metal1–Metal5 with Contact and Via1–Via4; the P&R strap layers (Metal1, Metal4, Metal5) are all inside it |
| N-well tie | `nwell_tie`: well `21/0`, tap = `22/0` (Comp) ∩ `32/0` (Nplus), to `VDD`; derived from drawn layers, checked |
| Substrate tie | `substrate_tie`: **asserted**, see below; tap = Comp ∩ Pplus − Nwell, to `VSS` |

**The substrate tie rests on an asserted region.** gf180mcu draws no p-well or
substrate marker, so the substrate side is declared with `well_layer: null` and
`well_boxes`. The 14 boxes are the strips of the standard-cell placement
extent (x 5.17–112.43, y 3.49–110.19 µm) between the 14 merged n-well bars
(read from the stream's `21/0`); every strip must independently hold a tap
reaching `VSS`, and does. They are listed in `ties_checked_by_well_assertion`
in the item 11 citation. The die margin (outside the cell extent) carries no
cells, hence no tap, and is not asserted; a first run with full-width boxes
reported `erc.missing_tie` on the empty top margin strip, which is why the
boxes stop at the cell extent. Boxes follow this tile's floorplan and must be
regenerated if it changes.

They did **not** need regenerating for the 24 µm re-run, and that was checked
rather than assumed: the floorplan is unchanged, and the new stream still draws
exactly 14 merged `21/0` bars with the same bounding box (x 5.17–112.43,
y 5.68–110.19 µm), so the committed `well_boxes` still describe this layout.
`run-erc.sh` was re-run against them and reports 0 `erc.missing_tie`.

**Coverage disclosures** (both values are in `records/erc.json`,
`erc_coverage`; item 11 requires the claimant to state them):

- *Layers in the stream without a declaration.* `layers_in_stream_without_declaration`
  is non-empty: `0/0, 21/10, 55/0, 63/63, 112/1, 204/0, 204/10`. `provenance.deck`
  is `null` (no `--deck`), so this is the unfiltered list of drawn layers the
  ERC spec does not declare, not a list narrowed to connectivity-relevant
  layers. This run says nothing about those layers; item 11 does not rest on
  them. This README has not re-derived what each of them draws.
- *Well-assertion coverage of `substrate_tie`.* Zero `erc.missing_tie` covers
  only what the 14 asserted boxes cover. `well_assertion_coverage` reports
  `uncovered_tap_area_um2: 1227.28` of `drawn_tap_area_um2: 1992.81`
  (`uncovered_tap_fraction: 0.616`) for tap layer `22/0`: about 62% of the drawn
  Comp area lies outside the asserted substrate region. (Both areas grew with
  the 24 µm tapcell pitch — 29 more `filltie` cells draw more Comp — while the
  fraction barely moved.) The likely explanation
  is that most of it is Comp inside n-wells (PMOS active), which a substrate
  tie region correctly excludes. **That explanation was not measured or
  re-derived here**; only the fraction is evidence.

What this does and does not show: supply nets are single conductor islands on
Metal1–Metal5 through Via1–Via4 and every n-well and substrate strip is tied to
its rail. `klt erc` does not model substrate/well continuity
(`erc.supply_short` is reported `inapplicable`, `substrate_continuity_not_modelled`),
so a VDD/VSS short through diffusion is not covered by this run. Not an IR-drop
or EM result.

## Open

- LVS (#24) consumes `logic_tile_routed.gds`; DRC result above (#23).
- Tap distance (#55): **closed** — 46 → 0 violations at a 24 µm tapcell pitch,
  see the result and DRC sections above.
- PDK-native DRC deck crosscheck (#23): still not run. The host KLayout floor is
  no longer the blocker (0.30.12 >= 0.30.9); `klt drc --check` on crosscheck
  reports: 2AMLogic/klayout-tools#4986.
