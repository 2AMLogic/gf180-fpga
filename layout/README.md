# layout/ — routed tile (T1 item 2, issue #22)

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
| `records/lvs.json` | `layout/logic_tile_routed_routed.v` (as-built netlist of the same place-and-route run) | `status: match`, 0 errors; `power_connectivity.status: match` (16 masters, 618 instances, no findings) |
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
pins reach the same net on all 618 instances. It is not a rail or PDN
continuity check; the PDN result is the place-and-route response above.

The report was made with the PDK at `$PDK_ROOT` (open_pdks `f6eeac7`, pinned in
`flow/pdk.json`) and klt `0.9.0`. `--check` re-hashes the stream, the reference
and the extraction deck; it does not re-run the compare.

## Open

- DRC (#23) consumes `logic_tile_routed.gds`.
