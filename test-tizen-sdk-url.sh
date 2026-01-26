#!/bin/bash
# Quick script to test if Tizen Studio 6.1 URL exists

echo "=========================================="
echo "Testing Tizen Studio URLs"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test Tizen Studio 6.1
echo "Testing Tizen Studio 6.1..."
URL_6_1="http://download.tizen.org/sdk/Installer/tizen-studio_6.1/web-cli_Tizen_Studio_6.1_ubuntu-64.bin"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL_6_1")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Tizen Studio 6.1 URL exists!${NC}"
    echo "  URL: $URL_6_1"
    
    # Get file size
    SIZE=$(curl -sI "$URL_6_1" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
    SIZE_MB=$((SIZE / 1024 / 1024))
    echo "  Size: ${SIZE_MB} MB"
else
    echo -e "${RED}✗ Tizen Studio 6.1 URL not found (HTTP $HTTP_CODE)${NC}"
    echo "  URL: $URL_6_1"
fi

echo ""

# Test Tizen Studio 5.0 (fallback)
echo "Testing Tizen Studio 5.0 (fallback)..."
URL_5_0="http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL_5_0")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Tizen Studio 5.0 URL exists (fallback available)${NC}"
    echo "  URL: $URL_5_0"
    
    # Get file size
    SIZE=$(curl -sI "$URL_5_0" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
    SIZE_MB=$((SIZE / 1024 / 1024))
    echo "  Size: ${SIZE_MB} MB"
else
    echo -e "${RED}✗ Tizen Studio 5.0 URL not found (HTTP $HTTP_CODE)${NC}"
    echo "  URL: $URL_5_0"
fi

echo ""

# Test Tizen Studio 6.0 (alternative)
echo "Testing Tizen Studio 6.0 (alternative)..."
URL_6_0="http://download.tizen.org/sdk/Installer/tizen-studio_6.0/web-cli_Tizen_Studio_6.0_ubuntu-64.bin"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL_6_0")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Tizen Studio 6.0 URL exists${NC}"
    echo "  URL: $URL_6_0"
    
    # Get file size
    SIZE=$(curl -sI "$URL_6_0" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
    SIZE_MB=$((SIZE / 1024 / 1024))
    echo "  Size: ${SIZE_MB} MB"
else
    echo -e "${RED}✗ Tizen Studio 6.0 URL not found (HTTP $HTTP_CODE)${NC}"
    echo "  URL: $URL_6_0"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""

# Check results
HTTP_CODE_6_1=$(curl -s -o /dev/null -w "%{http_code}" "$URL_6_1")
HTTP_CODE_5_0=$(curl -s -o /dev/null -w "%{http_code}" "$URL_5_0")

if [ "$HTTP_CODE_6_1" = "200" ]; then
    echo -e "${GREEN}✓ PRIMARY: Tizen Studio 6.1 will be used${NC}"
    echo "  This is the latest version and may have fixed toolchain issues!"
elif [ "$HTTP_CODE_5_0" = "200" ]; then
    echo -e "${YELLOW}⚠ FALLBACK: Tizen Studio 5.0 will be used${NC}"
    echo "  Version 6.1 not available, using 5.0 (known toolchain issues)"
else
    echo -e "${RED}✗ ERROR: No Tizen Studio version available${NC}"
fi

echo ""
