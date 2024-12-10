#!/bin/sh
#ddev-generated

# Check if aljibe.yaml exists in parent directory
if [ -f "../aljibe.yaml" ]; then
    ALJIBE_INSTALLED=1
fi

# Function to check if an addon is installed
check_addon_installed() {
    ddev add-on list --installed --skip-hooks | grep -i "$1" -q
}

# Function to install addon if conditions are met
install_addon() {
    local addon_name="$1"
    local addon_path="$2"
    
    # Install if Aljibe is not installed, or if both Aljibe and the addon are installed
    if [ -z "$ALJIBE_INSTALLED" ] || ([ -n "$ALJIBE_INSTALLED" ] && check_addon_installed "$addon_name"); then
        echo $ALJIBE_INSTALLED
        echo check_addon_installed "$addon_name"
        echo "**** Installing $addon_name..."
        ddev add-on get "$addon_path" 2&> /dev/null
    else
        echo "XXXX Skipping $addon_name installation"
    fi
}

# Install addons
install_addon "ddev-adminer" "ddev/ddev-adminer"
install_addon "ddev-mkdocs" "metadrop/ddev-mkdocs"
install_addon "ddev-backstopjs" "metadrop/ddev-backstopjs"
install_addon "ddev-lighthouse" "metadrop/ddev-lighthouse"
install_addon "ddev-selenium" "metadrop/ddev-selenium"
install_addon "ddev-pa11y" "metadrop/ddev-pa11y"
install_addon "ddev-unlighthouse" "metadrop/ddev-unlighthouse"
install_addon "ddev-aljibe-assistant" "metadrop/ddev-aljibe-assistant"

# Check for memcached and install redis if needed
if ! check_addon_installed "memcached"; then
    echo "memcached is not installed. Installing ddev/ddev-redis..."
    install_addon "ddev-redis" "ddev/ddev-redis"
fi


