#!/bin/bash

echo "=========================================="
echo "Setting up SDB (Smart Development Bridge)"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TIZEN_STUDIO="$HOME/tizen-studio"
SDB_PATH="$TIZEN_STUDIO/tools"

# Check if Tizen Studio exists
if [ ! -d "$TIZEN_STUDIO" ]; then
    echo -e "${YELLOW}Tizen Studio not found at $TIZEN_STUDIO${NC}"
    echo ""
    echo "Please install Tizen Studio first or specify the correct path."
    exit 1
fi

# Check if SDB exists
if [ ! -f "$SDB_PATH/sdb" ]; then
    echo -e "${YELLOW}SDB not found at $SDB_PATH/sdb${NC}"
    echo ""
    echo "Please install Tizen Studio tools."
    exit 1
fi

echo "Found Tizen Studio at: $TIZEN_STUDIO"
echo "Found SDB at: $SDB_PATH/sdb"
echo ""

# Add to current session
export PATH="$PATH:$SDB_PATH"

# Add to shell profile
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_RC="$HOME/.bash_profile"
fi

if [ -n "$SHELL_RC" ]; then
    # Check if already added
    if grep -q "tizen-studio/tools" "$SHELL_RC"; then
        echo -e "${GREEN}✓ PATH already configured in $SHELL_RC${NC}"
    else
        echo "Adding Tizen Studio tools to PATH in $SHELL_RC..."
        echo "" >> "$SHELL_RC"
        echo "# Tizen Studio tools" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:\$HOME/tizen-studio/tools\"" >> "$SHELL_RC"
        echo -e "${GREEN}✓ Added to $SHELL_RC${NC}"
        echo ""
        echo -e "${YELLOW}Note: Restart your terminal or run:${NC}"
        echo "  source $SHELL_RC"
    fi
fi

echo ""
echo "Testing SDB..."
"$SDB_PATH/sdb" version

echo ""
echo -e "${GREEN}=========================================="
echo "SDB Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "You can now use SDB commands:"
echo "  sdb version"
echo "  sdb connect <TV_IP>"
echo "  sdb devices"
echo ""
echo "If 'sdb' command is not found, run:"
echo "  source $SHELL_RC"
echo ""
echo "Or restart your terminal."
echo ""
