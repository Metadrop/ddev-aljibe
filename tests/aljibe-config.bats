#!/usr/bin/env bats

# Unit tests for commands/host/aljibe-config.
#
# These tests do not need DDEV: the real script runs with a fake `ddev` that
# reports the web container as running and executes `ddev exec "<cmd>"`
# locally, using a `yq` wrapper that points /mnt/ddev_config/aljibe.yaml to the
# test project's .ddev/aljibe.yaml and runs the real mikefarah yq v4 (a local
# binary or the mikefarah/yq:4 Docker image).
# Tests are skipped when mikefarah yq v4 is not available.

setup() {
  set -eu -o pipefail
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-support

  # shellcheck disable=SC2155
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  ALJIBE_CONFIG_CMD="${DIR}/commands/host/aljibe-config"

  WORK_DIR="$(mktemp -d)"
  mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/.ddev"
  export ALJIBE_YAML="${WORK_DIR}/.ddev/aljibe.yaml"

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
  cat > "${WORK_DIR}/bin/ddev" <<'EOF'
#!/bin/bash
case "$1" in
  status) echo "web    OK" ;;
  exec) bash -c "$2" ;;
esac
EOF
  chmod +x "${WORK_DIR}/bin/yq" "${WORK_DIR}/bin/ddev"
  export PATH="${WORK_DIR}/bin:${PATH}"
  cd "${WORK_DIR}"
}

teardown() {
  rm -rf "${WORK_DIR}"
}

@test "aljibe-config returns a configured value" {
  echo "default_site: mysite" > "${ALJIBE_YAML}"
  run "${ALJIBE_CONFIG_CMD}" default_site
  assert_success
  assert_output "mysite"
}

@test "aljibe-config fails on an invalid aljibe.yaml instead of returning empty" {
  printf 'default_site: mysite\nhooks: [unclosed\n' > "${ALJIBE_YAML}"
  run "${ALJIBE_CONFIG_CMD}" default_site
  assert_failure
}

@test "aljibe-config returns empty, successfully, for a missing key" {
  echo "default_site: mysite" > "${ALJIBE_YAML}"
  run "${ALJIBE_CONFIG_CMD}" theme_paths
  assert_success
  assert_output ""
}
