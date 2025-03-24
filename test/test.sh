#!/bin/bash

APPNAME="Gamelist-Manager"
APPPATH="/userdata/system/add-ons/${APPNAME,,}"
APPLINK="http://jujuvincebros.fr/phocadownload/outils/executable_only/arrm_executable_without_installer.zip"
ORIGIN="github.com/RobG66/Gamelist-Manager"
DESKTOP_FILE="/usr/share/applications/gamelist-manager.desktop"
PERSISTENT_DESKTOP="/userdata/system/configs/gamelist-manager/gamelist-manager.desktop"

# Remove $APPPATH if it already exists
if [ -d "$APPPATH" ]; then
    rm -rf "$APPPATH"
fi

# Prepare installation directories
mkdir -p "$APPPATH/extra"
mkdir -p /userdata/system/configs/gamelist-manager

# Download and extract application directly to $APPPATH
wget --show-progress -qO "$APPPATH/$APPNAME.zip" "$APPLINK"
unzip -oq "$APPPATH/$APPNAME.zip" -d "$APPPATH"
rm -f "$APPPATH/$APPNAME.zip"

# Download icon
ICON_URL="https://raw.githubusercontent.com/RobG66/Gamelist-Manager/master/resources/icon.png"
curl --progress-bar --location "$ICON_URL" -o "$APPPATH/extra/icon.png"

# Create launcher script
LAUNCHER="$APPPATH/Launcher"
echo "#!/bin/bash" > "$LAUNCHER"
echo 'export DISPLAY=:0.0' >> "$LAUNCHER"
echo 'unclutter-remote -s' >> "$LAUNCHER"
echo "DISPLAY=:0.0 QT_SCALE_FACTOR='1.25' GDK_SCALE='1.25' batocera-wine windows play $APPPATH/GamelistManager.exe" >> "$LAUNCHER"
chmod +x "$LAUNCHER"

# Create persistent desktop entry
echo "Creating persistent desktop entry for Gamelist-Manager..."
cat <<EOF > "$PERSISTENT_DESKTOP"
[Desktop Entry]
Version=1.0
Type=Application
Name=Gamelist Manager
Exec=/userdata/system/add-ons/gamelist-manager/Launcher
Icon=/userdata/system/add-ons/Gamelist-Manager/extra/icon.png
Terminal=false
Categories=Game;batocera.linux;
EOF

chmod +x "$PERSISTENT_DESKTOP"

cp "$PERSISTENT_DESKTOP" "$DESKTOP_FILE"
chmod +x "$DESKTOP_FILE"

# Ensure the desktop entry is always restored to /usr/share/applications
echo "Ensuring Gamelist-Manager desktop entry is restored at startup..."
cat <<EOF > "/userdata/system/configs/gamelist-manager/restore_desktop_entry.sh"
#!/bin/bash
# Restore Gamelist-Manager desktop entry
if [ ! -f "$DESKTOP_FILE" ]; then
    echo "Restoring Gamelist-Manager desktop entry..."
    cp "$PERSISTENT_DESKTOP" "$DESKTOP_FILE"
    chmod +x "$DESKTOP_FILE"
    echo "Gamelist-Manager desktop entry restored."
else
    echo "Gamelist-Manager desktop entry already exists."
fi
EOF
chmod +x "/userdata/system/configs/gamelist-manager/restore_desktop_entry.sh"

# Add to startup script
custom_startup="/userdata/system/custom.sh"
if ! grep -q "/userdata/system/configs/gamelist-manager/restore_desktop_entry.sh" "$custom_startup"; then
    echo "Adding Gamelist-Manager restore script to startup..."
    echo "bash "/userdata/system/configs/gamelist-manager/restore_desktop_entry.sh" &" >> "$custom_startup"
fi
chmod +x "$custom_startup"

# Finish installation
echo "$APPNAME installed successfully!"
