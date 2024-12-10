#!/bin/sh
#ddev-generated

# Initialize ALJIBE_INSTALLED to 0 and check if aljibe.yaml exists
ALJIBE_INSTALLED=0
if [ -f "../aljibe.yaml" ]; then
    ALJIBE_INSTALLED=1
fi

# Function to check if an addon is installed
check_addon_installed() {
    if ddev add-on list --installed --skip-hooks 2>/dev/null | grep -i "$1" -q; then
        return 0  # Found
    else
        return 1  # Not found
    fi
}

# Function to install addon if conditions are met
install_addon() {
    local addon_name=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    local addon_path=$(echo "$2" | tr '[:upper:]' '[:lower:]')
    
    # Install if Aljibe is not installed (ALJIBE_INSTALLED=0), or if both Aljibe and the addon are installed
    if [ "$ALJIBE_INSTALLED" -eq 0 ] || ([ "$ALJIBE_INSTALLED" -eq 1 ] && check_addon_installed "$addon_name"); then
        echo "**** Installing $addon_name..."
        ddev add-on get "$addon_path" 2>/dev/null
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


