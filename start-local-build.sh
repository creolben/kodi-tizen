#!/bin/bash

echo "=========================================="
echo "Starting Local Kodi Build"
echo "=========================================="
echo ""

# Check if container is running
if ! podman ps | grep -q "kodi-tizen-build"; then
    echo "Container not running. Setting up..."
    ./setup-local-build.sh
fi

CONTAINER_ID=$(podman ps --filter name=kodi-tizen-build --format "{{.ID}}")

if [ -z "$CONTAINER_ID" ]; then
    echo "Error: Could not find container"
    echo "Run: ./setup-local-build.sh"
    exit 1
fi

echo "Found container: $CONTAINER_ID"
echo ""
echo "Starting build inside container..."
echo "This will take 60-90 minutes."
echo ""
echo "You can monitor progress in another terminal with:"
echo "  podman exec $CONTAINER_ID tail -f /home/builder/kodi-tizen-deps/build.log"
echo ""
echo "Press Ctrl+C to detach (build will continue in background)"
echo ""
sleep 3

# Execute build in container
podman exec -it "$CONTAINER_ID" /home/builder/build-kodi.sh

echo ""
echo "Build complete! Check for TPK file:"
echo "  ls -lh build/*.tpk"
echo ""
