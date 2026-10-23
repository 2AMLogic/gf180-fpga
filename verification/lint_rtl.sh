#!/usr/bin/env bash
# RTL lint entry point: verilator --lint-only -Wall over rtl/**/*.v and *.sv,
# excluding the vendored stamped copies under rtl/common/ (ADR-0002).
# Passes vacuously (with a note) while rtl/ holds no HDL, so it gates the
# first RTL PR. A missing verilator is an error, never a pass.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rtl="${1:-$repo/rtl}"

mapfile -t files < <(find "$rtl" -path "$rtl/common" -prune -o -type f \( -name '*.v' -o -name '*.sv' \) -print | sort)
if [ "${#files[@]}" -eq 0 ]; then
    echo "lint_rtl: no lintable .v/.sv files under $rtl (rtl/common excluded); passing vacuously"
    exit 0
fi

if ! command -v verilator >/dev/null 2>&1; then
    echo "lint_rtl: ERROR: verilator not found on PATH" >&2
    exit 2
fi

echo "lint_rtl: $(verilator --version)"
echo "lint_rtl: linting ${#files[@]} file(s)"
verilator --lint-only -Wall "${files[@]}"
echo "lint_rtl: clean"
