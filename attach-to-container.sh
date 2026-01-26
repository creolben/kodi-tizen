#!/bin/bash

echo "Attaching to running container..."
echo ""
echo "Once inside, run this command:"
echo "  chmod +x /workspace/container-build-as-root.sh && /workspace/container-build-as-root.sh"
echo ""
echo "Press Enter to continue..."
read

podman exec -it 78b72566c034 bash
