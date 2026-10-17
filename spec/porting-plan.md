# Porting plan: `sky130-fpga` → gf180mcu

- **Status**: Accepted with `spec/decisions/0001-ratify-target-spec.md`.
- **Date**: 2026-10-17
- **Issue**: #2

This repo is a port, not a new design. The architecture is the constant and
the PDK is the variable. This document says exactly what is inherited, what is
copied, and what is re-derived, and pins every read of the sibling repo to a
commit.

## Sibling reads

Every statement about `2AMLogic/sky130-fpga` below was read from this commit
(`main` on 2026-10-17, via `gh api` and a detached checkout):

| Repo | Commit (full SHA) |
|---|---|
| `2AMLogic/sky130-fpga` | `42a8db00e138aa892a388b077a8ae2ea2ccab511` |

Issue #2 was written against `bf673ae65ed58221c6d2b896c3e2fed58f394702`;
`main` had moved by the time of this read, and the newer commit is the one
vendored and cited. Files read there: `spec/tile-spec.md`,
`spec/framework-gaps.md`, `spec/decisions/0001`–`0006`, `spec/tile-spec.json`,
the tile RTL and FABulous description under `design/`, `flow/` (read, not
copied) and `sim/`.

This repo's own base is `main` @ `88ab5c8`.

## Inherit unchanged (cited, not re-argued)

| Item | Sibling source | Status at `42a8db0` |
|---|---|---|
| Tile architecture: 4× LUT4, 1 FF per LUT (output-only), no carry in v1, 4 general-purpose tracks per edge, single tile type, 2×2 to 4×4 demonstration fabric, open FABulous-generated bitstream | `spec/tile-spec.md` (summary table) | The document itself is marked **Draft**; only its switch-matrix track count and timing rows are marked ratified. Inherited as the architectural intent. |
| Framework choice: FABulous tile/fabric description format | ADR-0001 | Accepted |
| Scope rules (tile is the scope; fabric growth, new tile types and wider routing are declined) | `CLAUDE.md`, `spec/tile-spec.md` "Out of scope" | In force here via this repo's `CLAUDE.md` |
| Timing *claim shape* (setup/hold-clean at every library corner at a stated period; no Fmax unless bisected from characterized data) | ADR-0002, ADR-0003 | `Proposed — ratified upon this PR merging`. Only the shape is inherited; **no number** is. |
| G1 tile-description discrepancies | ADR-0004 | **Proposed** — pending operator ratification at `42a8db0` |
| IO and constant handling for the nextpnr flow | ADR-0005 | **Proposed** — pending operator ratification at `42a8db0` |
| LUT pin-assignment policy | ADR-0006 | **Proposed** — pending operator ratification at `42a8db0` |

ADRs 0004–0006 are inherited **as Proposed**. This port makes no decision on
them; any vendored file whose behavior depends on them (the same-index
stand-in matrix, the harness pad overlay, the pin policy) carries that status
with it.

## Stamp (vendored copies)

`reuse.lock.json` (`mode: vendored`) records the source commit, each file's
source path, git blob id and sha256. `spec/check_reuse_lock.py` re-verifies
all of it, and with `--source <sky130-fpga checkout>` also checks the blob ids
against the sibling at the pinned commit. A vendored file diverges from its
source only with a decision record.

| Sibling path | Path here | Files | Contents |
|---|---|---|---|
| `design/rtl/*.v` | `rtl/common/rtl/` | 4 | `lut4_slice`, `logic_tile`, `logic_tile_switch_matrix`, `logic_tile_routed` |
| `design/fabulous/` (minus logs and `*results.txt`) | `rtl/common/fabulous/` | 51 | `fabric.csv`, `FABulous.tcl`, `Tile/{LOGIC4,CAP_*}`, `Fabric/models_pack.v`, `nextpnr/` mapping and top files, `corpus/` sources and constraints, `tb_*_equiv.v` |
| `design/gen/gen_switch_matrix.py` | `rtl/common/gen/` | 1 | switch-matrix RTL generator |
| `sim/tb_*.v`, `sim/switch_matrix_tb_gen.vh` | `verification/common/` | 12 | self-checking and bitstream-level testbenches |
| `sim/bitstream/**` | `verification/common/bitstream/` | 105 | committed bitstream fixtures, `fabric_spec.json`, config-memory map, pin experiment |

Path mapping (`design/` and `sim/` in the sibling; `rtl/common/` and
`verification/common/` here, the latter reserved by #4):

| Sibling | Here |
|---|---|
| `design/rtl/` | `rtl/common/rtl/` |
| `design/fabulous/` | `rtl/common/fabulous/` |
| `design/gen/` | `rtl/common/gen/` |
| `sim/*.v`, `sim/*.vh` | `verification/common/` |
| `sim/bitstream/` | `verification/common/bitstream/` |

The copied sources contain no sky130 reference (grepped at the pinned
commit). Comments inside vendored files still use the sibling's paths; they are
not edited.

**Deliberately not copied**, with the reason:

- `design/netlist/logic_tile_netlist.v`, `layout/`, `measurements/`: outputs
  of the sky130 physical flow, i.e. sibling evidence. Not valid for gf180mcu.
- `design/fabulous/generator.log`, `nextpnr.log`, and every `*results.txt`
  and `sim/*_results.txt`: recorded results of sibling runs. Results here are
  append-only evidence from this repo's own runs.
- `design/README.md`, `design/bitstream-format.md`: documentation; cited at the
  pinned commit rather than copied.
- `flow/`: the sibling's scripts. Several are PDK-independent but the
  testbenches depend on a few of them (see "Known gaps" below). Taking them is
  a decision for #4 (harness), not this issue.

## Re-derive on gf180mcu

| Item | Why it does not transfer | Where it is decided |
|---|---|---|
| Standard-cell library and track height | Different library family | `target-spec.md` rows 1 |
| Supply flavour | `mcu*5v0` libraries ship three nominal supplies | row 2 |
| Metal-stack option and switch-matrix layers | PDK variants A–D differ in routing layers | row 3 |
| Tile placement and routing | New physical design | later issue |
| Physical switch-matrix routing pitch (sibling G3) | Pitch is set by gf180mcu rules | later issue, input in row 3 |
| DRC/LVS signoff (sibling G3) | New rule decks | row 7 |
| Timing characterization at the library corners (sibling G4) | No sky130 number transfers | rows 5–6 |

## Open questions: where they land

1. **Does the pinned FABulous release generate a gf180mcu fabric out of the
   box?** Not run in this issue. The vendored description is PDK-independent
   text (no PDK reference in any copied file), and the generator emits
   RTL/model files rather than cells, so no PDK-specific change is expected.
   Confirming needs a generator run, which belongs with the harness work (#4).
   Deferred; any change to a vendored file needs a decision record. See
   ADR 0001 here.
2. **Will the 4-track switch matrix route on the chosen stack?** Cannot be
   answered by a spec. Deferred with a named experiment and fallback ladder in
   `target-spec.md` ("Routing-closure fallback ladder").
3. **What does the sibling's status mean for what this port can claim?** See
   "Inherited open gaps" below.

## Inherited open gaps (sibling status at `42a8db0`)

The sibling's `spec/framework-gaps.md` states: tile RTL implemented and
BEL-level tested; BEL-only layout DRC/LVS-clean; BEL timing characterized;
bitstream-level verification of the ratified fabric **not done** (only an
experimental single-tile harness test exists, on a same-index stand-in matrix
with ADR-0004/0005 Proposed); the composed-tile layout, DRC/LVS/ERC and STA are
**experimental observations, not signoff**; the SDF-annotated gate-level
re-simulation leg is blocked on a klayout-tools defect. G5 (bitstream-level
functional verification of the ratified fabric, inter-tile routing) and G6
(bitstream format documentation) are not closed.

Consequences for this repo:

- The vendored tile RTL and tests are inputs, not a verified result. **No
  functional claim is made here** until bitstream-level tests pass in this
  repo's own harness.
- The vendored switch matrix is the sibling's stand-in (same-index) matrix,
  not the Wilton-class population `tile-spec.md` describes. The 4-track
  architectural row is inherited; whether the *final* matrix is denser is
  sibling-owned, and any change to it comes back as a new stamped copy.
- Findings that bear on the master (description defects, test gaps) are filed
  on `sky130-fpga`, not fixed here.

## Known gaps in the stamped set

The vendored testbenches reference sibling files that are not vendored:
`flow/gate_sim_verdict.sh`, `flow/ctrl_route.py`, `flow/configmem_frames.py`,
`flow/fasm_to_bitstream.py` and `sim/run.sh` (some are named only in
comments, some are used to generate plusarg inputs). Whether they run here is
#4's concern; they were not copied because the harness layout is #4's to
define.
