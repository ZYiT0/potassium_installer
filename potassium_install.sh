#!/bin/bash

# Define ANSI color codes
BLUE='\033[0;34m'
LIGHT_BLUE='\033[0;36m' # Changed to standard cyan for a lighter, less intense blue effect
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Clear the terminal screen
clear

# Define the download URLs for Intel and ARM architectures
INTEL_DMG_URL="https://github.com/ZYiT0/OPMW-Potassium/releases/download/v1.0.0/Opiumware.Potassium-1.0.0.dmg"
ARM_DMG_URL="https://github.com/ZYiT0/OPMW-Potassium/releases/download/v1.0.0/Opiumware.Potassium-1.0.0-arm64.dmg"
DMG_FILENAME="Opiumware.Potassium.dmg"
APP_NAME="Opiumware Potassium.app"
APPLICATIONS_DIR="/Applications"

echo -e "${BLUE}Starting Opiumware Potassium installation...${NC}"

# Display a prominent title in the middle
echo ""
echo -e "${LIGHT_BLUE}=========================================${NC}"
echo -e "${LIGHT_BLUE}  Opiumware Potassium Installation       ${NC}"
echo -e "${LIGHT_BLUE}=========================================${NC}"
echo ""
echo "" # Add a newline for spacing

# 0. Check for existing installation
if [ -d "$APPLICATIONS_DIR/$APP_NAME" ]; then
    echo -e "${LIGHT_BLUE}[-]Opiumware Potassium is already installed in $APPLICATIONS_DIR.${NC}"
    read -p "Do you want to proceed with the installation (this will overwrite the existing application)? (y/N): " -n 1 -r
    echo "" # Newline after the prompt
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installation cancelled by user.${NC}"
        exit 0
    fi
    echo -e "${LIGHT_BLUE}Proceeding with re-installation.${NC}"
fi

# 1. Detect system architecture
ARCH=$(uname -m)
DOWNLOAD_URL=""

if [[ "$ARCH" == "x86_64" ]]; then
    echo "Detected Intel (x86_64) architecture."
    DOWNLOAD_URL="$INTEL_DMG_URL"
elif [[ "$ARCH" == "arm64" ]]; then
    echo "Detected Apple Silicon (arm64) architecture."
    DOWNLOAD_URL="$ARM_DMG_URL"
else
    echo -e "${RED}[X] Error: Unsupported architecture: $ARCH. This script only supports x86_64 (Intel) and arm64 (Apple Silicon).${NC}"
    exit 1
fi

# 2. Download the DMG file
echo "Downloading $DMG_FILENAME..."
# Use -s (silent) to suppress progress meter and error messages, but capture exit code
curl -L -s "$DOWNLOAD_URL" -o "$DMG_FILENAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}[X] Error: Failed to download $DMG_FILENAME.${NC}"
    exit 1
fi
echo -e "${GREEN}[√] Download complete.${NC}"

# 3. Mount the DMG file
echo "Mounting $DMG_FILENAME..."
# Use -nobrowse to prevent Finder from opening, -quiet to suppress verbose output
MOUNT_POINT=$(mktemp -d)
hdiutil attach "$DMG_FILENAME" -nobrowse -quiet -mountpoint "$MOUNT_POINT"
if [ $? -ne 0 ]; then
    echo -e "${RED}[X] Error: Failed to mount $DMG_FILENAME.${NC}"
    rm -f "$DMG_FILENAME" # Clean up downloaded file
    exit 1
fi
echo -e "${GREEN}[√] DMG mounted at $MOUNT_POINT.${NC}"

# 4. Find the .app bundle within the mounted volume
APP_PATH_IN_DMG=""
# Find the first .app bundle in the root of the mounted DMG
APP_PATH_IN_DMG=$(find "$MOUNT_POINT" -maxdepth 1 -type d -name "*.app" | head -n 1)

if [ -z "$APP_PATH_IN_DMG" ]; then
    echo -e "${RED}[X] Error: Could not find any .app bundle in the mounted DMG.${NC}"
    hdiutil detach "$MOUNT_POINT" -force > /dev/null 2>&1 # Force detach silently
    rm -rf "$MOUNT_POINT" # Remove temporary mount point
    rm -f "$DMG_FILENAME" # Clean up downloaded file
    exit 1
fi
echo "Found application: $(basename "$APP_PATH_IN_DMG")"

# 5. Copy the application to the Applications folder
echo "Copying '$(basename "$APP_PATH_IN_DMG")' to $APPLICATIONS_DIR..."
# Use rsync without --progress to suppress detailed file list
sudo rsync -a "$APP_PATH_IN_DMG" "$APPLICATIONS_DIR/"
if [ $? -ne 0 ]; then
    echo -e "${RED}[X] Error: Failed to copy the application to $APPLICATIONS_DIR. You might need to run this script with sudo.${NC}"
    hdiutil detach "$MOUNT_POINT" -force > /dev/null 2>&1 # Force detach silently
    rm -rf "$MOUNT_POINT"
    rm -f "$DMG_FILENAME"
    exit 1
fi
echo -e "${GREEN}[√] Application copied successfully.${NC}"

# 6. Unmount the DMG file
echo "Unmounting $DMG_FILENAME..."
hdiutil detach "$MOUNT_POINT" -force > /dev/null 2>&1 # Use -force and redirect output to /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}[X] Warning: Failed to unmount $DMG_FILENAME. You may need to unmount it manually.${NC}"
fi
rm -rf "$MOUNT_POINT" # Remove temporary mount point
echo -e "${GREEN}[√] DMG unmounted and temporary mount point removed.${NC}"

# 7. Clean up the downloaded DMG file
echo "Cleaning up downloaded DMG file..."
rm -f "$DMG_FILENAME"
echo -e "${GREEN}[√] Installation complete. Opiumware Potassium should now be in your Applications folder.${NC}"
echo ""
echo -e "Ui by 7sleeps"
echo -e "Backend by ZYiT0"

exit 0
