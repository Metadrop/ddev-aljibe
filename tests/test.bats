#!/bin/bash

setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-addon-aljibe
  mkdir -p "$TESTDIR"
  export PROJNAME=test-addon-aljibe
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy "$PROJNAME" >/dev/null 2>&1 || true
  cd "$TESTDIR"
  ddev config --project-name="$PROJNAME"
  ddev start -y >/dev/null
}

teardown() {
  set -eu -o pipefail
  cd "$TESTDIR" || { printf "unable to cd to %s\n" "$TESTDIR"; exit 1; }
  ddev delete -Oy "$PROJNAME" >/dev/null 2>&1
  [ -n "$TESTDIR" ] && rm -rf "$TESTDIR"
}

# Internal helper function to check existence of items from external list.
#
# WARNING: Do not call this function directly. Use check_required_folders or
# check_required_files instead. The wrong parameters may lead to unexpected
# results.
#
# Parameters:
#   $1: item_type - "folder" or "file"
#   $2: list_file - path to the file containing items to check
#   $3: test_flag - "-d" for folders, "-f" for files
check_required_items() {
  local item_type="$1"
  local list_file="$2"
  local test_flag="$3"
  local failed=0

  echo "Checking required ${item_type}s:"

  # Read required items from external file
  while IFS='#' read -r item comment || [ -n "$item" ]; do
    # Skip empty lines and comments
    [[ -z "$item" || "$item" =~ ^[[:space:]]*# ]] && continue

    # Trim whitespace
    item=$(echo "$item" | xargs)
    comment=$(echo "$comment" | xargs)

    if test "$test_flag" "${TESTDIR}/${item}"; then
      echo "Checking if ${item_type} '${item}' exists... Ok. (${comment})"
    else
      echo "Checking if ${item_type} '${item}' exists... Missing. (${comment})"
      failed=1
    fi
  done < "$list_file"

  return $failed
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

check_services() {
  echo "Checking services:"
  INSTALLED_SERVICES=$(ddev get --installed)
  for SERVICE in aljibe aljibe-assistant adminer backstopjs lighthouse mkdocs pa11y redis selenium unlighthouse; 
  do
    if echo "$INSTALLED_SERVICES" | grep -q "$SERVICE"; then
      echo "Checking if $SERVICE is installed... Ok."
    else
      echo "Checking if $SERVICE is installed... Not installed."
    fi
  done
}

check_project_browse() {
  echo -n "Checking if the project is browsable..."
  if curl -s "https://${PROJNAME}.ddev.site" | grep -q "Welcome"; then
    echo " Ok."
  else
    echo " Failed."
  fi
}

check_drupal_admin_access() {
  echo -n "Checking if the Drupal admin is accessible..."
  if curl -sLb cookies "$(ddev drush uli)" | grep -q "The email address is not made public"; then
    echo " Ok."
  else
    echo " Failed."
  fi
}

@test "install from directory" {
  set -eu -o pipefail
  cd "$TESTDIR"
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get "${DIR}"
  ddev restart >/dev/null
  ddev aljibe-assistant --auto

  # Checks on files and folders required after installation.
  run check_required_folders
  echo "$output" >&3
  [ "$status" -eq 0 ]

  run check_required_files
  echo "$output" >&3
  [ "$status" -eq 0 ]

  run check_required_symlinks
  echo "$output" >&3
  [ "$status" -eq 0 ]

  check_services >&3
  check_project_browse >&3
  ## Todo Make this test work
  # check_drupal_admin_access >&3
}

@test "install from release" {
  set -eu -o pipefail
  cd "$TESTDIR" || { printf "unable to cd to %s\n" "$TESTDIR"; exit 1; }
  echo "# ddev get metadrop/ddev-aljibe with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get metadrop/ddev-aljibe
  ddev restart >/dev/null
  ddev aljibe-assistant --auto

  check_services >&3
  check_project_browse >&3
  ## Todo Make this test work
  # check_drupal_admin_access >&3
}