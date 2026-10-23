# spec

- [`target-spec.md`](target-spec.md) — the ratified target table, corners and
  routing-closure ladder.
- [`porting-plan.md`](porting-plan.md) — inherit / stamp / re-derive from
  `sky130-fpga`, pinned to a full commit SHA.
- [`decisions/`](decisions/) — decision records.
- [`check_reuse_lock.py`](check_reuse_lock.py) — verifies `reuse.lock.json`
  against the vendored files (`python3 -I spec/check_reuse_lock.py
  [--source <sky130-fpga checkout>]`).
