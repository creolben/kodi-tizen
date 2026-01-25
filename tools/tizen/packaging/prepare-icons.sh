#!/bin/bash

# Kodi Tizen Icon Preparation Script
# This script prepares application icons for Tizen packaging

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ICON_DIR="$SCRIPT_DIR/icons"
MEDIA_DIR="$PROJECT_ROOT/media"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if ImageMagick is available for icon conversion
check_imagemagick() {
    if command -v convert >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Validate icon file
validate_icon() {
    local icon_file="$1"
    
    if [ ! -f "$icon_file" ]; then
        log_error "Icon file not found: $icon_file"
        return 1
    fi
    
    # Check if it's a PNG file
    if ! file "$icon_file" | grep -q "PNG"; then
        log_error "Icon is not a PNG file: $icon_file"
        return 1
    fi
    
    # Get dimensions if ImageMagick is available
    if check_imagemagick; then
        local dimensions=$(identify -format "%wx%h" "$icon_file" 2>/dev/null)
        local width=$(echo "$dimensions" | cut -d'x' -f1)
        local height=$(echo "$dimensions" | cut -d'x' -f2)
        
        log_info "Icon dimensions: ${width}x${height}"
        
        if [ "$width" -lt 117 ] || [ "$height" -lt 117 ]; then
            log_warn "Icon size is below recommended minimum (117x117)"
        fi
        
        if [ "$width" != "$height" ]; then
            log_warn "Icon is not square (${width}x${height})"
        fi
    fi
    
    return 0
}

# Copy icon from media directory
copy_from_media() {
    log_info "Copying icon from media directory..."
    
    # Prefer larger icons for better quality
    local source_icon=""
    
    if [ -f "$MEDIA_DIR/icon512x512.png" ]; then
        source_icon="$MEDIA_DIR/icon512x512.png"
        log_info "Using 512x512 icon"
    elif [ -f "$MEDIA_DIR/icon256x256.png" ]; then
        source_icon="$MEDIA_DIR/icon256x256.png"
        log_info "Using 256x256 icon"
    elif [ -f "$MEDIA_DIR/icon120x120.png" ]; then
        source_icon="$MEDIA_DIR/icon120x120.png"
        log_info "Using 120x120 icon"
    else
        log_error "No suitable icon found in media directory"
        return 1
    fi
    
    # Create icons directory if it doesn't exist
    mkdir -p "$ICON_DIR"
    
    # Copy icon
    cp "$source_icon" "$ICON_DIR/kodi.png"
    log_info "Icon copied to: $ICON_DIR/kodi.png"
    
    return 0
}

# Resize icon if ImageMagick is available
resize_icon() {
    local size="$1"
    
    if ! check_imagemagick; then
        log_warn "ImageMagick not available, skipping resize"
        return 1
    fi
    
    log_info "Resizing icon to ${size}x${size}..."
    
    local source="$ICON_DIR/kodi.png"
    local temp="$ICON_DIR/kodi_temp.png"
    
    convert "$source" -resize "${size}x${size}" "$temp"
    mv "$temp" "$source"
    
    log_info "Icon resized successfully"
    return 0
}

# Display icon information
display_info() {
    log_info "Icon Information:"
    
    if [ -f "$ICON_DIR/kodi.png" ]; then
        echo "  Location: $ICON_DIR/kodi.png"
        
        if check_imagemagick; then
            local dimensions=$(identify -format "%wx%h" "$ICON_DIR/kodi.png" 2>/dev/null)
            local size=$(du -h "$ICON_DIR/kodi.png" | cut -f1)
            echo "  Dimensions: $dimensions"
            echo "  File Size: $size"
        fi
        
        echo ""
        log_info "Icon is ready for packaging"
    else
        log_error "Icon file not found"
        return 1
    fi
}

# Main execution
main() {
    log_info "Preparing Kodi Tizen application icons..."
    echo ""
    
    # Check if icon already exists
    if [ -f "$ICON_DIR/kodi.png" ]; then
        log_info "Icon already exists, validating..."
        if validate_icon "$ICON_DIR/kodi.png"; then
            echo ""
            display_info
            return 0
        else
            log_warn "Existing icon is invalid, recreating..."
        fi
    fi
    
    # Copy icon from media directory
    if ! copy_from_media; then
        log_error "Failed to prepare icon"
        exit 1
    fi
    
    # Validate the copied icon
    if ! validate_icon "$ICON_DIR/kodi.png"; then
        log_error "Icon validation failed"
        exit 1
    fi
    
    # Optionally resize to optimal size (512x512)
    if check_imagemagick; then
        local current_size=$(identify -format "%w" "$ICON_DIR/kodi.png" 2>/dev/null)
        if [ "$current_size" -lt 512 ]; then
            log_info "Icon is smaller than optimal size, consider using a larger source"
        elif [ "$current_size" -gt 512 ]; then
            read -p "Resize icon to 512x512 for optimal size? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                resize_icon 512
            fi
        fi
    fi
    
    echo ""
    display_info
    
    echo ""
    log_info "Icon preparation completed successfully!"
}

# Run main function
main "$@"
