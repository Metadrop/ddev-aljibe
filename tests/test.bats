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

  check_services >&3
  check_project_browse >&3
  ## Todo Make this test work
  # check_drupal_admin_access >&3
}

#@test "install from release" {
#  set -eu -o pipefail
#  cd "$TESTDIR" || { printf "unable to cd to %s\n" "$TESTDIR"; exit 1; }
#  echo "# ddev get metadrop/ddev-aljibe with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
#  ddev get metadrop/ddev-aljibe
#  ddev restart >/dev/null
#  ddev aljibe-assistant --auto

#  check_services >&3
#  check_project_browse >&3
  ## Todo Make this test work
  # check_drupal_admin_access >&3
#}