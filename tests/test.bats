#!/bin/bash


# Standard DDEV add-on setup code taken from official DDEV add-ons.
setup() {
  set -eu -o pipefail
  export GITHUB_REPO=Metadrop/ddev-aljibe
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  # shellcheck disable=SC2155
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  # shellcheck disable=SC2155
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"

  mkdir -p ~/tmp
  # shellcheck disable=SC2155
  export TESTDIR=$(mktemp -d ~/tmp/${PROJNAME}.XXXXXX)
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true

  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success
  run ddev start -y
  assert_success
}

# Standard DDEV add-on tear down code taken from official DDEV add-ons.
teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

# Generic helper function to check items from external list using a custom checker function.
#
# WARNING: This is an internal helper. Do not call directly. Use wrapper functions instead.
#
# Parameters:
#   $1: item_type - descriptive name (e.g., "folder", "file", "add-on")
#   $2: list_file - path to the file containing items to check
#   $3: checker_function - name of function to call to check each item
#   $4+ - additional arguments passed to checker function
check_items_from_list() {
  local item_type="$1"
  local list_file="$2"
  local checker_function="$3"
  shift 3
  local checker_args=("$@")
  local failed=0

  echo "Checking required ${item_type}s:"

  # Read required items from external file
  while IFS='#' read -r item comment || [ -n "$item" ]; do
    # Skip empty lines and comments
    [[ -z "$item" || "$item" =~ ^[[:space:]]*# ]] && continue

    # Trim whitespace
    item=$(echo "$item" | xargs)
    comment=$(echo "$comment" | xargs)

    # Call the checker function with item and any additional arguments
    if "$checker_function" "$item" "${checker_args[@]}"; then
      echo "Checking if ${item_type} '${item}' exists... Ok. (${comment})"
    else
      echo "Checking if ${item_type} '${item}' exists... Missing. (${comment})"
      failed=1
    fi
  done < "$list_file"

  return $failed
}

# Checker function for filesystem items (files, folders, symlinks)
#
# Parameters:
#   $1: item - the item name
#   $2: test_flag - "-d" for folders, "-f" for files, "-L" for symlinks
check_filesystem_item() {
  local item="$1"
  local test_flag="$2"
  test "$test_flag" "${TESTDIR}/${item}"
}

# Checker function for installed add-ons
#
# Parameters:
#   $1: item - the add-on name
#   $2: installed_services - output from ddev add-on list
check_addon_item() {
  local item="$1"
  local installed_services="$2"
  # Add a trailing space in grep to avoid partial matches
  # Also, start with │ to avoid matching in other places that are not the first
  # column.
  echo "$installed_services" | grep -q "│ $item "
}

# Checker function for running services
#
# Parameters:
#   $1: item - the service name
#   $2: running_services - output from ddev describe
check_service_item() {
  local item="$1"
  local running_services="$2"
  # Add a trailing space in grep to avoid partial matches
  # Also, start with │ to avoid matching in other places that are not the first
  # column.
  echo "$running_services" | grep -q "│ $item "
}

# Internal helper function to check existence of items from external list.
#
# WARNING: Do not call this function directly. Use check_required_folders or
# check_required_files instead.
#
# Parameters:
#   $1: item_type - "folder" or "file"
#   $2: list_file - path to the file containing items to check
#   $3: test_flag - "-d" for folders, "-f" for files
check_required_items() {
  local item_type="$1"
  local list_file="$2"
  local test_flag="$3"
  check_items_from_list "$item_type" "$list_file" check_filesystem_item "$test_flag"
}

# Check a list of add-ons that should be installed.
check_addons() {
  local INSTALLED_ADDONS
  INSTALLED_ADDONS=$(ddev add-on list --installed)
  run check_items_from_list "add-on" "${DIR}/tests/required_addons.txt" check_addon_item "$INSTALLED_ADDONS"
  assert_success
}

# Check a list of required folders.
check_required_folders() {
  run check_required_items "folder" "${DIR}/tests/required_folders.txt" "-d"
  assert_success
}

# Check a list of required files.
check_required_files() {
  run check_required_items "file" "${DIR}/tests/required_files.txt" "-f"
  assert_success
}

# Check a list of required symlinks.
check_required_symlinks() {
  run check_required_items "symlinks" "${DIR}/tests/required_symlinks.txt" "-L"
  assert_success
}

# Check a list of services that should be running.
check_services() {
  local RUNNING_SERVICES
  RUNNING_SERVICES=$(ddev describe)
  run check_items_from_list "service" "${DIR}/tests/required_services.txt" check_service_item "$RUNNING_SERVICES"
  assert_success
}

# Check Aljibe Assistant is installed alongside Aljibe.
check_assistant_is_installed() {
  echo -n "Checking if Aljibe Assistant is installed..."
  run ddev add-on list --installed
  assert_success

  if echo "$output" | grep -q "aljibe-assistant"; then
    echo " Ok."
  else
    echo " Failed."
    fail "Aljibe Assistant is not installed"
  fi
}

# Checks the homepage returns a 200 status code.
check_project_homepage_is_browsable() {
  echo -n "Checking if the project is browsable..."
  run curl -w "%{http_code}" -o /dev/null -s "https://${PROJNAME}.ddev.site"
  assert_success

  local status_code="$output"
  if [ "$status_code" == "200" ]; then
    echo " Ok."
  else
    echo " Failed."
    fail "Project homepage returned status code $status_code instead of 200"
  fi
}

# Checks if the Drupal admin user is accessible via one-time login link.
#
# It checks page content because the status code is not valid for this check: if
# the ULI URL is not valid the user is redirected to the login page with a 200
# status code.
check_drupal_admin_access() {
  echo -n "Checking if the Drupal admin is accessible..."

  run ddev drush uli
  assert_success
  local login_url="$output"

  run curl -sLb /tmp/cookies_$$ "$login_url"
  assert_success
  local response="$output"

  # For some reason, the message saying that you have used a one-time login link
  # is not always present, so we check for the password change prompt instead.
  if echo "$response" | grep -q "To change the current user password, enter the new password in both fields."; then
    echo " Ok."
  else
    echo " Failed."
    fail "Drupal admin login check failed - expected password change prompt not found"
  fi

  # Cleanup
  rm -f /tmp/cookies_$$
}


check_create_database_command() {

  local DB_NAME="secondary"

  echo -n "Checking if create-database command works..."
  run ddev create-database $DB_NAME
  assert_success
  echo " Ok."

  echo -n "Checking if new created database is accessible..."
  run bats_pipe echo "SHOW TABLES;" \| ddev mysql --database="$DB_NAME"
  assert_success
  echo " Ok."

}

check_aljibe_config_command() {

  local line_count

  echo -n "Checking if aljibe-config default_site returns one line..."
  run ddev aljibe-config default_site
  assert_success

  # Check output is not empty and has exactly one line
  [ -n "$output" ]
  line_count=$(echo "$output" | wc -l)
  [ "$line_count" -eq 1 ]
  echo " Ok."

  echo -n "Checking if aljibe-config hooks -k returns 8 lines with expected hooks..."
  run ddev aljibe-config hooks -k
  assert_success
  # Check we have 8 lines
  line_count=$(echo "$output" | wc -l)
  [ "$line_count" -eq 8 ]
  # Check for each expected hook name
  assert_output --partial "pre_setup"
  assert_output --partial "post_setup"
  assert_output --partial "pre_site_install"
  assert_output --partial "post_site_install"
  assert_output --partial "pre_site_install_config"
  assert_output --partial "post_site_install_config"
  assert_output --partial "pre_site_install_db"
  assert_output --partial "post_site_install_db"
  echo " Ok."

  echo -n "Checking if aljibe-config hooks returns 8 lines and some content..."
  run ddev aljibe-config hooks
  assert_success
  # Check we have 8 lines
  line_count=$(echo "$output" | wc -l)
  [ "$line_count" -eq 8 ]
  # Check for the drush uli command
  assert_output --partial "drush @\${SITE_ALIAS} uli"
  echo " Ok."

}

@test "install from directory" {
  set -eu -o pipefail
  cd "$TESTDIR"
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3

  # Install the add-on and restart ddev to apply changes.
  ddev add-on get "${DIR}"
  assert_success
  ddev restart -y
  assert_success

  # Run Assistant in automatic mode with standard profile.
  ddev aljibe-assistant --auto -p standard
  assert_success

  # Checks on files and folders required after installation.
  check_required_folders
  check_required_files
  check_required_symlinks

  # Make sure Assistant is installed.
  check_assistant_is_installed

  # Check the required addons have been installed correctly.
  check_addons

  # Check if the expected services are running.
  check_services

  # Check the project's homepage is accessible.
  check_project_homepage_is_browsable
  check_drupal_admin_access

  # Check commands
  check_create_database_command
  check_aljibe_config_command
}
