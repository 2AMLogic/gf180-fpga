# Source this file; it defines klt() and klt_bin_dir() from the single
# klayout-tools pin (klt_spec in flow/pdk.json), run through a throwaway uvx
# environment so the host klt is never used. Bump the pin in flow/pdk.json only.
#
# klayout_spec pins klt's KLayout engine too. klayout-tools records the engine
# version it was tested against and flags any other one as
# `provenance.klayout_version_mismatch: true`, warning that report counts may
# differ from a tested pairing. Left unpinned, uvx resolves whatever KLayout is
# newest on PyPI, so a release upstream would silently put every DRC/LVS/ERC
# verdict in this repo on an untested engine (issue #55: klayout 0.30.13 landed
# and did exactly that). Bump it together with klt_spec.
#
# No local here=... below: this file is sourced, and run-par.sh / run-lvs.sh /
# run-erc.sh / smoke/run-smoke.sh each keep their own `here`.
KLT_SPEC="$(jq -er .klt_spec "$(dirname "${BASH_SOURCE[0]}")/pdk.json")" || return 1
KLAYOUT_SPEC="$(jq -er .klayout_spec "$(dirname "${BASH_SOURCE[0]}")/pdk.json")" || return 1
klt() { uvx --quiet --from "$KLT_SPEC" --with "$KLAYOUT_SPEC" klt "$@"; }
# bin dir of the pinned klt environment (holds its python)
klt_bin_dir() {
  uvx --quiet --from "$KLT_SPEC" --with "$KLAYOUT_SPEC" python -I -c 'import os,sys;print(os.path.dirname(sys.executable))'
}
