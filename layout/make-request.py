#!/usr/bin/env python3
"""Emit a `klt place-and-route` request for the tile at a given core size.

usage: make-request.py OUT.json NETLIST_REL CELL_LIB SITE PRESET FILLTIE \
           SITE_W SITE_H NCOLS NROWS

The core is NCOLS sites wide and NROWS rows high, offset by one tapcell-sized
margin (5.6 x row-height um) on each side.  Pin placement:

* n_out[*] faces s_in[*] and n_in[*] faces s_out[*] (same x window, same
  ordering), e_out/w_in and e_in/w_out likewise on the E/W edges, so a tile
  abuts its neighbour with matching positions on opposite edges.
* the 158 cfg bits and clk sit in the outer bands of the edges.  A band on one
  edge is mirrored by a free band on the opposite edge, so cfg pins of
  abutting tiles never land on the same coordinate.
"""
import json
import sys

out, netlist, lib, site, preset, filltie = sys.argv[1:7]
sw, sh = float(sys.argv[7]), float(sys.argv[8])
ncols, nrows = int(sys.argv[9]), int(sys.argv[10])
mx, my = 5.6, sh
core = [mx, my, round(mx + ncols * sw, 4), round(my + nrows * sh, 4)]
die = [0, 0, round(core[2] + mx, 4), round(core[3] + my, 4)]
W, H = die[2], die[3]


def win(total, frac_lo, frac_hi):
    return [round(total * frac_lo, 2), round(total * frac_hi, 2)]


def bus(name, lo, hi):
    return [f"{name}[{i}]" for i in range(lo, hi + 1)]


cons = []
# Fractions of the edge length.  Pin slots are ~1.12 um apart (klt/OpenROAD
# PPL), so the cfg bands are sized for their pin count.  Signal windows are the
# same on opposite edges (out<->in mirrored) and the clk sits in the gap that
# no opposite edge uses, so abutting tiles never put two pins on one slot.
PITCH = 1.12  # pin-slot pitch (2 x 0.56 um tracks), slots sit at (k + 0.5) * PITCH


def sig(pins, edge, length, lo, hi):
    # Window exactly 4 slots wide, centred on the slot lattice, so the ordered
    # group lands on the same 4 slots on both edges (hi is kept only to keep
    # the call sites readable: the window starts at `lo`).
    k = round(length * lo / PITCH - 0.5)
    x0 = (k + 0.5) * PITCH - 0.3
    return {"pins": pins, "edge": edge, "range_um": [round(x0, 2), round(x0 + 3 * PITCH + 0.6, 2)], "ordered": True}


cons += [
    sig(bus("n_out", 0, 3), "north", W, .45, .51),
    sig(bus("s_in", 0, 3), "south", W, .45, .51),
    sig(bus("n_in", 0, 3), "north", W, .53, .59),
    sig(bus("s_out", 0, 3), "south", W, .53, .59),
    sig(bus("e_out", 0, 3), "east", H, .45, .51),
    sig(bus("w_in", 0, 3), "west", H, .45, .51),
    sig(bus("e_in", 0, 3), "east", H, .53, .59),
    sig(bus("w_out", 0, 3), "west", H, .53, .59),
    # cfg 42 + 38 + 42 + 36: low band on N/E, high band on S/W.
    {"pins": bus("cfg", 0, 41), "edge": "north", "range_um": win(W, .02, .44)},
    {"pins": bus("cfg", 42, 79), "edge": "south", "range_um": win(W, .60, .98)},
    {"pins": bus("cfg", 80, 121), "edge": "east", "range_um": win(H, .02, .44)},
    {"pins": bus("cfg", 122, 157), "edge": "west", "range_um": win(H, .60, .98)},
    {"pins": ["clk"], "edge": "south", "range_um": win(W, .512, .528)},
]

req = {
    "schema": "klt.place_and_route.request/1",
    "engine": "openroad",
    "netlist": netlist,
    "hdl_toplevel": "logic_tile_routed",
    "pdk": {"cell_library": lib, "corner": "tt_025C_5v00"},
    "floorplan": {
        "method": "explicit",
        "die_area_um": die,
        "core_area_um": core,
        "site": site,
    },
    "io": {"layer_h": "Metal3", "layer_v": "Metal2", "pin_constraints": cons},
    "power": {
        "preset": preset,
        "power_net": "VDD",
        "ground_net": "VSS",
        "tapcell": {"distance_um": 40},
    },
    "constraints": {"clock_port": "clk", "clock_period_ns": 20.0},
    "seed": 1,
    "target_stage": "route",
}
with open(out, "w") as f:
    json.dump(req, f, indent=2)
    f.write("\n")
print(f"{out}: die {W} x {H}, core {core[2]-core[0]:.2f} x {core[3]-core[1]:.2f}")
