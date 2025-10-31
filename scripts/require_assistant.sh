#!/bin/bash
#ddev-generated

set -e

if [ ! -f .aljibe_installed ]; then

  # Get ddev version and remove 'v' prefix
  DDEV_VERSION=$(ddev -v | cut -f3 -d" " | sed 's/^v//')
  DDEV_VERSION_WITH_DYNAMIC_DEPENDENCIES="1.24.8"

  # Function to compare versions
  version_ge() {
    # Returns 0 (true) if $1 >= $2
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
  }

  # Check DDEV has dynamic dependencies functionality.
  if ! version_ge "$DDEV_VERSION_WITH_DYNAMIC_DEPENDENCIES" "$REQUIRED_VERSION"; then
    ddev add-on get metadrop/ddev-aljibe-assistant
  else
    echo "Metadrop/ddev-aljibe-assistant" > .runtime-deps-aljibe
  fi
fi
