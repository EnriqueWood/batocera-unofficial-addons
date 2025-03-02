#!/bin/bash

# Variables to update for different apps
APP_NAME="PeaZip"
AMD_SUFFIX="/peazip/extra/peazip.AppImage"
ARM_SUFFIX=""
LOGO_URL="https://github.com/DTJW92/batocera-unofficial-addons/raw/main/peazip/extra/peazip-icon.png"
REPO_BASE_URL="https://github.com/DTJW92/batocera-unofficial-addons/raw/main"

# -----------------------------------------------------------------------------------------------------------------
# Directories
ADDONS_DIR="/userdata/system/add-ons"
CONFIGS_DIR="/userdata/system/configs"
DESKTOP_DIR="/usr/share/applications"
CUSTOM_SCRIPT="/userdata/system/custom.sh"
APP_CONFIG_DIR="${CONFIGS_DIR}/${APP_NAME,,}"
PERSISTENT_DESKTOP="${APP_CONFIG_DIR}/${APP_NAME,,}.desktop"
DESKTOP_FILE="${DESKTOP_DIR}/${APP_NAME,,}.desktop"

# Ensure directories exist
echo "Creating necessary directories..."
mkdir -p "$APP_CONFIG_DIR" "$ADDONS_DIR/${APP_NAME,,}"
mkdir -p $ADDONS_DIR/${APP_NAME,,}/extra

# Step 1: Detect system architecture
echo "Detecting system architecture..."
arch=$(uname -m)

if [ "$arch" == "x86_64" ]; then
    echo "Architecture: x86_64 detected."
    appimage_url="${REPO_BASE_URL}${AMD_SUFFIX}"
elif [ "$arch" == "aarch64" ]; then
    echo "Architecture: arm64 detected."
    if [ -n "$ARM_SUFFIX" ]; then
        appimage_url="${REPO_BASE_URL}${ARM_SUFFIX}"
    else
        echo "No ARM64 AppImage suffix provided. Skipping download. Exiting."
        exit 1
    fi
else
    echo "Unsupported architecture: $arch. Exiting."
    exit 1
fi

if [ -z "$appimage_url" ]; then
    echo "No suitable AppImage found for architecture: $arch. Exiting."
    exit 1
fi

# Step 2: Download the AppImage
echo "Downloading $APP_NAME AppImage from $appimage_url..."
mkdir -p "$ADDONS_DIR/${APP_NAME,,}"
wget -q --show-progress -O "$ADDONS_DIR/${APP_NAME,,}/${APP_NAME,,}.AppImage" "$appimage_url"

if [ $? -ne 0 ]; then
    echo "Failed to download $APP_NAME AppImage."
    exit 1
fi

chmod a+x "$ADDONS_DIR/${APP_NAME,,}/${APP_NAME,,}.AppImage"
echo "$APP_NAME AppImage downloaded and marked as executable."

# Step 2.5: Download the application icon
echo "Downloading $APP_NAME icon..."
wget -q --show-progress -O "$ADDONS_DIR/${APP_NAME,,}/extra/icon.png" "$ICON_URL"

if [ $? -ne 0 ]; then
    echo "Failed to download $APP_NAME icon."
    exit 1
fi

# Update ICON_PATH to use the downloaded icon
ICON_PATH="$ADDONS_DIR/$APP_NAME/icon.png"

# Step 3: Create persistent desktop entry
echo "Creating persistent desktop entry for $APP_NAME..."
cat <<EOF > "$PERSISTENT_DESKTOP"
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Exec=$ADDONS_DIR/${APP_NAME,,}/${APP_NAME,,}.AppImage
Icon=$ADDONS_DIR/${APP_NAME,,}/extra/${APP_NAME,,}-icon.png
Terminal=false
Categories=Game;batocera.linux;
EOF

chmod +x "$PERSISTENT_DESKTOP"

cp "$PERSISTENT_DESKTOP" "$DESKTOP_FILE"
chmod +x "$DESKTOP_FILE"

# Ensure the desktop entry is always restored to /usr/share/applications
echo "Ensuring $APP_NAME desktop entry is restored at startup..."
cat <<EOF > "${APP_CONFIG_DIR}/restore_desktop_entry.sh"
#!/bin/bash
# Restore $APP_NAME desktop entry
if [ ! -f "$DESKTOP_FILE" ]; then
    echo "Restoring $APP_NAME desktop entry..."
    cp "$PERSISTENT_DESKTOP" "$DESKTOP_FILE"
    chmod +x "$DESKTOP_FILE"
    echo "$APP_NAME desktop entry restored."
else
    echo "$APP_NAME desktop entry already exists."
fi
EOF
chmod +x "${APP_CONFIG_DIR}/restore_desktop_entry.sh"

# Add to startup
echo "Adding desktop entry restore script to startup..."
cat <<EOF > "$CUSTOM_SCRIPT"
#!/bin/bash
# Restore $APP_NAME desktop entry at startup
bash "${APP_CONFIG_DIR}/restore_desktop_entry.sh" &
EOF
chmod +x "$CUSTOM_SCRIPT"

echo "$APP_NAME desktop entry creation complete."
