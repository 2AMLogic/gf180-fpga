# ADR-0002: Vendored RTL under `rtl/common/` is not lint-gated

- **Status**: Accepted — ratified upon the merge of the pull request closing
  issue #2.
- **Date**: 2026-10-17
- **Related**: #2, #7, ADR-0001, `reuse.lock.json`, `verification/lint_rtl.sh`.

## Context

`verification/lint_rtl.sh` runs one `verilator --lint-only -Wall` invocation
over every `.v`/`.sv` under `rtl/`. Once `rtl/common/` is stamped in, that
includes the sibling's FABulous corpus, where each file is a standalone
nextpnr design defining its own `top`. One invocation over them fails with
`MODDUP` (duplicate module `top`), so the gate cannot pass. Vendored files may
not be edited to satisfy a linter (`CLAUDE.md`, ADR-0001).

## Decision

`lint_rtl.sh` excludes `rtl/common/`. Vendored copies are guarded by
`spec/check_reuse_lock.py` (byte identity with the pinned source commit), not
by lint. RTL authored in this repo, outside `rtl/common/`, stays under
`verilator --lint-only -Wall`.

## Alternatives considered

- **Lint each vendored design separately**: needs a per-design top list and
  waivers for sibling-authored warnings we cannot fix here; deferred until a
  vendored design is actually integrated and a lint finding bears on the master
  (file it on `sky130-fpga`).
- **Waive warnings or edit vendored files**: rejected; breaks the stamped-copy
  rule.

## Consequences

- Lint defects in vendored RTL are not caught here; they are the master's to
  find. Functional claims still come from bitstream-level tests.
- Any RTL moved out of `rtl/common/` into repo-owned paths becomes lint-gated.
