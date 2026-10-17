# flow/ — PDK pin and toolchain bring-up

Toolchain bring-up only. Nothing here designs the tile; the library, variant
and metal stack the tile uses are decided in the spec (#2).

## Cold start (one command)

```bash
flow/smoke/run-smoke.sh
```

This verifies the PDK pin, runs `klt synthesize` and `klt place-and-route` on
both candidate libraries, and rewrites `flow/smoke/records/`. Install the PDK
first on a clean machine:

```bash
flow/setup-pdk.sh          # installs into flow/.pdk-root (git-ignored) or $PDK_ROOT
```

`setup-pdk.sh` runs ciel 2.6.1 through `uvx` (nothing is installed host-wide)
and exits 2 if any variant's `SOURCES` revision differs from the pin in
`flow/pdk.json`, or a candidate library is missing. `--verify` checks without
installing. A stale install at another revision is refused, never used.

Needs `jq`, `uvx`, `yosys`, `openroad` and `klt` on `PATH`. The smoke is a
single local corner; it is not a grid.

## Smoke design

`flow/smoke/rtl/smoke_lut4.v` is a registered 4-input function (not the
tile). Each library has its own directory with `synth.json` and `par.json`
requests, both at `tt_025C_5v00`, variant `gf180mcuD`. The
post-synthesis netlist is committed under `netlist/` so the P&R request is
reproducible; the `klt` JSON responses are in `flow/smoke/records/`
alongside `toolchain.json` (pin, commit, tool versions).

## Results (2026-10-17, base commit 88ab5c8)

| | mcu7t5v0 | mcu9t5v0 |
| --- | --- | --- |
| Cells after synthesis | 3 (dffq_1, xor2_1, xor3_1) | 3 (dffq_1, xnor2_1, xnor3_1) |
| Cell area (µm²) | 140.49 | 177.81 |
| Core area (µm², explicit) | 9768.64 | 10160.6 |
| Router closed | yes, `stage_reached: route`, 0 DRC violations | yes, 0 DRC violations |
| `power.pdn` | true (preset `gf180mcu_7t_6M`) | true (preset `gf180mcu_9t_6M`) |
| `power.tapcell_master` | `gf180mcu_fd_sc_mcu7t5v0__filltie` | `gf180mcu_fd_sc_mcu9t5v0__filltie` |
| Tapcells placed | 27 | 22 |

The core area is **not** the design's area: the 4-input function is ~140–180
µm², and the cores are sized by the minimum the preset PDN needs (the Metal4/5
straps reject a smaller core: 94 µm high for 7t). Do not read the smoke core
area as a density figure for the tile. The tapcell pitch is set to 40 µm
(`power.tapcell.distance_um`) because at the default 100 µm no tapcells land
in a core this small and `power.placed.status` is `partial`.

`klt place-and-route --check` against each committed report returns `match`.
FABulous 2.2.0 resolves via `uvx --from FABulous-FPGA`; `nextpnr-generic`
is not installed on the bring-up host.
