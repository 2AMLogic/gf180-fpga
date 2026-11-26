# flow/ — PDK pin and toolchain bring-up

Toolchain bring-up only. Nothing here designs the tile; the library, variant
and metal stack the tile uses are decided in the spec (#2).

## The one-command blinky demo (issue #144)

```bash
./flow/blinky.sh
```

A newcomer's reproducible path: a blinky goes from RTL (`blinky.v`) through
Yosys and `nextpnr-generic` to a bitstream, and the bitstream is loaded into
the simulated fabric where the stamped self-checking bench confirms the
output blinks (reset to 0, then a toggle on every clock edge; period = two
input clocks, in fabric clock cycles). The command exits nonzero unless the
bench reports its terminal PASS line, so a bitstream that does not blink
fails. The bench's built-in negative control (`+mutate`) flips every used
routing-select / BEL bit of the loaded stream and requires every flip to be
detected — a zeroed or broken bitstream cannot pass.

The flow is **not re-written here**: it is stamped verbatim from
`sky130-fpga` at the `reuse.lock.json` commit into `flow/common/`
(ADR-0005), and this repo's `flow/blinky.sh` runs it unmodified from a
throwaway staged layout under `flow/build/` (symlinks to the vendored trees;
nothing vendored is edited, no generated file lands in a tracked path).
Regenerated model outputs are byte-compared against the committed stamped
fixtures (`verification/common/bitstream/`), and the assembled frame stream
is byte-compared with FABulous's own `bit_gen`.

**Experimental harness, functional result only.** The demo runs the
experimental single-LOGIC4 harness (upstream `sim/README.md` status), not
the ratified fabric; it makes no timing claim — "wall clock" below is tool
time on the stated machine, not a fabric speed figure.

### Prerequisites

On `PATH`, checked and never skipped (a missing tool exits 2): `python3`
(with tkinter — FABulous imports it at module load), `uv`, `curl`, `tar`,
`sha256sum`, `timeout`, `iverilog`, `vvp`. The first run also downloads the
pinned OSS CAD Suite (~750 MB, sha256-verified) into `flow/build/dl/` and
the pinned FABulous into a throwaway venv under `flow/build/`; nothing is
installed host-wide, and later runs reuse both.

### Measured wall clock and tool versions

Machine class: shared dispatch worker, 16 vCPU Intel Xeon Platinum 8488C,
Ubuntu 24.04, Python 3.12.3, fast network. The machine-readable record behind these
figures — written by the command itself on every successful run — is
[`records/blinky.json`](records/blinky.json); the committed copy is
the 2026-11-20 cold run. CI
(`.github/workflows/verification.yml`, `blinky` job) runs the same command
so a stale figure fails a check rather than silently drifting.

Wall clock measured 2026-11-20 on the machine class above — a **shared**
host, so the figures vary with co-tenant load (quiet-host runs first; the
loaded figure was observed at load average well above the core count):

| | wall clock | tool fetch |
|---|---|---|
| Cold (first run, empty `flow/build/`) | 54–64 s quiet, 133 s loaded | ~750 MB OSS CAD Suite + FABulous venv (download + network-dependent) |
| Warm (tools cached) | 16 s quiet, 67–80 s loaded | none |

| Tool | Version (pinned by the stamped `flow/common/tool_versions.sh`) |
|---|---|
| yosys | 0.69+260 (OSS CAD Suite 2026-10-08, sha256-pinned) |
| nextpnr-generic | nextpnr-0.11.1-54-g861c57be |
| FABulous | 2.2.0 |
| Icarus Verilog | 14.0 (devel) — the OSS CAD Suite build the flow unpacks and runs the benches with; the host Icarus (13.0 here) only satisfies the pre-unpack PATH check |
| uv / python3 | 0.13.5 / 3.12.3 (host, recorded in `records/blinky.json`) |

The pins are verified at run time: `flow/blinky.sh` fails if the yosys or
nextpnr it unpacks does not match the recorded version strings.

## Cold start (one command)

```bash
flow/smoke/run-smoke.sh
```

This verifies the PDK pin, runs `klt synthesize` and `klt place-and-route` on
both candidate libraries, and rewrites `flow/smoke/records/`. Install the PDK
first on a clean machine:

```bash
flow/setup-pdk.sh          # installs into the resolved root (see below)
```

`setup-pdk.sh` runs ciel 2.6.1 through `uvx` (nothing is installed host-wide)
and exits 2 if any variant's `SOURCES` revision differs from the pin in
`flow/pdk.json`, or a candidate library is missing. `--verify` checks without
installing. A stale install at another revision is refused, never used.

### Which PDK root is used

`flow/pdk-root.sh` is the one place that decides, for `setup-pdk.sh` and for
every consumer that needs `$PDK_ROOT` (`layout/run-par.sh`,
`layout/run-lvs.sh`, `flow/tile/run-synth.sh`, `flow/smoke/run-smoke.sh`).
First match wins:

| | root | when |
| --- | --- | --- |
| 1 | `$PDK_ROOT` | set and non-empty in the environment. Used as given; a mismatch still exits 2, and is never repaired or worked around. |
| 2 | `flow/.pdk-root` | an install has materialized there (any variant `SOURCES` present) — at *any* revision, so a leftover install is refused rather than silently reached past. |
| 3 | `${CIEL_PDK_ROOT:-$HOME/.ciel}` | ciel's own store already satisfies the pinned revision and both libraries. Adopted, reported on stderr, and `ciel enable` is skipped — a host that already has the PDK does not re-fetch 3.6 GB of it. |
| 4 | `flow/.pdk-root` | nothing else: the install target in install mode, and the missing root `--verify` reports before exiting 2. |

`flow/.pdk-root` is git-ignored and empty in a fresh checkout or worktree, so
step 3 is what makes a worker that already carries the pinned PDK usable
without a download (issue #79). Step 2 keys on a `SOURCES` file rather than on
the directory, because install mode creates `flow/.pdk-root` before fetching:
an empty one is a download that never landed, not an install to protect.

`$HOME/.ciel` is shared with sibling repos, which re-point its flat variant
symlinks with their own `ciel enable`, so adoption is a point-in-time check —
the revision is re-checked immediately before adoption and again on every
consumer run. `flow/test-pdk-root.sh` tests the whole order against fixture
roots and needs no PDK.

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
separate decisions. (2026-11-26: the bump has since been taken — issue #102
moved `klt_spec` to 0.9.2; the column labels below are relabelled so they still
say which column is the pin. The probes themselves are unchanged 2026-11-14
records.)

**Environments.** Both probes used throwaway `uvx` environments. At probe
time, `source flow/klt.sh` selected klt 0.9.0. To reproduce either version
check with the KLayout engine used in the probe, run the corresponding command.

| Column | Version probe | Output |
| --- | --- | --- |
| Pinned at probe time | `uvx --from 'klayout-tools==0.9.0' --with 'klayout==0.30.12' klt --version` | `klt 0.9.0` |
| Latest at probe time, pinned since issue #102 | `uvx --from 'klayout-tools==0.9.2' --with 'klayout==0.30.12' klt --version` | `klt 0.9.2` |

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

| Upstream gap | Capability probed for | klt `0.9.0` (the pin at probe time; superseded by issue #102) | klt `0.9.2` (the pin since issue #102) |
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

**Correction (2026-11-15, PR #108 / issue #110):** the conclusion the #4803
half of the paragraph below draws — the pin rename is "retirable with no bump
at all. Retiring it is follow-on work" — is **superseded**. PR #108's
2026-11-15 measurement (recorded at `layout/README.md` § "Pins and the 2×2
abutment check"; not re-run for this note) shows the rename is retirable
**neither** at the pin **nor** with a bump: no one-seam check is expressible
with `--pair`, because the obstacle is the documented `--pins`/`--pair`
scoping contract — the pair target must also match `--pins`, `--pins` is one
regex applied to A and B alike, and an in-scope label matching no rule falls
back to same-name pairing — not a missing upstream fix. The gap is tracked
upstream at `2AMLogic/klayout-tools#5778` (filed by #108), which is why
`layout/README.md` now says the rename stays until that gap is resolved. #108
also moved the line citations the paragraphs below rely on; use these section
references instead, which do not drift: the rename site is `renamed()` in
`layout/abut-check.py`, with its rationale in that file's module docstring;
the abutment-check record — including the replacement for the "named as a
gap" text cited below — is `layout/README.md` § "Pins and the 2×2 abutment
check"; the #4986 envelope is § "DRC (T1 item 3, issue #23)"; the open-item
entry is § "Open". The 2026-11-14 text below is kept as written; this note is
the only thing added.

**Already retired at the then-pin 0.9.0 — the pin is 0.9.2 since issue #102, and both fixes are in 0.9.2 as well — no bump for these two involved.** #4802: the
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
(the `**Functional:**` bullet under "Result (as found)" in
`measurements/README.md`), both of which are `absent` at the pin and
`present` in 0.9.2.

**It would retire nothing further: there is no row a bump leaves unfixed.** All
four fixes are in 0.9.2 — two already at the pin, two arriving with the bump — so
no gap among these four needs re-filing upstream.
