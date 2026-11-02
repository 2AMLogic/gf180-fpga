#!/usr/bin/env python3
"""2x2 abutment check of the routed tile with `klt interface-check`.

interface-check pairs labels of A and B that carry the SAME name, but a tile
mates complementary pins (A.n_out with B.s_in).  So for each seam this script
writes a copy of the neighbour with the facing pins renamed to the names they
mate with, then runs interface-check with the neighbour placed one tile pitch
over.  The tile itself is untouched.

usage (run with the klt interpreter so `pya` is importable):
  abut-check.py TILE.gds OUT_DIR  ->  prints one JSON record
"""
import json
import os
import subprocess
import sys

import pya

gds, outdir = sys.argv[1:3]
os.makedirs(outdir, exist_ok=True)
lay = pya.Layout()
lay.read(gds)
top = lay.top_cell()
bb = top.bbox()
dbu = lay.dbu
W, H = bb.width() * dbu, bb.height() * dbu


def renamed(pairs, path):
    """Copy of the layout whose labels `src` are renamed to `dst`; the
    labels whose names would collide are dropped first."""
    l2 = pya.Layout()
    l2.read(gds)
    t2 = l2.top_cell()
    drop = set(pairs.values())
    for li in l2.layer_indexes():
        shapes = t2.shapes(li)
        for s in [s for s in shapes.each() if s.is_text()]:
            name = s.text_string
            if name in drop:
                shapes.erase(s)
            elif name in pairs:
                s.text_string = pairs[name]
    l2.write(path)


def sides(axis):
    if axis == "ns":  # B above A
        pairs = {f"s_in[{i}]": f"n_out[{i}]" for i in range(4)}
        pairs.update({f"s_out[{i}]": f"n_in[{i}]" for i in range(4)})
        return pairs, f"0,{H:g}", r"n_(in|out)\[\d\]"
    pairs = {f"w_in[{i}]": f"e_out[{i}]" for i in range(4)}  # B right of A
    pairs.update({f"w_out[{i}]": f"e_in[{i}]" for i in range(4)})
    return pairs, f"{W:g},0", r"e_(in|out)\[\d\]"


rec = {"tile_gds": gds, "tile_w_um": W, "tile_h_um": H, "seams": {}}
for axis in ("ns", "ew"):
    pairs, place, regex = sides(axis)
    b = os.path.join(outdir, f"neighbour-{axis}.gds")
    renamed(pairs, b)
    p = subprocess.run(
        ["klt", "interface-check", "--place", place, "--pins", regex,
         "--format", "json", gds, b],
        capture_output=True, text=True)
    try:
        res = json.loads(p.stdout)
    except ValueError:
        res = {"raw": p.stdout, "stderr": p.stderr}
    rec["seams"][axis] = {"place_um": place, "pins_regex": regex,
                          "exit": p.returncode, "result": res}
print(json.dumps(rec, indent=2))
