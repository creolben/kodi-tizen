#!/bin/bash
set -e

echo "=========================================="
echo "Rebuilding Container with Non-Root User"
echo "=========================================="
echo ""
echo "The Tizen SDK requires a non-root user."
echo "Rebuilding container with 'builder' user..."
echo ""

# Stop and remove existing container
echo "Stopping existing container..."
podman stop $(podman ps -q --filter ancestor=localhost/kodi-tizen-builder) 2>/dev/null || true

# Rebuild the image
echo "Rebuilding container image..."
podman build --platform linux/amd64 -t kodi-tizen-builder -f Containerfile.tizen .

echo ""
echo "✓ Container rebuilt successfully!"
echo ""
echo "Now run the container with:"
echo "  podman run --platform linux/amd64 -v \$(pwd):/workspace:Z -it localhost/kodi-tizen-builder"
echo ""
