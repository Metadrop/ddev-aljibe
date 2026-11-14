#!/usr/bin/env bats

# Unit tests for commands/host/site-install.
#
# These tests do not need DDEV or Docker: the real site-install script is
# executed with a fake `ddev` binary first in PATH that records every call it
# receives and answers a few drush calls with canned output.

setup() {
  set -eu -o pipefail
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-support

  # shellcheck disable=SC2155
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  SITE_INSTALL_CMD="${DIR}/commands/host/site-install"

  STUB_DIR="$(mktemp -d)"
  export DDEV_CALLS_LOG="${STUB_DIR}/ddev-calls.log"
  : > "${DDEV_CALLS_LOG}"

  # Fake ddev: log every call. Aliases starting with @remote. are reported as
  # remote by `drush sa --fields=host`. `drush status` reports the alias as not
  # found, so the script stops right after the alias checks.
  cat > "${STUB_DIR}/ddev" <<'EOF'
#!/bin/bash
echo "$*" >> "${DDEV_CALLS_LOG}"
case "$*" in
  "drush sa --fields=host @remote."*) echo "host: remote.example.com" ;;
  "drush "*" status"*) echo "The alias $2 could not be found." >&2; exit 1 ;;
esac
exit 0
EOF
  chmod +x "${STUB_DIR}/ddev"

  export PATH="${STUB_DIR}:${PATH}"
  # Make star_project() believe the project is already running.
  export DDEV_PROJECT_STATUS=running
  export DDEV_APPROOT="${STUB_DIR}"
  cd "${STUB_DIR}"
}

teardown() {
  rm -rf "${STUB_DIR}"
}

@test "site-install refuses a remote alias and never drops its database" {
  run "${SITE_INSTALL_CMD}" remote.prod
  assert_failure
  assert_output --partial "seems a remote alias"
  run cat "${DDEV_CALLS_LOG}"
  refute_line --partial "sql:drop"
}

@test "site-install does not treat a local alias as remote" {
  run "${SITE_INSTALL_CMD}" mysite
  refute_output --partial "seems a remote alias"
  run cat "${DDEV_CALLS_LOG}"
  assert_line "drush @mysite.local sql:drop -y"
}
