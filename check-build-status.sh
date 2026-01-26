#!/bin/bash

echo "=========================================="
echo "Kodi Tizen Build Status Check"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_section() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}"
    echo ""
}

# Check 1: Local TPK files
print_section "1. Checking for TPK Files Locally"

TPK_FILES=$(find . -name "*.tpk" -type f 2>/dev/null)
if [ -n "$TPK_FILES" ]; then
    echo -e "${GREEN}✓ Found TPK files:${NC}"
    echo "$TPK_FILES" | while read file; do
        ls -lh "$file"
    done
else
    echo -e "${YELLOW}✗ No TPK files found locally${NC}"
fi

# Check 2: Build directory
print_section "2. Checking Build Directory"

if [ -d "build" ]; then
    echo -e "${GREEN}✓ Build directory exists${NC}"
    echo "Contents:"
    ls -lh build/ | head -20
else
    echo -e "${YELLOW}✗ No build directory found${NC}"
fi

# Check 3: Container status
print_section "3. Checking Container Status"

if command -v podman &> /dev/null; then
    CONTAINERS=$(podman ps -a --filter ancestor=localhost/kodi-tizen-builder --format "{{.ID}} {{.Status}} {{.Names}}")
    if [ -n "$CONTAINERS" ]; then
        echo -e "${GREEN}✓ Found Kodi build container(s):${NC}"
        echo "$CONTAINERS"
        
        # Check if build ran inside container
        CONTAINER_ID=$(echo "$CONTAINERS" | head -1 | awk '{print $1}')
        echo ""
        echo "Checking inside container..."
        
        if podman exec "$CONTAINER_ID" test -d /workspace/build 2>/dev/null; then
            echo -e "${GREEN}✓ Build directory exists in container${NC}"
            podman exec "$CONTAINER_ID" ls -lh /workspace/build 2>/dev/null | head -10
        else
            echo -e "${YELLOW}✗ No build directory in container${NC}"
        fi
        
        if podman exec "$CONTAINER_ID" test -d /home/builder/tizen-studio 2>/dev/null; then
            echo -e "${GREEN}✓ Tizen SDK installed in container${NC}"
        else
            echo -e "${YELLOW}✗ Tizen SDK not installed in container${NC}"
        fi
        
        if podman exec "$CONTAINER_ID" test -d /home/builder/kodi-tizen-deps 2>/dev/null; then
            echo -e "${GREEN}✓ Dependencies built in container${NC}"
        else
            echo -e "${YELLOW}✗ Dependencies not built in container${NC}"
        fi
    else
        echo -e "${YELLOW}✗ No Kodi build container found${NC}"
    fi
else
    echo -e "${YELLOW}✗ Podman not found${NC}"
fi

# Check 4: GitHub Actions
print_section "4. Checking GitHub Actions Build"

echo "Fetching latest build status..."
STATUS=$(curl -s 'https://api.github.com/repos/creolben/kodi-tizen/actions/runs?per_page=1' 2>/dev/null)

if [ -n "$STATUS" ]; then
    BUILD_STATUS=$(echo "$STATUS" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
    BUILD_CONCLUSION=$(echo "$STATUS" | grep -o '"conclusion":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    echo "Status: $BUILD_STATUS"
    echo "Conclusion: $BUILD_CONCLUSION"
    
    if [ "$BUILD_STATUS" = "completed" ] && [ "$BUILD_CONCLUSION" = "success" ]; then
        echo -e "${GREEN}✓ GitHub Actions build completed successfully!${NC}"
        echo ""
        echo "Download TPK from:"
        echo "  https://github.com/creolben/kodi-tizen/actions"
        echo ""
        echo "Look for 'Artifacts' section in the latest successful run."
    elif [ "$BUILD_STATUS" = "in_progress" ]; then
        echo -e "${YELLOW}⏳ GitHub Actions build is in progress${NC}"
    elif [ "$BUILD_STATUS" = "queued" ]; then
        echo -e "${YELLOW}⏳ GitHub Actions build is queued${NC}"
    else
        echo -e "${YELLOW}Build status: $BUILD_STATUS${NC}"
    fi
else
    echo -e "${YELLOW}✗ Could not fetch GitHub Actions status${NC}"
fi

# Summary and Recommendations
print_section "Summary and Recommendations"

HAS_LOCAL_TPK=false
HAS_LOCAL_BUILD=false
HAS_CONTAINER=false
CONTAINER_READY=false

[ -n "$TPK_FILES" ] && HAS_LOCAL_TPK=true
[ -d "build" ] && HAS_LOCAL_BUILD=true
[ -n "$CONTAINERS" ] && HAS_CONTAINER=true

if [ "$HAS_CONTAINER" = true ]; then
    CONTAINER_ID=$(echo "$CONTAINERS" | head -1 | awk '{print $1}')
    if podman exec "$CONTAINER_ID" test -d /home/builder/tizen-studio 2>/dev/null; then
        CONTAINER_READY=true
    fi
fi

echo "Current Status:"
echo "  Local TPK files: $([ "$HAS_LOCAL_TPK" = true ] && echo -e "${GREEN}Yes${NC}" || echo -e "${YELLOW}No${NC}")"
echo "  Local build dir: $([ "$HAS_LOCAL_BUILD" = true ] && echo -e "${GREEN}Yes${NC}" || echo -e "${YELLOW}No${NC}")"
echo "  Container running: $([ "$HAS_CONTAINER" = true ] && echo -e "${GREEN}Yes${NC}" || echo -e "${YELLOW}No${NC}")"
echo "  Container ready: $([ "$CONTAINER_READY" = true ] && echo -e "${GREEN}Yes${NC}" || echo -e "${YELLOW}No${NC}")"

echo ""
echo -e "${BLUE}Recommended Actions:${NC}"
echo ""

if [ "$HAS_LOCAL_TPK" = true ]; then
    echo -e "${GREEN}✓ You have TPK files! Ready to install.${NC}"
    echo "  Run: ./install-kodi-now.sh"
elif [ "$BUILD_STATUS" = "completed" ] && [ "$BUILD_CONCLUSION" = "success" ]; then
    echo -e "${GREEN}✓ GitHub Actions build is complete!${NC}"
    echo "  1. Go to: https://github.com/creolben/kodi-tizen/actions"
    echo "  2. Click latest successful run"
    echo "  3. Download TPK from Artifacts section"
    echo "  4. Run: ./install-kodi-now.sh"
elif [ "$HAS_CONTAINER" = true ] && [ "$CONTAINER_READY" = false ]; then
    echo -e "${YELLOW}⚠ Container exists but build hasn't run${NC}"
    echo "  Start the build:"
    echo "    podman exec -it $CONTAINER_ID bash"
    echo "    ~/build-kodi.sh"
elif [ "$HAS_CONTAINER" = true ] && [ "$CONTAINER_READY" = true ]; then
    echo -e "${YELLOW}⚠ Container is ready but build incomplete${NC}"
    echo "  Continue the build:"
    echo "    podman exec -it $CONTAINER_ID bash"
    echo "    ~/build-kodi.sh"
else
    echo -e "${YELLOW}⚠ No build in progress${NC}"
    echo "  Option 1 - Wait for GitHub Actions (easiest):"
    echo "    Check: https://github.com/creolben/kodi-tizen/actions"
    echo ""
    echo "  Option 2 - Start local build:"
    echo "    ./setup-local-build.sh"
    echo "    podman exec -it kodi-tizen-build bash"
    echo "    ~/build-kodi.sh"
fi

echo ""
