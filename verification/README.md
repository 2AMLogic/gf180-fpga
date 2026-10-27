# verification

`common/` holds stamped copies of the bitstream-level testbenches and committed
bitstream fixtures from `sky130-fpga`, listed with commit and sha256 in
`../reuse.lock.json`. Do not edit them.

Icarus Verilog testbench harness with two modes: cocotb (`smoke/` and its
negative control) and plain Verilog (`--vvp`), which runs the stamped
self-checking benches in `common/` (see "Stamped benches" below). Shape follows `2AMLogic/gf180-tmds-tx` `verification/tmds_encoder/`.

## Cold start (fresh clone)

```sh
python3 -m venv .venv && . .venv/bin/activate
pip install -r verification/requirements.txt
python3 verification/runner.py verification/smoke   # smoke + negative control
verification/lint_rtl.sh                            # RTL lint
```

`pnpm check:ci` (Loom's build gate) runs both of these; `pnpm test` / `pnpm lint` run
each half. It needs the same prerequisites and the venv above on `PATH`.

Prerequisites on `PATH`: Icarus Verilog (`iverilog`), Verilator (lint only).
The runner exits 0 only if the good DUT passes **and** the negative control
fails. A missing simulator is an error (exit 2), never a pass.

## Stamped benches (T1 item 9)

```sh
python3 -I verification/runner.py --vvp verification/item9/benches.json
python3 -I verification/item9/inventory.py --check
```

No cocotb needed, only `iverilog`/`vvp`. `item9/benches.json` is the single
table of benches, DUT sources and plusargs; the runner, CI and
`item9/INVENTORY.md` all read it. A run passes only if `vvp` exits 0, prints a
`PASS:` line and no line starting `FAIL`/`ERROR`; a bench that ends without a
verdict counts as a failure. Entries with a `negative_control` are re-run
against a deliberately broken DUT kept in `item9/negative_control/` (outside
`common/`) and must fail. Results (per run, plus excluded benches with reasons)
go to `item9/sim_build/result.json`.

Benches whose inputs are not in the stamp are listed as `not runnable: input
missing` rather than run with hand-written inputs; see `item9/INVENTORY.md`.
The item-9 attestation (`signoff/item9-inventory.json` ->
`signoff/item9-testbenches.json`) is regenerated with
`klt signoff --attest 9 --inventory verification/signoff/item9-inventory.json -o verification/signoff/item9-testbenches.json`
and `--check`ed in CI.

## Pinned toolchain

| Tool | Version | Where pinned |
|---|---|---|
| cocotb | 2.0.1 | `requirements.txt` |
| Icarus Verilog | 13.0 | CI builds this version (`verification.yml`); host-verified |
| Verilator | 5.050 (lint) | host-verified; CI installs the distro package and records its version |

cocotb 2.0.1 was run against Icarus 13.0 and Python 3.12.3 and works with
this harness. Every run writes `<test_dir>/sim_build/result.json` with
per-test pass/fail for each leg, the seed (`--seed N` reproduces it), the
cocotb/Icarus/Verilator/Python versions that actually ran, and the commit.

## Test directory convention

```
<test_dir>/test_NAME.py                    cocotb module
<test_dir>/NAME.v                          good DUT (toplevel NAME)
<test_dir>/negative_control/NAME_broken.v  broken DUT, same toplevel
```

`smoke/` is the reference instance. The negative control must be a DUT that
the tests are *expected to fail on*; never fix it.

## Wiring a vendored test

Vendored tests live under `common/<name>/` (see `common/README.md`). Because
their DUT is real RTL, point the runner at it instead of a local copy:

```sh
python3 verification/runner.py verification/common/<name> \
    --dut rtl/<file>.v --broken verification/common/<name>/negative_control/<file>_broken.v
```

`--module`, `--toplevel` override the `test_NAME` / `NAME` defaults. Add the
invocation to `.github/workflows/verification.yml` alongside the smoke step.

## RTL lint

`lint_rtl.sh [dir]` runs `verilator --lint-only -Wall` over every `.v`/`.sv`
under `rtl/` (or `dir`), except the vendored stamped copies in `rtl/common/`
(ADR-0002: not lint-gated; they are guarded by `spec/check_reuse_lock.py`, run in CI by the `reuse-lock` job of
`verification.yml` with a negative control that perturbs a copy). It
passes vacuously, with a printed note, while there is no other HDL, so it gates
the first RTL PR authored here.
