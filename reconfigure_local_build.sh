#!/bin/bash
# reconfigure_local_build.sh
# Automates the setup of Tizen Certificates and Security Profiles
# Run this INSIDE your podman container or local linux Tizen environment.

set -e

echo "=== Kodi Tizen Build Configuration Helper ==="
echo ""
echo "This script will generate a valid Security Profile required for 'make tpk'."
echo ""

# Check for Tizen SDK
TIZEN_SDK=${TIZEN_SDK:-$HOME/tizen-studio}
if [ ! -d "$TIZEN_SDK" ]; then
    echo "Error: Tizen SDK not found at $TIZEN_SDK"
    echo "Please find where Tizen Studio is installed and set TIZEN_SDK env var."
    exit 1
fi

TIZEN_CLI="$TIZEN_SDK/tools/ide/bin/tizen"
if [ ! -f "$TIZEN_CLI" ]; then
    echo "Error: Tizen CLI not found at $TIZEN_CLI"
    exit 1
fi

echo "✓ Tizen SDK found"
echo ""

# 1. (Skipped) DUID Check
# This script generates a generic signed TPK.
# If you need to install on a physical TV, you must re-sign the output TPK
# using a Distributor Certificate that contains your TV's DUID.
echo "--- Step 1: Preparation ---"
echo "Generating generic certificates to satisfy build requirements."
echo ""
echo "--- Step 2: Generating Certificates ---"
echo "Creating keystore directories..."
mkdir -p "$HOME/tizen-studio-data/keystore/author"
mkdir -p "$HOME/tizen-studio-data/keystore/distributor"

AUTHOR_PASS="123456"
DIST_PASS="123456"
PROFILE_NAME="tv-samsung"

# Clean old certs if exist (optional, safety first)
rm -f "$HOME/tizen-studio-data/keystore/author/kodi_author.p12"
rm -f "$HOME/tizen-studio-data/keystore/distributor/kodi_distributor.p12"

echo "Generating Author Certificate..."
"$TIZEN_CLI" certificate -a "KodiLocal" \
    -f kodi_author \
    -p "$AUTHOR_PASS" \
    -c "US" -o "Kodi" -n "KodiLocal" \
    -e "local@kodi.tv"

echo "Generating Distributor Certificate (Placeholder)..."
# Tizen CLI doesn't easily support DUID via 'certificate' command, so we generate a legitimate
# certificate to satisfy the build system's signing requirement.
# You will need to re-sign with a real DUID-containing cert for physical installation.
"$TIZEN_CLI" certificate -a "KodiLocalDist" \
    -f kodi_distributor \
    -p "$DIST_PASS" \
    -c "US" -o "Kodi" -n "KodiLocalDist" \
    -e "local@kodi.tv"

echo ""
echo "--- Step 3: Configuring Profile ---"
# Remove existing profile if it exists
echo "Removing existing profile '$PROFILE_NAME' (if any)..."
"$TIZEN_CLI" security-profiles remove -n "$PROFILE_NAME" >/dev/null 2>&1 || true

echo "Adding profile '$PROFILE_NAME'..."
"$TIZEN_CLI" security-profiles add \
    -n "$PROFILE_NAME" \
    -a "$HOME/tizen-studio-data/keystore/author/kodi_author.p12" -p "$AUTHOR_PASS" \
    -d "$HOME/tizen-studio-data/keystore/author/kodi_distributor.p12" -dp "$DIST_PASS"

# Explicit Verification
if "$TIZEN_CLI" security-profiles list | grep -q "$PROFILE_NAME"; then
    echo "Profile '$PROFILE_NAME' created successfully."
else
    echo "Error: Failed to create profile '$PROFILE_NAME'. Please check the logs above."
    exit 1
fi

echo ""
echo "--- Step 4: Verification ---"
"$TIZEN_CLI" security-profiles list

echo ""
echo "=== Configuration Complete! ==="
echo ""
echo "You can now build signed TPKs."
echo "The build system has been pre-configured to look for profile: '$PROFILE_NAME'"
echo ""
echo "To build now, run:"
echo "  export TIZEN_SECURITY_PROFILE=$PROFILE_NAME"
echo "  make tpk"
echo ""
