#!/bin/bash
#
# Touchpad Tray Installer - X-Seti Oct 12 2024
# Installs, configures autostart, and launches touchpad tray applet
# Uses sysfs inhibit method that actually works on KDE Plasma 6 Wayland
#

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directories
INSTALL_DIR="$HOME/.local/bin"
AUTOSTART_DIR="$HOME/.config/autostart"
SCRIPT_NAME="touchpad-tray.py"
DESKTOP_FILE="touchpad-tray.desktop"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Touchpad Tray Applet Installer${NC}"
echo -e "${BLUE}(Working Version - sysfs method)${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if running on Wayland
if [ "$XDG_SESSION_TYPE" != "wayland" ]; then
    echo -e "${RED}Warning: Not running on Wayland. This tool is designed for Wayland.${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Verify touchpad inhibit path exists
INHIBIT_PATH="/sys/class/input/event10/device/inhibited"
if [ ! -f "$INHIBIT_PATH" ]; then
    echo -e "${RED}Error: Touchpad inhibit path not found at $INHIBIT_PATH${NC}"
    echo -e "${YELLOW}Your touchpad might be on a different event device.${NC}"
    echo ""
    echo "Run this to find your touchpad:"
    echo "  cat /proc/bus/input/devices | grep -A 5 -i touchpad"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Touchpad device found at $INHIBIT_PATH${NC}"
echo ""

# Check dependencies
echo -e "${BLUE}Checking dependencies...${NC}"
MISSING_DEPS=()

if ! command -v python3 &> /dev/null; then
    MISSING_DEPS+=("python3")
fi

if ! python3 -c "import PyQt6" &> /dev/null; then
    MISSING_DEPS+=("python-pyqt6")
fi

if ! command -v pkexec &> /dev/null; then
    MISSING_DEPS+=("polkit")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo -e "${RED}Missing dependencies: ${MISSING_DEPS[*]}${NC}"
    echo -e "${BLUE}Install with: sudo pacman -S ${MISSING_DEPS[*]}${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All dependencies found${NC}"
echo ""

# Create directories if they don't exist
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$AUTOSTART_DIR"
echo -e "${GREEN}✓ Directories ready${NC}"
echo ""

# Install script
echo -e "${BLUE}Installing script...${NC}"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"

# Check if script is in current directory (try both names)
if [ -f "touchpad-tray.py" ]; then
    cp "touchpad-tray.py" "$SCRIPT_PATH"
elif [ -f "$SCRIPT_NAME" ]; then
    cp "$SCRIPT_NAME" "$SCRIPT_PATH"
else
    echo -e "${RED}Error: touchpad-tray.py or $SCRIPT_NAME not found in current directory${NC}"
    exit 1
fi

chmod +x "$SCRIPT_PATH"
echo -e "${GREEN}✓ Script installed to $SCRIPT_PATH${NC}"
echo ""

# Create desktop file for autostart
echo -e "${BLUE}Creating autostart entry...${NC}"
cat > "$AUTOSTART_DIR/$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Touchpad Tray Toggle
Comment=System tray applet for toggling touchpad
Exec=$SCRIPT_PATH
Icon=input-touchpad
Terminal=false
Categories=Utility;
X-KDE-autostart-after=panel
X-KDE-StartupNotify=false
EOF

echo -e "${GREEN}✓ Autostart configured${NC}"
echo ""

# Kill existing instance if running
echo -e "${BLUE}Checking for existing instances...${NC}"
if pgrep -f "$SCRIPT_NAME" > /dev/null; then
    echo -e "${BLUE}Stopping existing instance...${NC}"
    pkill -f "$SCRIPT_NAME"
    sleep 1
fi

# Launch the application
echo -e "${BLUE}Launching Touchpad Tray...${NC}"
nohup "$SCRIPT_PATH" > /dev/null 2>&1 &
sleep 2

# Check if it's running
if pgrep -f "$SCRIPT_NAME" > /dev/null; then
    echo -e "${GREEN}✓ Touchpad Tray is running!${NC}"
else
    echo -e "${RED}Warning: Failed to start. Try running manually: $SCRIPT_PATH${NC}"
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: First time you click the icon, you'll be asked${NC}"
echo -e "${YELLOW}for your password to allow touchpad control.${NC}"
echo ""
echo -e "Features:"
echo -e "  • Left-click icon to toggle touchpad on/off"
echo -e "  • Right-click for menu"
echo -e "  • Auto-starts on login"
echo -e "  • ${GREEN}Actually works on Wayland!${NC}"
echo ""
echo -e "To uninstall, run:"
echo -e "  rm $SCRIPT_PATH"
echo -e "  rm $AUTOSTART_DIR/$DESKTOP_FILE"
echo -e "  pkill -f touchpad-tray.py"
echo ""
