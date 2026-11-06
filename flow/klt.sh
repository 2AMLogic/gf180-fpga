# Source this file; it defines klt() and klt_bin_dir() from the single
# klayout-tools pin (klt_spec in flow/pdk.json), run through a throwaway uvx
# environment so the host klt is never used. Bump the pin in flow/pdk.json only.
KLT_SPEC="$(jq -er .klt_spec "$(dirname "${BASH_SOURCE[0]}")/pdk.json")" || return 1
klt() { uvx --quiet --from "$KLT_SPEC" klt "$@"; }
# bin dir of the pinned klt environment (holds its python)
klt_bin_dir() {
  uvx --quiet --from "$KLT_SPEC" python -I -c 'import os,sys;print(os.path.dirname(sys.executable))'
}
