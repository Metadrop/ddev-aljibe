#!/bin/sh
#ddev-generated

# Check if aljibe.yaml exists in parent directory
if [ -f "../aljibe.yaml" ]; then
    ALJIBE_INSTALLED=1
fi

# Function to check if an addon is installed
check_addon_installed() {
    ddev add-on get --installed | grep "$1" -q
}

# Function to install addon if conditions are met
install_addon() {
    local addon_name="$1"
    local addon_path="$2"
    
    # Install if Aljibe is not installed, or if both Aljibe and the addon are installed
    if [ -z "$ALJIBE_INSTALLED" ] || ([ -n "$ALJIBE_INSTALLED" ] && check_addon_installed "$addon_name"); then
        ddev add-on get "$addon_path"
    fi
}

# Install addons
install_addon "ddev-adminer" "ddev/ddev-adminer"
install_addon "ddev-mkdocs" "Metadrop/ddev-mkdocs"
install_addon "ddev-backstopjs" "Metadrop/ddev-backstopjs"
install_addon "ddev-lighthouse" "Metadrop/ddev-lighthouse"
install_addon "ddev-selenium" "Metadrop/ddev-selenium"
install_addon "ddev-pa11y" "Metadrop/ddev-pa11y"
install_addon "ddev-unlighthouse" "Metadrop/ddev-unlighthouse"
install_addon "ddev-aljibe-assistant" "Metadrop/ddev-aljibe-assistant"

# Check for memcached and install redis if needed
if ! check_addon_installed "memcached"; then
    echo "memcached is not installed. Installing ddev/ddev-redis..."
    install_addon "ddev-redis" "ddev/ddev-redis"
fi


