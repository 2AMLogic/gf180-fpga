#!/usr/bin/env python3
"""Verify reuse.lock.json against the vendored files on disk.

Checks, for every entry: the file exists, its sha256 matches the lock, and its
git blob id equals the one recorded for the source commit. Also fails if a
file under rtl/common/ or verification/common/ is not listed (an unrecorded
vendored copy). With --source <sky130-fpga checkout>, also compares each
entry's blob id with `git rev-parse <commit>:<source_path>` in that checkout.

Usage: python3 -I spec/check_reuse_lock.py [--source PATH]
"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VENDORED_DIRS = ("rtl/common", "verification/common")


def git_blob_id(data: bytes) -> str:
    return hashlib.sha1(b"blob %d\0" % len(data) + data).hexdigest()


def main(argv):
    source = None
    if "--source" in argv:
        source = argv[argv.index("--source") + 1]
    lock = json.loads((ROOT / "reuse.lock.json").read_text())
    commit = lock["source"]["commit"]
    errors = []
    listed = set()
    for e in lock["files"]:
        listed.add(e["path"])
        p = ROOT / e["path"]
        if not p.is_file():
            errors.append(f"missing: {e['path']}")
            continue
        data = p.read_bytes()
        if hashlib.sha256(data).hexdigest() != e["sha256"]:
            errors.append(f"sha256 mismatch: {e['path']}")
        if git_blob_id(data) != e["source_blob"]:
            errors.append(f"blob id mismatch vs source: {e['path']}")
        if source:
            out = subprocess.run(
                ["git", "-C", source, "rev-parse", f"{commit}:{e['source_path']}"],
                capture_output=True, text=True)
            if out.stdout.strip() != e["source_blob"]:
                errors.append(f"source blob differs at {commit[:12]}: {e['source_path']}")
    for d in VENDORED_DIRS:
        for p in sorted((ROOT / d).rglob("*")):
            rel = p.relative_to(ROOT).as_posix()
            if p.is_file() and rel not in listed and not rel.endswith("README.md"):
                errors.append(f"unlisted vendored file: {rel}")
    for err in errors:
        print("FAIL", err)
    print(f"{len(lock['files'])} entries checked, {len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
