#!/bin/bash

setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-addon-backstopjs
  mkdir -p $TESTDIR
  export PROJNAME=test-addon-backstopjs
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

check_services() {
  echo -n "Checking services:"
  INSTALLED_SERVICES=$(ddev get --installed)
  echo -n "Checking if Aljibe is installed..."
  echo "$INSTALLED_SERVICES" | grep -q "aljibe" | echo " Ok."
  echo -n "Checking if Aljibe Assistant is installed..."
  echo "$INSTALLED_SERVICES" | grep -q "aljibe-assistant" | echo " Ok."
  echo -n "Checking if Adminer is installed..."
  echo "$INSTALLED_SERVICES" | grep -q "adminer" | echo " Ok."
  echo -n "Checking if BackstopJS is installed..."
  echo "$INSTALLED_SERVICES" | grep -q "backstopjs" | echo " Ok."
  echo -n "Checking if lighthouse is installed..."
  echo "$INSTALLED_SERVICES" | grep -q "lighthouse" | echo " Ok."
  echo -n "Checking if mkdocs is installed..."
  echo "$INSTALLED_SERVICES" | grep -q "mkdocs" | echo " Ok."
  echo -n "Checking if pa11y is installed..."
  echo "$INSTALLED_SERVICES" | grep -q "pa11y" | echo " Ok."
  echo -n "Checking if redis is installed..."
  echo "$INSTALLED_SERVICES" | grep -q "redis" | echo " Ok."
  echo -n "Checking if selenium is installed..."
  echo "$INSTALLED_SERVICES" | grep -q "selenium" | echo " Ok."
  echo -n "Checking if unlighthouse is installed..."
  echo "$INSTALLED_SERVICES" | grep -q "unlighthouse" | echo " Ok."

}

# Check if the project is browsable with wget
check_project_browse() {
  echo -n "Checking if the project is browsable..."
  curl -s https://${PROJNAME}.ddev.site | grep -q "Welcome"
  echo " Ok."
}

check_drupal_admin_access() {
  echo -n "Checking if the Drupal admin is accessible..."
  curl -sLb cookies $(ddev drush uli) | grep -q "The email address is not made public"
  echo " Ok."
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get ${DIR}
  ddev restart >/dev/null
  ddev aljibe-assistant --auto

  check_services >&3
  check_project_browse >&3
  ## Todo Make this test work
  # check_drupal_admin_access >&3
}

@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev get metadrop/ddev-aljibe with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get metadrop/ddev-aljibe
  ddev restart >/dev/null
  ddev aljibe-assistant --auto

  check_services >&3
  check_project_browse >&3
  ## Todo Make this test work
  # check_drupal_admin_access >&3
}
