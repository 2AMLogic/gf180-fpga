# Source this file; it defines report_path_rewrite(), the single path rewrite
# behind the record writers (flow/smoke/run-smoke.sh, flow/tile/run-synth.sh,
# layout/run-par.sh). A record is committed evidence: it carries repo-relative
# paths and a symbolic $PDK_ROOT only, never a host-absolute path.
#
# The PDK root is recognised first. The default install target is inside the
# checkout (flow/.pdk-root, flow/pdk-root.sh), so stripping the checkout prefix
# first also strips the head of a checkout-local PDK path, and the $PDK_ROOT
# substitution can no longer match: the record then carries a checkout-relative
# flow/.pdk-root/... path where an external PDK carries $PDK_ROOT/... (issue
# #205). Order, the prefix another one contains first:
#
#   1. <pdk_root>  -> $PDK_ROOT
#   2. <scratch>/  -> removed, where a scratch directory is given
#   3. <repo>/     -> removed
#
# The scratch prefix precedes the checkout prefix for the same reason: a
# scratch directory under the checkout would otherwise lose its head first.
#
# No local here=... below: this file is sourced, and each writer keeps its own.
# shellcheck shell=bash

# report_path_rewrite <repo> <pdk_root> [<scratch>] -- [<file>...]
#   <repo>      the checkout toplevel, as `git rev-parse --show-toplevel` prints it
#   <pdk_root>  the resolved $PDK_ROOT, canonicalised (`cd "$PDK_ROOT" && pwd`)
#   <scratch>   the per-run directory klt ran in, where there is one
#   Rewrites <file>s in place (sed -i); with no <file>, filters stdin to stdout.
#   Returns 2 and rewrites nothing when <repo> or <pdk_root> is empty: an empty
#   pattern would prefix every line of the record with $PDK_ROOT.
report_path_rewrite() {
  local repo="${1:-}" pdk_root="${2:-}" scratch="${3:-}"
  if [[ -z "$repo" || -z "$pdk_root" ]]; then
    echo "report_path_rewrite: <repo> and <pdk_root> are required" >&2
    return 2
  fi
  shift 2
  if [[ $# -gt 0 && "$1" != -- ]]; then scratch="$1"; shift; fi
  if [[ $# -gt 0 ]]; then
    if [[ "$1" != -- ]]; then
      echo "report_path_rewrite: expected -- before <file>s, got '$1'" >&2
      return 2
    fi
    shift
  fi
  local expr=( -e "s#$pdk_root#\$PDK_ROOT#g" )
  [[ -n "$scratch" ]] && expr+=( -e "s#$scratch/##g" )
  expr+=( -e "s#$repo/##g" )
  if [[ $# -eq 0 ]]; then sed "${expr[@]}"; else sed -i "${expr[@]}" "$@"; fi
}
