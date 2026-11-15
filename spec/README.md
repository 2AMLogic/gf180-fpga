# spec

- [`target-spec.md`](target-spec.md) — the ratified target table, corners and
  routing-closure ladder.
- [`porting-plan.md`](porting-plan.md) — inherit / stamp / re-derive from
  `sky130-fpga`, pinned to a full commit SHA.
- [`decisions/`](decisions/) — decision records.
- [`check_reuse_lock.py`](check_reuse_lock.py) — verifies `reuse.lock.json`
  against the vendored files (`python3 -I spec/check_reuse_lock.py
  [--source <sky130-fpga checkout>]`).

## Citing decision records

`spec/decisions/` here and `sky130-fpga`'s `spec/decisions/` share one
citation namespace, so references carry the repo they mean:

- Bare `ADR-NNNN` — and a bare `spec/decisions/NNNN…` path — cites **this
  repo's** record under `spec/decisions/`.
- A sibling record names the sibling repo: `` `sky130-fpga` ADR-NNNN ``. So
  `` `sky130-fpga` ADR-0001 `` is the framework-choice record there, a
  different record from this repo's `0001`; for a sibling path the repo name
  sits immediately before it. One qualifier covers every record number in
  the run that follows it (`` `sky130-fpga` ADR-0002, ADR-0003 `` names two
  sibling records).
- Vendored files under `rtl/common/` and `verification/common/` are
  `sky130-fpga`'s own text, held byte-identical by `reuse.lock.json`; they
  keep the sibling's citation usage and are exempt from this convention.
