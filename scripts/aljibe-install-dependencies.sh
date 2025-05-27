#!/bin/bash
#ddev-generated


# Define array of addons to install
# Format: "addon_name|addon_path"
ADDONS=(
    "ddev-adminer|ddev/ddev-adminer"
    "ddev-mkdocs|metadrop/ddev-mkdocs"
    "ddev-backstopjs|metadrop/ddev-backstopjs"
    "ddev-selenium|metadrop/ddev-selenium"
    "ddev-pa11y|metadrop/ddev-pa11y"
    "ddev-unlighthouse|metadrop/ddev-unlighthouse"
    "ddev-aljibe-assistant|metadrop/ddev-aljibe-assistant"
)

# Initialize ALJIBE_INSTALLED to 0 and check if aljibe.yaml exists
ALJIBE_INSTALLED=0
if [ -f "aljibe.yaml" ]; then
    ALJIBE_INSTALLED=1
    echo "Aljibe is already installed, we will only update addons."
fi

# Function to check if an addon is installed
is_addon_installed() {
    if ddev add-on list --installed --skip-hooks | grep -i "$1" -q; then
        echo "Addon '$1' is already installed."
        return 0  # Found
    else
        echo "Addon '$1' is not installed."
        return 1  # Not found
    fi
}

# Function to install addon if conditions are met
install_addon() {
    local addon_name=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    local addon_path=$(echo "$2" | tr '[:upper:]' '[:lower:]')

    # Install if Aljibe is not installed (ALJIBE_INSTALLED=0), or if both Aljibe and the addon are installed
    if [ "$ALJIBE_INSTALLED" -eq 0 ] || ([ "$ALJIBE_INSTALLED" -eq 1 ] && is_addon_installed "$addon_name"); then
        ddev add-on get "$addon_path" &> /dev/null
    fi
}

# Install addons from array
for addon in "${ADDONS[@]}"; do
    addon_name=$(echo "$addon" | cut -d'|' -f1)
    addon_path=$(echo "$addon" | cut -d'|' -f2)
    install_addon "$addon_name" "$addon_path"
done

# Check for memcached and install redis if needed
if is_addon_installed "memcached"; then
    echo "memcached is not installed. Installing ddev/ddev-redis..."
    install_addon "ddev-redis" "ddev/ddev-redis"
fi

# ddev-selenium-video is mandatory if ddev-selenium is installed
echo "Forcing install of ddev-selenium-video..."
if is_addon_installed "ddev-selenium"; then
  echo "ddev-selenium is installed, installing ddev-selenium-video..."
  ddev add-on get metadrop/ddev-selenium-video
fi

