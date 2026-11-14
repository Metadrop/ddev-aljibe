#!/usr/bin/env bats

# Unit tests for commands/web/behat.
#
# These tests do not need DDEV or Docker: the real script is executed with a
# fake `behat` binary first in PATH that prints each argument it receives on
# its own line.

setup() {
  set -eu -o pipefail
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-support

  # shellcheck disable=SC2155
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  BEHAT_CMD="${DIR}/commands/web/behat"

  STUB_DIR="$(mktemp -d)"
  cat > "${STUB_DIR}/behat" <<'EOF'
#!/bin/bash
printf 'ARG[%s]\n' "$@"
EOF
  chmod +x "${STUB_DIR}/behat"
  export PATH="${STUB_DIR}:${PATH}"
}

teardown() {
  rm -rf "${STUB_DIR}"
}

@test "behat passes options containing spaces as single arguments" {
  run "${BEHAT_CMD}" local --tags="@api and ~@wip" --name "My scenario"
  assert_success
  assert_output - <<'EOF'
ARG[--colors]
ARG[--config=/var/www/html/tests/behat/local/behat.yml]
ARG[--tags=@api and ~@wip]
ARG[--name]
ARG[My scenario]
EOF
}

@test "behat defaults to the local folder with no arguments" {
  run "${BEHAT_CMD}"
  assert_success
  assert_output - <<'EOF'
ARG[--colors]
ARG[--config=/var/www/html/tests/behat/local/behat.yml]
EOF
}
