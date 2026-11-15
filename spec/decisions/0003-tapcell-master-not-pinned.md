# ADR-0003: The tapcell master stays tool-owned (`par.json` does not pin `library.tapcell`)

> This is **gf180-fpga's** ADR-0003. It is not `sky130-fpga`'s ADR-0003 — the
> sibling timing-claim-shape record cited as "ADR-0003" in
> `spec/porting-plan.md` and `spec/target-spec.md`. The local-vs-sibling
> numbering collision is a known ambiguity; resolving it repo-wide is out of
> scope here.

- **Status**: Accepted — ratified upon the merge of the pull request closing
  issue #93.
- **Date**: 2026-11-15
- **Related**: #93, #91 (via PR #94), #102, `layout/README.md` (tapcell
  provenance note), `layout/par.json`, `layout/records/step0-par.json`,
  `manifests/gf180-fpga.signoff.json`, `manifests/run-signoff.sh`,
  `flow/pdk.json` (`klt_spec`), `flow/klt.sh` (issue #55),
  klayout-tools#3051 (`power.tapcell` override), klayout-tools#4127
  (`library.tapcell: null`).

## Context

`layout/par.json` pins the tapcell *pitch* only (`power.tapcell.distance_um`:
24). The tap/endcap **masters** are resolved by klt from its per-cell-library
table, keyed on `pdk.cell_library` — for `gf180mcu_fd_sc_mcu7t5v0`,
`gf180mcu_fd_sc_mcu7t5v0__filltie` with endcap
`gf180mcu_fd_sc_mcu7t5v0__endcap`, table pitch 100 µm. klt 0.9.0 also accepts
`request.library.tapcell = {master, endcap|null, distance_um}`, which takes
precedence over the built-in table, so the request *could* hold the master.
The question was whether it should: is the master held by the request (by
construction) or attested by the response (committed records and manifests)?

## Decision

**Do not pin.** `layout/par.json` is unchanged: the request carries
`power.tapcell.distance_um: 24` and nothing else about the tap cells. The
masters continue to come from klt's table under the exact `klt_spec` pin
(`klayout-tools==0.9.0` in `flow/pdk.json`, run through a throwaway
`uvx --from` in `flow/klt.sh`), attested after the fact by the committed
evidence chain below. No P&R re-run is needed and none was taken: nothing
about the built tile changes.

Facts the decision rests on, verified against the pinned klt 0.9.0:

1. **Pitch precedence (AC: the two keys must not both be set).** Executing
   the pinned klt's own `_tapcell_lines` (klt 0.9.0,
   `place_and_route_script.py`): with `library.tapcell.distance_um: 100` and
   `power.tapcell.distance_um: 24` both supplied, the emitted Tcl is
   `tapcell -distance 24 …` — the `power` override wins whenever it is
   present, and `library.tapcell.distance_um` is read only when it is absent.
   So a request carrying both pitches contains a schema-required field that is
   provably never read.
2. **No silent arrival path.** Unlike the #55 exposure (which existed because
   `klayout` was *unpinned* and a new release silently moved every verdict),
   `klt_spec` is an exact `==` pin. A future klt cannot reach this repo at all
   without a reviewed `flow/pdk.json` edit, and such a bump requires a P&R
   re-run of its own.
3. **The master is already held by committed, CI-gated evidence.** It is
   attested in `layout/records/step0-par.json` (`power.tapcell_master` →
   `gf180mcu_fd_sc_mcu7t5v0__filltie`), re-derived into
   `manifests/gf180-fpga.signoff.json` item 11
   (`citation.power_delivery.tapcell_master`), and byte-compared by
   `manifests/run-signoff.sh --check` in CI. A bump that changed the table
   would surface the new master as diff lines in two committed records inside
   the bump PR, with CI red until both are regenerated.
4. **Table stability across the imminent bump.** The `gf180mcu_fd_sc_mcu7t5v0`
   entry is byte-identical in klt 0.9.0 and 0.9.2.dev (`("…filltie",
   "…endcap", 100)`), so #102's `klt_spec` bump carries no tap-cell change and
   neither issue depends on the other. (As of 2026-11-14; re-verify against
   whatever version #102 actually lands on.)

## Alternatives considered

- **Pin `library.tapcell` while keeping `power.tapcell.distance_um`.**
  Rejected: adds a schema-required field (`library.tapcell.distance_um`) that
  the `power` override makes inert — the same defect shape as the FILLTIE
  parameter #91 (PR #94) just removed.
- **Pin `library.tapcell` and delete `power.tapcell.distance_um`** (pin
  master + endcap + `distance_um: 24`, leaving exactly one pitch key).
  Rejected:
  - it duplicates PDK knowledge klt already owns, in a repo whose discipline
    (`CLAUDE.md`) is that what is re-derived here is device-level and
    physical, not what the master/tool owns;
  - it converts a silent-substitution risk (already closed by the exact pin
    plus the committed attestation chain) into a silent-**staleness** risk:
    if a future klt *corrects* the gf180mcu 7t entry, a pinned request keeps
    building with the stale master and nothing flags it, because request and
    response agree by construction — the risk class is moved, not removed,
    and the staleness direction has no detector;
  - it moves the measured 24 µm pitch out of `power.tapcell` — the key whose
    documented purpose is exactly this override (klayout-tools#3051) and
    whose measured rationale `layout/README.md` records — into a key meaning
    "the table value": doc and evidence churn for no change in the tile;
  - it costs a full PDK-host re-run of ladder step 0 plus re-attestation of
    the evidence citing the run — write-mode `run-signoff.sh` re-derives the
    item 1, 2, 9 and 10 envelopes (item 2 re-attested from the new stream)
    and item 11, a compound citation in `manifests/gf180-fpga.signoff.json`
    whose `power_delivery` names the resolved master, regenerates against
    the new records — to land a byte-identical layout.
- **Add a new check asserting the expected master against the record.**
  Rejected: a new mechanism where `manifests/run-signoff.sh --check` already
  byte-compares the derived citation.

## Consequences

- The tapcell master remains tool-owned under the exact `klt_spec` pin; the
  request holds only the measured pitch. A future klt correction to the
  gf180mcu 7t entry is *adopted* at the next deliberate bump, where it is
  visible as diff lines in `layout/records/step0-par.json` and the signoff
  manifest and gated by CI — adoption, not silent substitution.
- `layout/README.md`'s tapcell provenance note states this decision instead of
  pointing at the open question; issue #93 is resolved, not pending.
- The reasoning generalizes in spirit to the other `request.library` keys
  (`filler`, `antenna_diode`, `power_pins`, `wire_rc`, `cts_buffer`): do not
  pin what the tool owns while the exact `klt_spec` pin plus the committed
  attestation chain already hold it still, unless a concrete path by which a
  substitution reaches the repo is shown. Those keys are not changed here.
- Should a future issue decide to pin after all, it must be the one-pitch-key
  form (master + endcap + `distance_um` in `library.tapcell`,
  `power.tapcell.distance_um` deleted), re-run P&R on a PDK host, re-attest
  the records and manifests, and confirm the tile counts (58 tapcells, 54
  endcaps) are unchanged.
