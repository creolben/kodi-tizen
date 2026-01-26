#!/bin/bash

echo "Monitoring Kodi Tizen Build Progress..."
echo "========================================"
echo ""

while true; do
    clear
    echo "=== Build Status Check ==="
    echo "Time: $(date)"
    echo ""
    
    # Check if build process is running
    BUILD_RUNNING=$(podman exec fbe0eaf11081 bash -c "ps aux | grep -E 'make|gcc|g\+\+' | grep -v grep | wc -l" 2>/dev/null)
    
    if [ "$BUILD_RUNNING" -gt 0 ]; then
        echo "✓ Build is RUNNING ($BUILD_RUNNING processes)"
        echo ""
        echo "Active processes:"
        podman exec fbe0eaf11081 bash -c "ps aux | grep -E 'make|gcc|g\+\+' | grep -v grep | head -5" 2>/dev/null
    else
        echo "⏸ Build appears to be idle or complete"
    fi
    
    echo ""
    echo "=== Recent Build Output ==="
    podman exec fbe0eaf11081 bash -c "tail -20 /workspace/tools/depends/build.log 2>/dev/null || tail -20 /workspace/build/build.log 2>/dev/null || echo 'No build log available yet'"
    
    echo ""
    echo "=== Checking for TPK files ==="
    TPK_COUNT=$(podman exec fbe0eaf11081 bash -c "find /workspace -name '*.tpk' 2>/dev/null | wc -l")
    if [ "$TPK_COUNT" -gt 0 ]; then
        echo "✓ Found $TPK_COUNT TPK file(s)!"
        podman exec fbe0eaf11081 bash -c "find /workspace -name '*.tpk' -exec ls -lh {} \;"
        echo ""
        echo "BUILD COMPLETE!"
        break
    else
        echo "No TPK files yet..."
    fi
    
    echo ""
    echo "Press Ctrl+C to stop monitoring"
    echo "Refreshing in 30 seconds..."
    sleep 30
done
