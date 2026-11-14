#!/usr/bin/env bats

# Unit tests for commands/web/frontend.
#
# These tests do not need DDEV: the real script runs with
# - a `yq` wrapper first in PATH that points /mnt/ddev_config/aljibe.yaml to a
#   test file and runs the real mikefarah yq v4 (as in the DDEV web container),
#   either a local binary or the mikefarah/yq:4 Docker image;
# - a fake `npm` that logs the directory it runs in.
# Tests are skipped when mikefarah yq v4 is not available.

setup() {
  set -eu -o pipefail
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-support

  # shellcheck disable=SC2155
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  FRONTEND_CMD="${DIR}/commands/web/frontend"

  WORK_DIR="$(mktemp -d)"
  mkdir -p "${WORK_DIR}/bin"
  export ALJIBE_YAML="${WORK_DIR}/aljibe.yaml"
  export NPM_LOG="${WORK_DIR}/npm.log"
  : > "${NPM_LOG}"

  local real_yq
  real_yq="$(command -v yq || true)"
  if [ -n "${real_yq}" ] && "${real_yq}" --version 2>&1 | grep -q mikefarah; then
    export YQ_RUNNER="${real_yq}"
  elif command -v docker >/dev/null && docker image inspect mikefarah/yq:4 >/dev/null 2>&1; then
    export YQ_RUNNER="docker run --rm -v ${WORK_DIR}:${WORK_DIR} mikefarah/yq:4"
  else
    skip "mikefarah yq v4 not available"
  fi

  cat > "${WORK_DIR}/bin/yq" <<'EOF'
#!/bin/bash
args=()
for arg in "$@"; do
  [ "$arg" = /mnt/ddev_config/aljibe.yaml ] && arg="${ALJIBE_YAML}"
  args+=("$arg")
done
# shellcheck disable=SC2086 # YQ_RUNNER may be a multi-word docker command.
exec ${YQ_RUNNER} "${args[@]}"
EOF
  cat > "${WORK_DIR}/bin/npm" <<'EOF'
#!/bin/bash
echo "npm $* in ${PWD}" >> "${NPM_LOG}"
EOF
  chmod +x "${WORK_DIR}/bin/yq" "${WORK_DIR}/bin/npm"
  export PATH="${WORK_DIR}/bin:${PATH}"

  cd "${WORK_DIR}"
  mkdir -p themes/foobar
  cat > "${ALJIBE_YAML}" <<'EOF'
theme_paths:
  foobar: themes/foobar
EOF
}

teardown() {
  rm -rf "${WORK_DIR}"
}

@test "frontend runs the task in the exactly matching theme" {
  run "${FRONTEND_CMD}" production foobar
  assert_success
  run cat "${NPM_LOG}"
  assert_output - <<EOF
npm install in ${WORK_DIR}/themes/foobar
npm run production in ${WORK_DIR}/themes/foobar
EOF
}

@test "frontend does not match a theme by substring" {
  run "${FRONTEND_CMD}" production foo
  assert_failure
  assert_output --partial "Theme foo not found in aljibe.yaml"
  run cat "${NPM_LOG}"
  assert_output ""
}
