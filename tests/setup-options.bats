#!/usr/bin/env bats

# Unit tests for option parsing in commands/host/setup.
#
# These tests do not need DDEV or Docker: the real setup script is executed
# with a fake `ddev` binary first in PATH that just records every call it
# receives. Assertions are made against that call log.

setup() {
  set -eu -o pipefail
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-support

  # shellcheck disable=SC2155
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  SETUP_CMD="${DIR}/commands/host/setup"

  STUB_DIR="$(mktemp -d)"
  export DDEV_CALLS_LOG="${STUB_DIR}/ddev-calls.log"
  : > "${DDEV_CALLS_LOG}"

  # Fake ddev: log the arguments of every call and succeed. It prints nothing,
  # except for `aljibe-config default_site`, which prints $STUB_DEFAULT_SITE
  # (empty by default, like aljibe-config does for a missing key).
  cat > "${STUB_DIR}/ddev" <<'EOF'
#!/bin/bash
echo "$*" >> "${DDEV_CALLS_LOG}"
case "$*" in
  "aljibe-config default_site") echo "${STUB_DEFAULT_SITE:-}" ;;
esac
EOF
  chmod +x "${STUB_DIR}/ddev"

  export PATH="${STUB_DIR}:${PATH}"
  # Make star_project() believe the project is already running.
  export DDEV_PROJECT_STATUS=running
}

teardown() {
  rm -rf "${STUB_DIR}"
}

@test "setup --sites=a,b (equals form) installs both sites" {
  run "${SETUP_CMD}" --no-themes --sites=site1,site2
  assert_success
  run grep -c '^site-install ' "${DDEV_CALLS_LOG}"
  assert_output "2"
  run cat "${DDEV_CALLS_LOG}"
  assert_line "site-install site1"
  assert_line "site-install site2"
}

@test "setup --sites a,b (space form) installs both sites" {
  run "${SETUP_CMD}" --no-themes --sites site1,site2
  assert_success
  run grep -c '^site-install ' "${DDEV_CALLS_LOG}"
  assert_output "2"
  run cat "${DDEV_CALLS_LOG}"
  assert_line "site-install site1"
  assert_line "site-install site2"
}

@test "setup --themes=a,b (equals form) builds only those themes" {
  run "${SETUP_CMD}" --no-install --themes=theme1,theme2
  assert_success
  run cat "${DDEV_CALLS_LOG}"
  assert_line "frontend production theme1"
  assert_line "frontend production theme2"
  refute_line "aljibe-config theme_paths --keys"
}

@test "setup --themes a,b (space form) builds only those themes" {
  run "${SETUP_CMD}" --no-install --themes theme1,theme2
  assert_success
  run cat "${DDEV_CALLS_LOG}"
  assert_line "frontend production theme1"
  assert_line "frontend production theme2"
  refute_line "aljibe-config theme_paths --keys"
}

@test "setup installs 'self' when no default_site is configured" {
  run "${SETUP_CMD}" --no-themes
  assert_success
  run cat "${DDEV_CALLS_LOG}"
  assert_line "site-install self"
}

@test "setup installs the configured default_site" {
  export STUB_DEFAULT_SITE=mysite
  run "${SETUP_CMD}" --no-themes
  assert_success
  run cat "${DDEV_CALLS_LOG}"
  assert_line "site-install mysite"
}
