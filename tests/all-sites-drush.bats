#!/usr/bin/env bats

# Unit tests for commands/host/all-sites-drush.
#
# These tests do not need DDEV or Docker: the real script is executed in a
# temporary project with two drush site alias files, and a fake `ddev` binary
# first in PATH that prints every call with each argument in brackets.

setup() {
  set -eu -o pipefail
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-support

  # shellcheck disable=SC2155
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  ALL_SITES_DRUSH_CMD="${DIR}/commands/host/all-sites-drush"

  WORK_DIR="$(mktemp -d)"
  mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/project/drush/sites"
  touch "${WORK_DIR}/project/drush/sites/self.site.yml" \
        "${WORK_DIR}/project/drush/sites/second.site.yml"

  cat > "${WORK_DIR}/bin/ddev" <<'EOF'
#!/bin/bash
printf 'ddev'; printf ' [%s]' "$@"; printf '\n'
EOF
  chmod +x "${WORK_DIR}/bin/ddev"
  export PATH="${WORK_DIR}/bin:${PATH}"
  cd "${WORK_DIR}/project"
}

teardown() {
  rm -rf "${WORK_DIR}"
}

@test "all-sites-drush passes arguments with spaces intact to every site" {
  run "${ALL_SITES_DRUSH_CMD}" sqlq "SELECT 1"
  assert_success
  assert_line "ddev [drush] [@self.local] [sqlq] [SELECT 1]"
  assert_line "ddev [drush] [@second.local] [sqlq] [SELECT 1]"
}

@test "all-sites-drush fails when no drush command is given" {
  run "${ALL_SITES_DRUSH_CMD}"
  assert_failure
  assert_output --partial "Please provide a drush command"
  refute_output --partial "ddev ["
}
