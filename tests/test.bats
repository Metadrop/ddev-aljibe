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
  check_items_from_list "add-on" "${DIR}/tests/required_addons.txt" check_addon_item "$INSTALLED_ADDONS"
}

# Check a list of required folders.
check_required_folders() {
  check_required_items "folder" "${DIR}/tests/required_folders.txt" "-d"
}

# Check a list of required files.
check_required_files() {
  check_required_items "file" "${DIR}/tests/required_files.txt" "-f"
}

# Check a list of required symlinks.
check_required_symlinks() {
  check_required_items "symlinks" "${DIR}/tests/required_symlinks.txt" "-L"
}

# Check a list of services that should be running.
check_services() {
  local RUNNING_SERVICES
  RUNNING_SERVICES=$(ddev describe)
  check_items_from_list "service" "${DIR}/tests/required_services.txt" check_service_item "$RUNNING_SERVICES"
}

# Check Aljibe Assistant is installed alongside Aljibe.
check_assistant_is_installed() {
  local failed=0

  echo -n "Checking if Aljibe Assistant is installed..."
  if ddev add-on list --installed  | grep -q "aljibe-assistant"; then
    echo " Ok."
  else
    echo " Failed."
    failed=1
  fi
  return "$failed"
}

# Checks the homepage returns a 200 status code.
check_project_homepage_is_browsable() {
  local failed=0

  echo -n "Checking if the project is browsable..."
  local status_code
  status_code=$(curl -w "%{http_code}"  -o NULL -s  "https://${PROJNAME}.ddev.site")

  if [ "$status_code" == "200" ]; then
    echo " Ok."
  else
    echo " Failed."
    failed=1
  fi

  return "$failed"
}

# Checks if the Drupal admin user is accessible via one-time login link.
#
# It checks page content because the status code is not valid for this check: if
# the ULI URL is not valid the user is redirected to the login page with a 200
# status code.
check_drupal_admin_access() {
  local failed=0

  echo -n "Checking if the Drupal admin is accessible..."

  local login_url
  login_url=$(ddev drush uli 2>&1)

  # Debug output
  echo ""
  echo "DEBUG: login_url = '$login_url'"
  echo "DEBUG: Attempting curl..."

  local response
  response=$(curl -sLb /tmp/cookies_$$ "$login_url" 2>&1)
  local curl_exit=$?

  echo "DEBUG: curl exit code = $curl_exit"
  echo "DEBUG: response length = ${#response}"
  echo "DEBUG: First 200 chars of response = '${response:0:200}'"

  if echo "$response" | grep -q "You have used a one-time login link"; then
    echo " Ok."
  else
    echo " Failed."
    echo "DEBUG: Full response:"
    echo "$response"
    failed=1
  fi

  # Cleanup
  rm -f /tmp/cookies_$$

  return "$failed"
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
  run check_required_folders
  assert_success

  run check_required_files
  assert_success

  run check_required_symlinks
  assert_success

  # Make sure Assistant is installed.
  run check_assistant_is_installed
  assert_success

  # Check the required addons have installed correctly.
  run check_addons
  assert_success

  # Check if the expected services are running.
  run check_services
  assert_success

  # Check the project's homepage is accessible.
  run check_project_homepage_is_browsable
  assert_success

  run check_drupal_admin_access
  assert_success
}
