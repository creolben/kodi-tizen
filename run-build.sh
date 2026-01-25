#!/bin/bash
# Run the Kodi Tizen build in Podman

echo "=== Starting Kodi Tizen Build ==="
echo ""
echo "This will take approximately 1.5-2 hours for the first build."
echo "The build log will be saved to build.log"
echo ""
echo "You can monitor progress in another terminal with:"
echo "  tail -f build.log"
echo ""
echo "Starting build..."
echo ""

# Run the build and save output to log
podman run --platform linux/amd64 \
  -v $(pwd):/home/builder/workspace:Z \
  kodi-tizen-builder \
  bash /home/builder/workspace/container-build.sh 2>&1 | tee build.log

echo ""
echo "=== Build Complete ==="
echo ""
echo "Check for TPK file:"
ls -lh build/*.tpk 2>/dev/null || echo "No TPK file found - check build.log for errors"
