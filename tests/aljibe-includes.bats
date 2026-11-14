#!/usr/bin/env bats

# Unit tests for helper functions in commands/host/includes/aljibe_includes.
#
# These tests do not need DDEV or Docker: the include file is sourced and its
# functions are called directly, with a fake `ddev` binary first in PATH that
# returns canned output.

setup() {
  set -eu -o pipefail
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-support

  # shellcheck disable=SC2155
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"

  STUB_DIR="$(mktemp -d)"
  export PATH="${STUB_DIR}:${PATH}"

  # shellcheck source=/dev/null
  source "${DIR}/commands/host/includes/aljibe_includes"
}

teardown() {
  rm -rf "${STUB_DIR}"
}

@test "get_all_installable_sites strips only the leading @ and trailing .local" {
  # No installable_sites_aliases in aljibe.yaml, so the drush alias list is used.
  cat > "${STUB_DIR}/ddev" <<'EOF'
#!/bin/bash
case "$*" in
  "drush site:alias "*) printf '%s\n' "@self.local" "@mylocalsite.local" "@site.localhost.local" ;;
esac
exit 0
EOF
  chmod +x "${STUB_DIR}/ddev"

  run get_all_installable_sites
  assert_success
  assert_output "self mylocalsite site.localhost"
}
