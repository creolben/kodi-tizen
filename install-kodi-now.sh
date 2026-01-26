#!/bin/bash

# Quick installer that sets up PATH and runs installation
export PATH="$PATH:$HOME/tizen-studio/tools"

echo "SDB is now available in this session"
echo ""

# Run the installer
./install-to-tv.sh
