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
| `par.json` | the request: explicit floorplan, `power.pdn: true`, preset `gf180mcu_7t_6M`, tapcell `gf180mcu_fd_sc_mcu7t5v0__filltie` (40 µm), `io` Metal3/Metal2 |
| `records/step0-par.json` | the `klt place-and-route` response (ladder step 0) |
| `records/abutment.json` | `klt interface-check` 2×2 seam results |
| `logic_tile_routed.gds` / `.def` | routed stream and DEF consumed by items 3, 4, 11 |
| `logic_tile_routed_routed.v` | as-built gate-level netlist (for LVS) |
| `abut-check.py` | drives the abutment check (see below) |
| `drc/tile.drc.json` | `klt drc` report on `logic_tile_routed.gds` (T1 item 3; **not clean**, see below) |

## Result: ladder step 0 closes (2026-11-02, klt 0.8.1.dev1073+gbe5754378ff3)

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

Reproducibility: `run-par.sh --check` returns `match`. Stream SHA-256
`d71889f054b5087bd607cfc69a02e23e60b7c6601f6be586c91ca02b582d634a`
(`logic_tile_routed.gds`). `--check` verifies the request inputs (netlist, liberty) against the record; it does not re-run the flow, and no second full run was byte-compared.

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

## DRC (T1 item 3, issue #23): not clean

`drc/tile.drc.json` is `klt drc --deck gf180mcu --engine curated --pdk gf180mcuD`
(klayout-tools 0.9.0, PDK root from `flow/setup-pdk.sh`, open_pdks `f6eeac7`)
on `logic_tile_routed.gds`. No waivers, `--allow-deck-errors` or
`--allow-missing-host-tools`. `klt drc --check` returns `match`.

| | |
|---|---|
| status | `violations`, **46** |
| rules | `comp.tap_distance.nwell.mv.1` 23, `comp.tap_distance.psub.mv.1` 23 (15 µm max tap distance, 5V/6V domain) |
| where | 8 standard-cell types (mux4_1 18, dffq_1 6, mux4_2 6, clkinv_1 6, ...) |
| input hash | `sha256:d71889f0...d582d634a` (equals the committed GDS) |
| deck hash | `sha256:cf44de63f0a5b01c1d09c4d58e0535e990aa4b070bcaae17fd3a94a67a1d97e1` |

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

**The PDK-native deck did not run.** `--engine both` returned
`comparison.state: engine_failed`: the host's standalone KLayout is 0.28.16 and
the pinned PDK deck needs >= 0.30.9. This is a worker-spec gap (no newer
KLayout provisioned, none may be installed host-wide), not a design result.
Until a native run exists, "clean" could not be claimed even without the 46
violations. The crosscheck envelope is not committed (2AMLogic/klayout-tools#4986): `klt drc --check` does not
accept its nested shape.

**Reading the 46.** Both rules are the MV (15 µm) tap-distance rules, selected
because the 5V library carries Dualgate (55/0). The tile's `par.json` places
tapcells at 40 µm pitch. The klt note says tap distance is context-dependent;
here it is evaluated on the placed design, so this looks like a real
finding rather than a standalone-cell artefact. Fixing it (denser tapcells,
i.e. a floorplan/area change) is a spec decision and was **not** made here;
the tile is unchanged. T1 item 3 therefore stays `unmet` (`check_failed`) in
`manifests/gf180-fpga.signoff.json`. The fabric-level check is #53.

## Open

- LVS (#24) consumes `logic_tile_routed.gds`; DRC result above (#23).
- Tap distance (46 DRC violations): #55. `klt drc --check` on crosscheck reports: 2AMLogic/klayout-tools#4986.
