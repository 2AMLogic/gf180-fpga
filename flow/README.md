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

## Tile netlist and T1 item 1 (`flow/tile/`)

`flow/tile/run-synth.sh` runs `klt synthesize` on `logic_tile_routed`
(`synth.json`: vendored RTL, `gf180mcu_fd_sc_mcu7t5v0`, `tt_025C_5v00`, no
clock target — timing needs characterized data) and pins the gate-level
netlist at `flow/tile/netlist/logic_tile_routed_synth.v` (the stable path for
LVS). `--check` re-synthesizes and exits 3 if the committed netlist is stale.
Result (2026-10-27): 193 cells, 6809.51 µm² cell area, 4 flops, 0 latches /
comb loops / multi-driven nets. `logic_tile.v` is not instantiated by the top.

`flow/tile/run-fabulous.sh` records the FABulous 2.2.0 generator run on the
vendored description (`records/fabulous-gen.txt`): it completes and changes no
vendored file, so no decision record is needed (ADR-0001's deferred question).
`nextpnr-generic` is absent here, so only the fabric generator stage ran.

`flow/tile/attest/item1.json` is the item-1 inventory; the passing envelope is
`flow/tile/records/item1-attest.json` (`klt signoff --attest 1 --inventory
flow/tile/attest/item1.json --check flow/tile/records/item1-attest.json`). The
freshness check is `local_only` (needs the PDK). Citing it from the block
manifest waits on #5 / PR #10.

## klayout-tools release containment (2026-11-14, base commit 7ec812b)

Four klayout-tools gaps this repo filed are now closed upstream. This section
records, per gap, whether the fix is in the pinned release and whether it is in
the latest release — so the cost of a pin bump can be read off a table instead
of guessed. It changes no pin: the bump itself, and retiring any workaround, are
separate decisions.

**Environments.** Both columns were probed in throwaway `uvx` environments;
nothing was installed host-wide.

| Column | How it was entered | `klt --version` printed |
| --- | --- | --- |
| Pinned | `source flow/klt.sh` (`klt_spec` = `klayout-tools==0.9.0`) | `klt 0.9.0` |
| Latest | `uvx --from "klayout-tools==0.9.2" --with "$KLAYOUT_SPEC" klt` | `klt 0.9.2` |

**The host `klt` was not used for any cell.** It is
`klt 0.9.2.dev1029+g76f47afa48f1` (`/home/ubuntu/.local/bin/klt`) — a
pre-release of 0.9.2, newer than the pin and older than the 0.9.2 release, so it
is attributable to neither column.

`0.9.2` is the latest release as of this run, uploaded 2026-11-14T07:48:37Z
(`pypi.org/pypi/klayout-tools/json`); `0.9.0` was uploaded 2026-11-05T04:29:51Z
and `0.9.1` 2026-11-05T20:34:27Z. The latest release was still `0.9.1` when this
work was specified — 0.9.2 landed hours before the probe ran, so re-read PyPI
before reusing this column.

Package directories were resolved inside each environment, and every
source-level cell below is a `grep`/`sed` against the resolved directory
(`$SP`):

```bash
SP="$(uvx --quiet --from "$KLT_SPEC" --with "$KLAYOUT_SPEC" \
      python -I -c 'import klayout_tools,os;print(os.path.dirname(klayout_tools.__file__))')"
```

### The table

Each cell names the flag, module or qualified request/response field that
provides the capability, or `absent`, and gives the tier that settled it:
**T1** = the owning subcommand's `--help`; **T2** = the capability's own
qualified field or branch in the installed source; **T3** = a committed record
in this repo whose `provenance.klt_version` is that column's version.

| Upstream gap | Capability probed for | klt `0.9.0` (the pin) | klt `0.9.2` (latest) |
| --- | --- | --- | --- |
| [#4802](https://github.com/2AMLogic/klayout-tools/issues/4802) | signal-layer cap echoed as `applied.signal_layers` | **present** — `applied.signal_layers` (`place_and_route.py:2475`) — T2, corroborated T3 | **present** — `applied.signal_layers` (`place_and_route.py:2435`) — T2 |
| [#4803](https://github.com/2AMLogic/klayout-tools/issues/4803) | `klt interface-check` pairs complementary pin names | **present** — `--pair A_REGEX=B_TEMPLATE` — T1 | **present** — `--pair A_REGEX=B_TEMPLATE` — T1 |
| [#4986](https://github.com/2AMLogic/klayout-tools/issues/4986) | `klt drc --check` verifies an `--engine both` report | **absent** — no `mode == "crosscheck"` branch in `drc.py` — T2 | **present** — `drc.py:2563` crosscheck branch in `check_drc_report` — T2 |
| [#5006](https://github.com/2AMLogic/klayout-tools/issues/5006) | `testbench.plusargs` on the Verilog-bench path | **absent** — not in `VERILOG_TOP_FIELDS`, fixed `vvp` argv — T2 | **present** — `request.testbench.plusargs` (`functional_verification_verilog_top.py:48,301`) — T2 |

No cell is `not determined`: all eight were settled by T1 or T2.

### Evidence, cell by cell

**#4802 — `applied.signal_layers`.** The cap itself (`request.library.route_layers`)
predates this gap (#4127); what #4802 added is the response echo that lets a
closing run *prove* it respected the budget. Probe, run in both environments:

```bash
grep -rn 'signal_layers' "$SP"
```

In `0.9.0` it returns exactly one hit, inside the `applied` block (shown with
its preceding marker line via `sed -n '2474,2475p'`):

```
place_and_route.py:2474:            # Issue #4802: range given to `set_routing_layers -signal`.
place_and_route.py:2475:            "signal_layers": _signal_layer_range(cell_library, library),
```

T3 corroboration, from a record this repo ran on the pin itself —
`layout/records/step0-par.json` carries `provenance.klt_version: "0.9.0"` with
`applied.signal_layers: "Metal2-Metal4"`, against `layout/par.json`'s
`library.route_layers` `{"low": "Metal2", "high": "Metal4"}`. That is run-level
proof, stronger than the source grep.

In `0.9.2` the same grep puts the field at `place_and_route.py:2435` and also
hits the documentation the release ships, which names the gap (long table row,
elided at `…`):

```
data/cli/place-and-route.md:2485:| `applied` | object | … `signal_layers` (string `"<low>-<high>"`,
additive, issue #4802: the range passed to `set_routing_layers -signal`, i.e.
`library.route_layers` if supplied, else the built-in per-library range …) |
```

**#4803 — `interface-check --pair`.** Settled at T1 by the owning subcommand's
help, run in each environment:

```bash
klt interface-check --help                       # 0.9.0, via flow/klt.sh
uvx --quiet --from "klayout-tools==0.9.2" --with "$KLAYOUT_SPEC" \
    klt interface-check --help                   # 0.9.2
```

Both print the same flag at lines 28–33 of the help text, and its example is
this tile's own seam shape:

```
  --pair A_REGEX=B_TEMPLATE
                        pair complementary names: an A label fully matching
                        A_REGEX mates with the B label named by the
                        re.Match.expand template, e.g.
                        'n_out\[(\d+)\]=s_in[\1]'; repeatable, first match
                        wins; both names must match --pins
```

**#4986 — `drc --check` on a crosscheck envelope.** The fix branches
`check_drc_report` on the envelope's `mode`. Probe, in both environments:

```bash
grep -n 'crosscheck' "$SP/drc.py"
grep -n 'def check_drc_report\|def rerun_drc_report' "$SP/drc.py"
```

In `0.9.0` the first command returns **no match at all**, while the second puts
`check_drc_report` at `drc.py:2611` — so the function exists and has no
crosscheck path. That is the positive evidence of absence: the only function
that could honor the capability does not mention it. (The `drc_crosscheck.py`
module *does* exist in 0.9.0 — it *writes* the envelope. Producing it was never
the gap; checking it was.) In `0.9.2` both halves of the fix are there:

```
drc.py:2563:    if committed.get("mode") == "crosscheck":
drc.py:2564:        # Issue #4986: an ``--engine both`` envelope nests each engine's own
drc.py:2667:    if committed.get("mode") == "crosscheck":
drc.py:2670:            f"{report_path} is an --engine both (crosscheck) report "
```

The second `grep` places the function boundaries in `0.9.2` at
`check_drc_report` `drc.py:2536` and `rerun_drc_report` `drc.py:2631`, so
`:2563` falls in the `--check` path and `:2667` in the `--rerun` path — the
latter being the "`--rerun` supports single-engine reports only" rejection the
upstream criteria asked for.

**#5006 — `testbench.plusargs`.** Probe, in both environments:

```bash
grep -rn 'testbench\.plusargs' "$SP"
grep -rn 'VERILOG_TOP_FIELDS = ' "$SP"      # then sed the tuple and its use sites
```

In `0.9.0` the Verilog-bench path exists but the field does not: the first
command returns nothing, the allowed-key tuple has four entries and the
unknown-key set does not exempt `plusargs`, so such a request would be rejected
as an unknown key — and the simulator argv is fixed:

```
functional_verification.py:3025:VERILOG_TOP_FIELDS = (
functional_verification.py:3026:    "verilog_top",
functional_verification.py:3027:    "pass_marker",
functional_verification.py:3028:    "fail_marker",
functional_verification.py:3029:    "dut_instance",
functional_verification.py:3030:)
functional_verification.py:3051:        set(testbench) - set(VERILOG_TOP_FIELDS) - {"search_path", "testcase"}
functional_verification.py:3314:                ["vvp", vvp_path],
```

In `0.9.2` the field is exempted from the unknown-key check, validated, forwarded
into the `vvp` argv and echoed in the report:

```
functional_verification_verilog_top.py:48:        - {"search_path", "testcase", "plusargs"}
functional_verification_verilog_top.py:73:    resolved["plusargs"] = plusargs(
functional_verification_verilog_top.py:301:                ["vvp", vvp_path, *plusargs],
functional_verification_verilog_top.py:353:                "plusargs": plusargs,  # issue #5006; `[]` when absent
_verilog_top.py:14:    """``testbench.plusargs`` (issue #5006): ``+name[=value]`` strings appended
```

Note that a bare `plusargs` grep is not evidence for this row: in `0.9.0` it
matches `functional_verification.py:1047,1057,1102` — the **cocotb** seed
plusarg — which is a different feature on a different path. Only the qualified
`testbench.plusargs` settles it.

### Two probe rules that do not work

Both are recorded because each would have produced a wrong cell here, and both
look reasonable.

- **A missing `Issue #NNNN:` source marker is not evidence of absence.** #4803 is
  present in `0.9.0` while `grep -rn '#4803\b'` over that release's package
  returns nothing. A marker confirms; its absence proves nothing.
- **A missing *module* is not evidence of absence either.** `0.9.2` holds the
  #4986 and #5006 fixes in `drc_report_check.py` and
  `functional_verification_verilog_top.py` / `_verilog_top.py`, none of which
  exists in `0.9.0` — but those modules are the product of a later refactor, not
  of the fixes, so their absence at the pin shows only that the code was laid out
  differently. Both `absent` cells above rest instead on the qualified field or
  branch being missing from the function that would have to honor it.

### What this means for the workarounds

Sites below are line-cited against this section's base commit, `7ec812b`.

**Already retired at the current pin (0.9.0), no bump involved.** #4802: the
budget is enforced by the request today — `layout/make-request.py:104` caps the
router, and `layout/README.md:106` records that it is "now enforced by the
request, not evidenced after the fact" with `layout/README.md:119` noting the fix
landed in klt 0.9.0 (PR #83). The after-the-fact argument at
`layout/README.md:168-174` is now an append-only record of the 2026-11-02 run,
not a live workaround. #4803's capability is **also already at the pin**, so the
pin alone renders its workaround unnecessary — but the workaround is still live
(`layout/abut-check.py:30`, named as a gap at `layout/README.md:209-211`), i.e.
retirable with no bump at all. Retiring it is follow-on work, not done here.

**A bump to 0.9.2 would retire** the #4986 crosscheck-envelope workaround
(`layout/README.md:285-286`, with the open-item entry at
`layout/README.md:414-416`) and the #5006 functional-verification workaround
(`measurements/README.md:42-46`), both of which are `absent` at the pin and
`present` in 0.9.2.

**It would retire nothing further: there is no row a bump leaves unfixed.** All
four fixes are in 0.9.2 — two already at the pin, two arriving with the bump — so
no gap among these four needs re-filing upstream.
