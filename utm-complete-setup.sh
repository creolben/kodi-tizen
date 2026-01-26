#!/bin/bash
# Complete UTM VM Setup Script for Kodi Tizen Build
# This script automates VM creation, Ubuntu installation monitoring, and dependency setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Configuration
VM_NAME="kodi-tizen-builder"
ISO_PATH="$HOME/Downloads/ubuntu-22.04.5-live-server-arm64.iso"
VM_USER="builder"
VM_PASSWORD=""  # Will prompt user

print_step "UTM Complete Setup for Kodi Tizen Build"

# Step 1: Check prerequisites
print_step "Step 1/7: Checking Prerequisites"

# Check if UTM is installed
if ! command -v osascript &> /dev/null; then
    print_error "osascript not found. This script requires macOS."
    exit 1
fi

if ! osascript -e 'tell application "UTM" to get version' &> /dev/null; then
    print_error "UTM is not installed. Install with: brew install --cask utm"
    exit 1
fi
print_success "UTM is installed"

# Check if ISO exists
if [ ! -f "$ISO_PATH" ]; then
    print_error "Ubuntu ISO not found at: $ISO_PATH"
    echo "Download it from: https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.5-live-server-arm64.iso"
    exit 1
fi
print_success "Ubuntu ISO found"

# Step 2: Check if VM already exists
print_step "Step 2/7: Checking VM Status"

VM_EXISTS=$(osascript -e "tell application \"UTM\" to get name of every virtual machine" 2>/dev/null | grep -w "$VM_NAME" || echo "")

if [ -n "$VM_EXISTS" ]; then
    print_warning "VM '$VM_NAME' already exists"
    read -p "Do you want to delete and recreate it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Deleting existing VM..."
        osascript -e "tell application \"UTM\" to delete virtual machine \"$VM_NAME\"" 2>/dev/null || true
        sleep 2
        print_success "VM deleted"
    else
        print_step "Using existing VM..."
        VM_STATUS=$(osascript -e "tell application \"UTM\" to get status of virtual machine \"$VM_NAME\"")
        if [ "$VM_STATUS" = "stopped" ]; then
            print_step "Starting existing VM..."
            osascript -e "tell application \"UTM\" to start virtual machine \"$VM_NAME\""
            print_success "VM started"
        else
            print_success "VM is already running"
        fi
        
        # Skip to step 5 (wait for Ubuntu to be ready)
        echo ""
        print_warning "Skipping VM creation. Proceeding to Ubuntu setup..."
        sleep 2
        VM_ALREADY_EXISTS=true
    fi
fi

# Step 3: Create VM (if needed)
if [ -z "$VM_ALREADY_EXISTS" ]; then
    print_step "Step 3/7: Creating UTM VM"
    
    cat > /tmp/create-utm-vm.scpt << EOF
tell application "UTM"
    set iso to POSIX file "$ISO_PATH"
    set vm to make new virtual machine with properties {backend:apple, configuration:{name:"$VM_NAME", drives:{{removable:true, source:iso}, {guest size:102400}}}}
end tell
EOF
    
    if osascript /tmp/create-utm-vm.scpt 2>&1; then
        print_success "VM created successfully"
    else
        print_error "Failed to create VM"
        exit 1
    fi
    
    rm /tmp/create-utm-vm.scpt
    
    # Step 4: Start VM
    print_step "Step 4/7: Starting VM"
    osascript -e "tell application \"UTM\" to start virtual machine \"$VM_NAME\""
    print_success "VM started"
    
    # Wait for VM window to appear
    sleep 3
    
    print_step "Ubuntu Installation Required"
    echo "The VM is now running and Ubuntu installer should be visible."
    echo ""
    echo "Please complete the Ubuntu installation with these settings:"
    echo "  - Language: English"
    echo "  - Keyboard: Your preference"
    echo "  - Installation type: Ubuntu Server"
    echo "  - Network: Use defaults (DHCP)"
    echo "  - Storage: Use entire disk"
    echo "  - Profile setup:"
    echo "    - Your name: builder"
    echo "    - Server name: kodi-builder"
    echo "    - Username: builder"
    echo "    - Password: (choose a password)"
    echo "  - SSH: Enable OpenSSH server ✓"
    echo "  - Featured snaps: Skip"
    echo ""
    echo "After installation completes and the VM reboots:"
    echo "  1. Shut down the VM"
    echo "  2. Remove the ISO from VM settings"
    echo "  3. Start the VM again"
    echo ""
    read -p "Press Enter when Ubuntu is installed and VM has rebooted (logged in)..."
fi

# Step 5: Wait for Ubuntu to be ready
print_step "Step 5/7: Waiting for Ubuntu to be Ready"

echo "Attempting to detect VM IP address..."
sleep 5

# Try to get IP address
VM_IP=""
for i in {1..30}; do
    VM_IP=$(osascript -e "tell application \"UTM\" to get address of virtual machine \"$VM_NAME\"" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1 || echo "")
    if [ -n "$VM_IP" ]; then
        print_success "VM IP detected: $VM_IP"
        break
    fi
    echo "Waiting for VM network... ($i/30)"
    sleep 2
done

if [ -z "$VM_IP" ]; then
    print_warning "Could not auto-detect VM IP"
    echo "Please find the VM IP manually:"
    echo "  - In the VM terminal, run: ip addr show | grep 'inet '"
    read -p "Enter VM IP address: " VM_IP
fi

# Get VM password if not set
if [ -z "$VM_PASSWORD" ]; then
    echo ""
    read -sp "Enter VM password for user '$VM_USER': " VM_PASSWORD
    echo ""
fi

# Test SSH connection
print_step "Testing SSH Connection"
for i in {1..10}; do
    if sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$VM_USER@$VM_IP" "echo 'SSH connection successful'" 2>/dev/null; then
        print_success "SSH connection established"
        break
    fi
    if [ $i -eq 10 ]; then
        print_error "Could not establish SSH connection"
        echo "Please ensure:"
        echo "  1. VM is running and Ubuntu is booted"
        echo "  2. OpenSSH server is installed: sudo apt install openssh-server"
        echo "  3. IP address is correct: $VM_IP"
        exit 1
    fi
    echo "Waiting for SSH... ($i/10)"
    sleep 3
done

# Step 6: Transfer setup script
print_step "Step 6/7: Transferring Setup Script to VM"

if [ ! -f "utm-setup-script.sh" ]; then
    print_error "utm-setup-script.sh not found in current directory"
    exit 1
fi

sshpass -p "$VM_PASSWORD" scp -o StrictHostKeyChecking=no utm-setup-script.sh "$VM_USER@$VM_IP:~/"
print_success "Setup script transferred"

# Step 7: Run setup script in VM
print_step "Step 7/7: Running Setup Script in VM"

echo "This will install:"
echo "  - System updates"
echo "  - Build dependencies"
echo "  - Tizen SDK"
echo "  - Tizen toolchain"
echo "  - Clone Kodi repository"
echo "  - Apply C++17 patches"
echo ""
echo "This will take approximately 15-20 minutes..."
echo ""

sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no -t "$VM_USER@$VM_IP" "bash ~/utm-setup-script.sh"

# Final summary
print_step "Setup Complete! 🎉"

echo -e "${GREEN}Your UTM VM is ready for building Kodi!${NC}"
echo ""
echo "VM Details:"
echo "  Name: $VM_NAME"
echo "  IP: $VM_IP"
echo "  User: $VM_USER"
echo ""
echo "To SSH into the VM:"
echo "  ${BLUE}ssh $VM_USER@$VM_IP${NC}"
echo ""
echo "To build Kodi:"
echo "  ${BLUE}ssh $VM_USER@$VM_IP${NC}"
echo "  ${BLUE}cd ~/kodi-tizen${NC}"
echo "  ${BLUE}bash ~/build-kodi.sh${NC}"
echo ""
echo "Or use the quick build script that was created:"
echo "  ${BLUE}ssh $VM_USER@$VM_IP 'bash ~/build-kodi.sh'${NC}"
echo ""
echo "Build time estimate: 60-90 minutes"
echo ""
echo "After build completes, the TPK will be at:"
echo "  ${BLUE}~/kodi-tizen/build/*.tpk${NC}"
echo ""
echo "To copy TPK to macOS:"
echo "  ${BLUE}scp $VM_USER@$VM_IP:~/kodi-tizen/build/*.tpk ~/Downloads/${NC}"
echo ""

# Save connection info
cat > utm-vm-info.txt << EOF
UTM VM Connection Info
======================

VM Name: $VM_NAME
IP Address: $VM_IP
Username: $VM_USER

SSH Command:
ssh $VM_USER@$VM_IP

Build Command:
ssh $VM_USER@$VM_IP 'bash ~/build-kodi.sh'

Copy TPK:
scp $VM_USER@$VM_IP:~/kodi-tizen/build/*.tpk ~/Downloads/

VM Management:
- Start: osascript -e 'tell application "UTM" to start virtual machine "$VM_NAME"'
- Stop: osascript -e 'tell application "UTM" to stop virtual machine "$VM_NAME"'
- Status: osascript -e 'tell application "UTM" to get status of virtual machine "$VM_NAME"'
EOF

print_success "Connection info saved to: utm-vm-info.txt"
