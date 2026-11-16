#!/usr/bin/env bats

# Policy checks for the kickstart composer.json templates.
#
# These enforce rules that integration tests cannot catch, for example because
# CI runs with a GitHub token. They do not need DDEV or Docker: they only
# inspect the templates in kickstart/d10, kickstart/d11 and kickstart/d12.

setup() {
  set -eu -o pipefail
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-support

  if ! command -v jq >/dev/null 2>&1; then
    skip "jq is required for these tests"
  fi

  # shellcheck disable=SC2155
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
}

# Composer reads GitHub VCS repositories through the GitHub API and falls back
# to cloning over SSH when the API is not available (no token, or rate
# limited), which fails in the DDEV web container.
@test "kickstart templates do not use GitHub VCS repositories" {
  local version
  for version in d10 d11 d12; do
    run jq -r '.repositories[]? | select(.type == "vcs" or .type == "git" or .type == "github") | .url' "${DIR}/kickstart/${version}/composer.json"
    assert_success
    refute_output --partial "github.com"
  done
}

# Patches pointing at a URL (for example a merge request diff, which anyone
# with push access can change) would download unreviewed code into every new
# project. Patches must be local files shipped with the kickstart.
@test "kickstart templates only use local patch files" {
  local version patch
  for version in d10 d11 d12; do
    run jq -r '.extra.patches // {} | .[] | .[]' "${DIR}/kickstart/${version}/composer.json"
    assert_success
    refute_output --regexp '^[a-zA-Z]+://'
    while IFS= read -r patch; do
      [ -n "$patch" ] || continue
      if [ ! -f "${DIR}/kickstart/common/${patch}" ] && [ ! -f "${DIR}/kickstart/${version}/${patch}" ]; then
        fail "${version}: patch file '${patch}' not found in kickstart/common or kickstart/${version}"
      fi
    done <<< "$output"
  done
}
