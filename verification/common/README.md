# verification/common

Stamped copies of the plain-Verilog, self-checking testbenches and committed
bitstream fixtures vendored from `sky130-fpga` via `reuse.lock.json`
(`mode: vendored`). Do not edit them in place; a divergence needs a decision
record. `spec/check_reuse_lock.py` guards byte identity.

- `tb_*.v` -- eleven benches. Each prints `PASS: ...` or `FAIL: ...` and
  `$finish`es; none uses cocotb. Some take plusargs (`+bin= +map= +wiring=
  +design=`, or `+dir= +list= +wiring= +map=`).
- `bitstream/` -- the configuration map (`logic4_configmem.map`), the
  `top_io`/`top_reg` fixtures and `corpus/` (frame streams `.bin`, `.wiring`
  manifests and `index.txt`, which maps each case to its `+design=`).
- `switch_matrix_tb_gen.vh` -- table included by `tb_switch_matrix.v`.

They are run by `verification/runner.py --vvp`, driven by
`verification/item9/benches.json`; see `../README.md` and
`../item9/INVENTORY.md` for what runs and what cannot (missing stamped inputs).
