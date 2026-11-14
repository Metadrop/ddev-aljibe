#!/usr/bin/env bats

# Unit tests for commands/host/aljibe-kickstart.
#
# These tests do not need DDEV or Docker: the real script is executed against
# a temporary project with a fake `ddev` binary first in PATH.

setup() {
  set -eu -o pipefail
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-support
  bats_load_library bats-file

  # shellcheck disable=SC2155
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  KICKSTART_CMD="${DIR}/commands/host/aljibe-kickstart"

  WORK_DIR="$(mktemp -d)"
  STUB_DIR="${WORK_DIR}/bin"
  mkdir -p "${STUB_DIR}"
  export DDEV_CALLS_LOG="${WORK_DIR}/ddev-calls.log"
  : > "${DDEV_CALLS_LOG}"

  cat > "${STUB_DIR}/ddev" <<'EOF'
#!/bin/bash
echo "$*" >> "${DDEV_CALLS_LOG}"
EOF
  chmod +x "${STUB_DIR}/ddev"
  export PATH="${STUB_DIR}:${PATH}"

  # The project lives one level down so we can detect files leaking into its
  # parent directory.
  export DDEV_APPROOT="${WORK_DIR}/parent/project"
  local ks="${DDEV_APPROOT}/.ddev/kickstart"
  mkdir -p "${ks}/common/tests" "${ks}/d10" "${ks}/d11"
  echo "common" > "${ks}/common/.gitignore"
  echo "common" > "${ks}/common/phpunit.xml"
  echo "common" > "${ks}/common/tests/README.md"
  echo "d10" > "${ks}/d10/composer.json"
  echo "d11" > "${ks}/d11/composer.json"
}

teardown() {
  rm -rf "${WORK_DIR}"
}

# Emulate macOS: uname reports Darwin.
fake_macos_uname() {
  cat > "${STUB_DIR}/uname" <<'EOF'
#!/bin/bash
echo Darwin
EOF
  chmod +x "${STUB_DIR}/uname"
}

assert_kickstart_copied() {
  local expected_version="$1"
  assert_file_exists "${DDEV_APPROOT}/.gitignore"
  assert_file_exists "${DDEV_APPROOT}/phpunit.xml"
  assert_file_exists "${DDEV_APPROOT}/tests/README.md"
  run cat "${DDEV_APPROOT}/composer.json"
  assert_output "${expected_version}"
  # Only the contents of common/ and the version folder are copied: no
  # kickstart folders in the project root, nothing outside of it.
  assert_dir_not_exists "${DDEV_APPROOT}/common"
  assert_dir_not_exists "${DDEV_APPROOT}/d10"
  assert_dir_not_exists "${DDEV_APPROOT}/d11"
  run ls -A "${WORK_DIR}/parent"
  assert_output "project"
}

@test "aljibe-kickstart copies d11 files into the project root" {
  run "${KICKSTART_CMD}" -y
  assert_success
  assert_kickstart_copied d11
  run cat "${DDEV_CALLS_LOG}"
  assert_line "config --project-type=drupal11 --docroot=web"
}

@test "aljibe-kickstart d10 copies d10 files into the project root" {
  run "${KICKSTART_CMD}" -y d10
  assert_success
  assert_kickstart_copied d10
  run cat "${DDEV_CALLS_LOG}"
  assert_line "config --project-type=drupal10 --docroot=web"
}

@test "aljibe-kickstart on macOS (bash 3.2 globbing) copies only into the project root" {
  fake_macos_uname
  # bash < 5.2 (macOS ships 3.2) expands ".*" to "." and ".." as well;
  # disabling globskipdots reproduces that behaviour on newer bash.
  run bash +O globskipdots "${KICKSTART_CMD}" -y
  assert_success
  assert_kickstart_copied d11
}

@test "aljibe-kickstart prompt: n, N, no and No cancel without copying" {
  local answer
  for answer in n N no No; do
    run "${KICKSTART_CMD}" <<< "${answer}"
    assert_success
    assert_output --partial "Kickstart operation cancelled."
    assert_file_not_exists "${DDEV_APPROOT}/composer.json"
  done
  run cat "${DDEV_CALLS_LOG}"
  assert_output ""
}

@test "aljibe-kickstart prompt: Enter (default yes) copies the files" {
  run "${KICKSTART_CMD}" <<< ""
  assert_success
  refute_output --partial "Kickstart operation cancelled."
  assert_kickstart_copied d11
}
