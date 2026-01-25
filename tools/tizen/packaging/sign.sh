#!/bin/bash

# Kodi Tizen TPK Signing Script
# This script signs a Tizen Package (TPK) file with a certificate

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Display usage
usage() {
    echo "Usage: $0 [OPTIONS] <tpk-file>"
    echo ""
    echo "Options:"
    echo "  -p, --profile <name>    Security profile name (default: from TIZEN_SECURITY_PROFILE)"
    echo "  -o, --output <path>     Output path for signed TPK (default: overwrites input)"
    echo "  -h, --help              Display this help message"
    echo ""
    echo "Environment Variables:"
    echo "  TIZEN_SDK               Path to Tizen Studio installation (required)"
    echo "  TIZEN_SECURITY_PROFILE  Default security profile name"
    echo ""
    echo "Examples:"
    echo "  $0 org.xbmc.kodi-21.0.0.tpk"
    echo "  $0 -p my-profile -o signed.tpk org.xbmc.kodi-21.0.0.tpk"
    exit 1
}

# Parse command line arguments
SECURITY_PROFILE="${TIZEN_SECURITY_PROFILE}"
OUTPUT_PATH=""
TPK_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--profile)
            SECURITY_PROFILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [ -z "$TPK_FILE" ]; then
                TPK_FILE="$1"
            else
                log_error "Unknown argument: $1"
                usage
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$TPK_FILE" ]; then
    log_error "TPK file not specified"
    usage
fi

if [ ! -f "$TPK_FILE" ]; then
    log_error "TPK file not found: $TPK_FILE"
    exit 1
fi

# Check TIZEN_SDK
if [ -z "$TIZEN_SDK" ]; then
    log_error "TIZEN_SDK environment variable not set"
    log_error "Please set TIZEN_SDK to your Tizen Studio installation path"
    exit 1
fi

if [ ! -d "$TIZEN_SDK" ]; then
    log_error "TIZEN_SDK directory not found: $TIZEN_SDK"
    exit 1
fi

# Check for tizen CLI tool
TIZEN_CLI="$TIZEN_SDK/tools/ide/bin/tizen"
if [ ! -f "$TIZEN_CLI" ]; then
    log_error "Tizen CLI tool not found at: $TIZEN_CLI"
    exit 1
fi

# Validate security profile
validate_certificate() {
    log_info "Validating security profile..."
    
    if [ -z "$SECURITY_PROFILE" ]; then
        log_error "Security profile not specified"
        log_error "Set TIZEN_SECURITY_PROFILE environment variable or use -p option"
        exit 1
    fi
    
    # Check if profile exists
    "$TIZEN_CLI" security-profiles list 2>/dev/null | grep -q "$SECURITY_PROFILE" || {
        log_error "Security profile '$SECURITY_PROFILE' not found"
        log_error "Available profiles:"
        "$TIZEN_CLI" security-profiles list 2>/dev/null || echo "  (none)"
        echo ""
        log_error "Create a security profile using Tizen Studio Certificate Manager"
        exit 1
    }
    
    log_info "Security profile '$SECURITY_PROFILE' validated"
}

# Sign the TPK
sign_tpk() {
    log_info "Signing TPK with profile '$SECURITY_PROFILE'..."
    
    local TEMP_DIR=$(mktemp -d)
    local TPK_BASENAME=$(basename "$TPK_FILE")
    local UNSIGNED_TPK="$TEMP_DIR/$TPK_BASENAME"
    
    # Copy TPK to temp directory
    cp "$TPK_FILE" "$UNSIGNED_TPK"
    
    # Sign using tizen CLI
    "$TIZEN_CLI" package -t tpk -s "$SECURITY_PROFILE" -- "$UNSIGNED_TPK" || {
        log_error "Failed to sign TPK"
        rm -rf "$TEMP_DIR"
        exit 1
    }
    
    # Determine output path
    if [ -z "$OUTPUT_PATH" ]; then
        OUTPUT_PATH="$TPK_FILE"
    fi
    
    # Move signed TPK to output location
    local SIGNED_TPK="$TEMP_DIR/$TPK_BASENAME"
    if [ -f "$SIGNED_TPK" ]; then
        mv "$SIGNED_TPK" "$OUTPUT_PATH"
        log_info "Signed TPK saved to: $OUTPUT_PATH"
    else
        log_error "Signed TPK not found after signing"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
}

# Verify signature
verify_signature() {
    log_info "Verifying TPK signature..."
    
    # Extract signature info using unzip
    local SIG_CHECK=$(unzip -l "$OUTPUT_PATH" 2>/dev/null | grep -c "signature" || echo "0")
    
    if [ "$SIG_CHECK" -gt 0 ]; then
        log_info "TPK signature verified (signature files present)"
    else
        log_warn "Could not verify signature (signature files not found)"
    fi
}

# Display certificate information
display_cert_info() {
    log_info "Certificate Information:"
    
    "$TIZEN_CLI" security-profiles list 2>/dev/null | grep -A 10 "$SECURITY_PROFILE" || {
        log_warn "Could not retrieve certificate details"
        return
    }
}

# Main execution
main() {
    log_info "Starting Kodi Tizen TPK signing process..."
    echo ""
    
    validate_certificate
    sign_tpk
    verify_signature
    
    echo ""
    display_cert_info
    
    echo ""
    log_info "Signing completed successfully!"
    echo ""
    echo "Signed TPK: $OUTPUT_PATH"
    echo ""
    echo "To install on device:"
    echo "  sdb install $OUTPUT_PATH"
}

# Run main function
main "$@"
