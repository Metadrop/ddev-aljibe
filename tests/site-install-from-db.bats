#!/usr/bin/env bats

# Unit tests for commands/host/site-install-from-db (deprecated wrapper).
#
# These tests do not need DDEV or Docker: the real script is executed with a
# fake `ddev` binary first in PATH that prints each argument in brackets.

setup() {
  set -eu -o pipefail
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-support

  # shellcheck disable=SC2155
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  SITE_INSTALL_FROM_DB_CMD="${DIR}/commands/host/site-install-from-db"

  STUB_DIR="$(mktemp -d)"
  cat > "${STUB_DIR}/ddev" <<'EOF'
#!/bin/bash
printf 'ddev'; printf ' [%s]' "$@"; printf '\n'
EOF
  chmod +x "${STUB_DIR}/ddev"
  export PATH="${STUB_DIR}:${PATH}"
}

teardown() {
  rm -rf "${STUB_DIR}"
}

@test "site-install-from-db passes a database file with spaces as one argument" {
  echo "-- dump" > "${STUB_DIR}/my dump.sql"
  run "${SITE_INSTALL_FROM_DB_CMD}" self "${STUB_DIR}/my dump.sql"
  assert_success
  assert_line "ddev [site-install] [self] [${STUB_DIR}/my dump.sql]"
}
