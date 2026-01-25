#!/bin/bash
# Kodi Tizen - Environment Setup Script
# Run this with: source setup-env.sh

# Set Tizen SDK path
export TIZEN_SDK=$HOME/tizen-studio

# Add Tizen tools to PATH
export PATH=$PATH:$TIZEN_SDK/tools
export PATH=$PATH:$TIZEN_SDK/tools/emulator/bin

# Verify setup
echo "Tizen Environment Setup"
echo "======================="
echo ""
echo "TIZEN_SDK: $TIZEN_SDK"
echo ""

# Check if Tizen Studio exists
if [ -d "$TIZEN_SDK" ]; then
    echo "✓ Tizen Studio found"
else
    echo "✗ Tizen Studio not found at $TIZEN_SDK"
    echo "  Please adjust TIZEN_SDK path if needed"
fi

# Check if SDB is available
if command -v sdb &> /dev/null; then
    echo "✓ SDB available: $(which sdb)"
else
    echo "✗ SDB not found in PATH"
fi

echo ""
echo "Environment ready! You can now run:"
echo "  ./tools/tizen/quick-test.sh"
echo ""
