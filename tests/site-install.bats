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
  export DDEV_DOCROOT=web
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

# Put chmod/sed wrappers first in PATH that behave like the BSD (macOS) tools:
# - chmod: options are only accepted before operands.
# - sed: -i always takes a backup suffix (attached `-i.bak`, or the next
#   argument when given as a bare `-i`).
install_bsd_tool_wrappers() {
  local real_chmod real_sed
  real_chmod="$(command -v chmod)"
  real_sed="$(command -v sed)"
  BSD_DIR="${STUB_DIR}/bsd"
  mkdir -p "${BSD_DIR}"

  cat > "${BSD_DIR}/chmod" <<WRAPPER
#!/bin/bash
seen_operand=0
for arg in "\$@"; do
  if [[ "\$arg" == -* && \$seen_operand -eq 1 ]]; then
    echo "chmod: \$arg: No such file or directory" >&2
    exit 1
  fi
  [[ "\$arg" != -* ]] && seen_operand=1
done
exec "${real_chmod}" "\$@"
WRAPPER

  cat > "${BSD_DIR}/sed" <<WRAPPER
#!/bin/bash
args=()
while [ \$# -gt 0 ]; do
  case "\$1" in
    -i) args+=("-i\$2"); shift 2 ;;
    *) args+=("\$1"); shift ;;
  esac
done
exec "${real_sed}" "\${args[@]}"
WRAPPER

  chmod +x "${BSD_DIR}/chmod" "${BSD_DIR}/sed"
  export PATH="${BSD_DIR}:${PATH}"
}

@test "site-install sets up a secondary site with BSD (macOS) chmod and sed" {
  # Fake ddev for a full config install of the secondary site "second".
  cat > "${STUB_DIR}/ddev" <<'STUB'
#!/bin/bash
echo "$*" >> "${DDEV_CALLS_LOG}"
case "$*" in
  "drush @second.local status --field=site") echo "sites/second" ;;
esac
exit 0
STUB
  export DDEV_PRIMARY_URL=https://test.ddev.site
  mkdir -p web/sites/default web/sites/second
  cat > web/sites/default/settings.ddev.php <<'PHP'
$databases['default']['default']['database'] = "db";
PHP
  echo "uri: http://example.docker.localhost:8000" > web/sites/second/example.local.drush.yml

  install_bsd_tool_wrappers

  run "${SITE_INSTALL_CMD}" second
  assert_success

  run cat web/sites/second/settings.ddev.php
  assert_output --partial "['database'] = \"db_second\""
  run cat web/sites/second/local.drush.yml
  assert_output "uri: https://test.ddev.site"
  # No backup files left behind (BSD `sed -i -e` would leave local.drush.yml-e).
  run find web/sites/second -maxdepth 1 \( -name '*.yml-e' -o -name '*.bak' \)
  assert_output ""
}

@test "site-install handles spaces in the project path and database file name" {
  # Fake ddev: print each argument in brackets so splitting is visible.
  cat > "${STUB_DIR}/ddev" <<'STUB'
#!/bin/bash
{ printf 'ddev'; printf ' [%s]' "$@"; printf '\n'; } >> "${DDEV_CALLS_LOG}"
case "$*" in
  "drush @self status --field=site") echo "sites/default" ;;
esac
exit 0
STUB
  export DDEV_APPROOT="${STUB_DIR}/my project"
  mkdir -p "${DDEV_APPROOT}/web/sites/default"
  echo "-- dump" > "${STUB_DIR}/my dump.sql"

  run "${SITE_INSTALL_CMD}" self "${STUB_DIR}/my dump.sql"
  assert_success
  run cat "${DDEV_CALLS_LOG}"
  assert_line "ddev [import-db] [--file] [${STUB_DIR}/my dump.sql] [--database] [db]"
  assert_line "ddev [drush] [@self] [deploy]"
}

@test "site-install copies dotfiles from the files archive" {
  cat > "${STUB_DIR}/ddev" <<'STUB'
#!/bin/bash
echo "$*" >> "${DDEV_CALLS_LOG}"
case "$*" in
  "drush @self status --field=site") echo "sites/default" ;;
esac
exit 0
STUB
  mkdir -p web/sites/default archive/files/images
  echo "Deny from all" > archive/files/.htaccess
  echo "png" > archive/files/images/logo.png
  tar -czf files.tar.gz -C archive files

  run "${SITE_INSTALL_CMD}" self '' files.tar.gz
  assert_success
  run cat web/sites/default/files/.htaccess
  assert_output "Deny from all"
  run cat web/sites/default/files/images/logo.png
  assert_output "png"
}

@test "site-install removes only its own temp dir when TMPDIR has spaces" {
  cat > "${STUB_DIR}/ddev" <<'STUB'
#!/bin/bash
echo "$*" >> "${DDEV_CALLS_LOG}"
case "$*" in
  "drush @self status --field=site") echo "sites/default" ;;
esac
exit 0
STUB
  mkdir -p web/sites/default archive/files
  echo "a" > archive/files/a.txt
  tar -czf files.tar.gz -C archive files

  # An unrelated directory whose path is a prefix of TMPDIR up to the space.
  mkdir -p "${STUB_DIR}/my"
  echo "keep me" > "${STUB_DIR}/my/important.txt"
  mkdir -p "${STUB_DIR}/my tmp"
  export TMPDIR="${STUB_DIR}/my tmp"

  run "${SITE_INSTALL_CMD}" self '' files.tar.gz
  assert_success
  # The unrelated directory is untouched...
  run cat "${STUB_DIR}/my/important.txt"
  assert_output "keep me"
  # ...and the extraction temp dir was cleaned up.
  run ls -A "${STUB_DIR}/my tmp"
  assert_output ""
}
