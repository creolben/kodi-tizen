#!/bin/bash
# Quick Test Script - Connect to TV and Test Kodi

# Add Tizen Studio to PATH
export PATH=$PATH:$HOME/tizen-studio/tools

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Kodi Tizen - Quick Test${NC}"
echo ""

# Check if SDB is available
if ! command -v sdb &> /dev/null; then
    echo -e "${YELLOW}Adding Tizen Studio to PATH...${NC}"
    export PATH=$PATH:$HOME/tizen-studio/tools
fi

# Verify SDB is now available
if command -v sdb &> /dev/null; then
    echo -e "${GREEN}✓ SDB found${NC}"
    echo ""
else
    echo "Error: SDB not found even after adding to PATH"
    echo "Please check your Tizen Studio installation"
    exit 1
fi

# Run the interactive connection helper
./tools/tizen/connect-tv.sh
