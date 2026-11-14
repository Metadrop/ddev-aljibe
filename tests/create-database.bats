#!/usr/bin/env bats

# Unit tests for commands/db/create-database.
#
# These tests do not need DDEV or Docker: the real script is executed with a
# fake `mysql` binary first in PATH that prints the SQL passed with -e.

setup() {
  set -eu -o pipefail
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-support

  # shellcheck disable=SC2155
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  CREATE_DATABASE_CMD="${DIR}/commands/db/create-database"

  STUB_DIR="$(mktemp -d)"
  cat > "${STUB_DIR}/mysql" <<'EOF'
#!/bin/bash
while [ $# -gt 0 ]; do
  if [ "$1" = "-e" ]; then echo "SQL: $2"; shift; fi
  shift
done
EOF
  chmod +x "${STUB_DIR}/mysql"
  export PATH="${STUB_DIR}:${PATH}"
}

teardown() {
  rm -rf "${STUB_DIR}"
}

@test "create-database quotes the name as a MySQL identifier" {
  run "${CREATE_DATABASE_CMD}" my-db_2
  assert_success
  # shellcheck disable=SC2016 # literal backticks: MySQL identifier quoting.
  assert_line 'SQL: CREATE DATABASE IF NOT EXISTS `my-db_2`; GRANT ALL ON `my-db_2`.* TO '"'db'@'%';"
}

@test "create-database fails without a database name and runs no SQL" {
  run "${CREATE_DATABASE_CMD}"
  assert_failure
  refute_output --partial "SQL:"
}

@test "create-database rejects names that would inject SQL" {
  run "${CREATE_DATABASE_CMD}" "x; DROP DATABASE db; --"
  assert_failure
  assert_output --partial "Invalid database name"
  refute_output --partial "SQL:"
}
