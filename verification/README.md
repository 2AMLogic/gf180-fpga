# verification

`common/` holds stamped copies of the bitstream-level testbenches and committed
bitstream fixtures from `sky130-fpga`, listed with commit and sha256 in
`../reuse.lock.json`. Do not edit them. No result is recorded here yet.

cocotb + Icarus Verilog testbench harness. The tile's functional claims
(bitstream-level tests on the simulated fabric) run on this harness once #2's
stamped tests land in `common/`; until then it carries a smoke test and its
negative control. Shape follows `2AMLogic/gf180-tmds-tx` `verification/tmds_encoder/`.

## Cold start (fresh clone)

```sh
python3 -m venv .venv && . .venv/bin/activate
pip install -r verification/requirements.txt
python3 verification/runner.py verification/smoke   # smoke + negative control
verification/lint_rtl.sh                            # RTL lint
```

Prerequisites on `PATH`: Icarus Verilog (`iverilog`), Verilator (lint only).
The runner exits 0 only if the good DUT passes **and** the negative control
fails. A missing simulator is an error (exit 2), never a pass.

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
under `rtl/` (or `dir`). It passes vacuously, with a printed note, while there
is no HDL, so it gates the first RTL PR.
