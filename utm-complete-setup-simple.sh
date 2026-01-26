#!/bin/bash
# Simplified UTM VM Setup Script for Kodi Tizen Build
# This script guides you through the setup process step by step

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

print_step "UTM Complete Setup for Kodi Tizen Build"

# Step 1: Check prerequisites
print_step "Step 1: Checking Prerequisites"

if ! osascript -e 'tell application "UTM" to get version' &> /dev/null; then
    print_error "UTM is not installed. Install with: brew install --cask utm"
    exit 1
fi
print_success "UTM is installed"

if [ ! -f "$ISO_PATH" ]; then
    print_error "Ubuntu ISO not found at: $ISO_PATH"
    echo "Download it from: https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.5-live-server-arm64.iso"
    exit 1
fi
print_success "Ubuntu ISO found"

# Step 2: Check if VM exists
print_step "Step 2: Checking VM Status"

VM_EXISTS=$(osascript -e "tell application \"UTM\" to get name of every virtual machine" 2>/dev/null | grep -w "$VM_NAME" || echo "")

if [ -n "$VM_EXISTS" ]; then
    print_warning "VM '$VM_NAME' already exists"
    VM_STATUS=$(osascript -e "tell application \"UTM\" to get status of virtual machine \"$VM_NAME\"")
    echo "Current status: $VM_STATUS"
    echo ""
    echo "Options:"
    echo "  1) Use existing VM (recommended if Ubuntu is installed)"
    echo "  2) Delete and recreate VM"
    echo "  3) Exit"
    read -p "Choose option (1-3): " choice
    
    case $choice in
        1)
            print_step "Using existing VM"
            if [ "$VM_STATUS" = "stopped" ]; then
                osascript -e "tell application \"UTM\" to start virtual machine \"$VM_NAME\""
                print_success "VM started"
            fi
            SKIP_CREATION=true
            ;;
        2)
            print_step "Deleting existing VM"
            osascript -e "tell application \"UTM\" to delete virtual machine \"$VM_NAME\"" 2>/dev/null || true
            sleep 2
            print_success "VM deleted"
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
fi

# Step 3: Create VM if needed
if [ -z "$SKIP_CREATION" ]; then
    print_step "Step 3: Creating UTM VM"
    
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
    
    print_step "Step 4: Starting VM"
    osascript -e "tell application \"UTM\" to start virtual machine \"$VM_NAME\""
    print_success "VM started"
    sleep 3
    
    print_step "Ubuntu Installation Instructions"
    echo "The VM window should now be open showing Ubuntu installer."
    echo ""
    echo "Complete the installation with these settings:"
    echo ""
    echo "  ${BLUE}Language:${NC} English"
    echo "  ${BLUE}Keyboard:${NC} Your preference"
    echo "  ${BLUE}Installation type:${NC} Ubuntu Server"
    echo "  ${BLUE}Network:${NC} Use defaults (DHCP)"
    echo "  ${BLUE}Storage:${NC} Use entire disk (default)"
    echo ""
    echo "  ${BLUE}Profile setup:${NC}"
    echo "    Your name: ${GREEN}builder${NC}"
    echo "    Server name: ${GREEN}kodi-builder${NC}"
    echo "    Username: ${GREEN}builder${NC}"
    echo "    Password: ${GREEN}(choose a secure password)${NC}"
    echo ""
    echo "  ${BLUE}SSH:${NC} ${GREEN}✓ Enable OpenSSH server${NC} (IMPORTANT!)"
    echo "  ${BLUE}Featured snaps:${NC} Skip (press Tab, Enter)"
    echo ""
    echo "Installation takes about 10-15 minutes."
    echo ""
    echo "After installation completes:"
    echo "  1. VM will reboot"
    echo "  2. ${YELLOW}Shut down the VM${NC}"
    echo "  3. In UTM, go to VM settings → CD/DVD → Clear ISO"
    echo "  4. Start the VM again"
    echo "  5. Log in with username: builder"
    echo ""
    read -p "Press Enter when Ubuntu is installed, ISO removed, and you're logged in..."
else
    print_step "Step 3: VM Already Exists"
    echo "Make sure the VM is running and you can log in."
    read -p "Press Enter when you're logged into Ubuntu..."
fi

# Step 5: Get VM IP
print_step "Step 5: Getting VM IP Address"

echo "Attempting to detect VM IP..."
sleep 3

VM_IP=$(osascript -e "tell application \"UTM\" to get address of virtual machine \"$VM_NAME\"" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1 || echo "")

if [ -n "$VM_IP" ]; then
    print_success "VM IP detected: $VM_IP"
else
    print_warning "Could not auto-detect VM IP"
    echo ""
    echo "In the VM terminal, run this command:"
    echo "  ${BLUE}ip addr show | grep 'inet ' | grep -v 127.0.0.1${NC}"
    echo ""
    read -p "Enter the VM IP address: " VM_IP
fi

# Step 6: Test SSH
print_step "Step 6: Testing SSH Connection"

echo "Testing SSH to $VM_IP..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no builder@$VM_IP "echo 'SSH works'" 2>/dev/null; then
    print_success "SSH connection successful"
else
    print_warning "SSH connection failed"
    echo ""
    echo "Please ensure OpenSSH is installed in the VM:"
    echo "  ${BLUE}sudo apt update && sudo apt install -y openssh-server${NC}"
    echo ""
    read -p "Press Enter after installing OpenSSH..."
    
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no builder@$VM_IP "echo 'SSH works'" 2>/dev/null; then
        print_success "SSH connection successful"
    else
        print_error "Still cannot connect via SSH"
        echo "Please check:"
        echo "  1. VM is running"
        echo "  2. IP address is correct: $VM_IP"
        echo "  3. OpenSSH server is running: sudo systemctl status ssh"
        exit 1
    fi
fi

# Step 7: Transfer and run setup script
print_step "Step 7: Setting Up Build Environment"

if [ ! -f "utm-setup-script.sh" ]; then
    print_error "utm-setup-script.sh not found"
    exit 1
fi

echo "Transferring setup script to VM..."
scp -o StrictHostKeyChecking=no utm-setup-script.sh builder@$VM_IP:~/
print_success "Script transferred"

echo ""
echo "Now running setup script in VM..."
echo "This will install:"
echo "  - System updates"
echo "  - Build dependencies (gcc, cmake, git, etc.)"
echo "  - Tizen SDK (~500MB download)"
echo "  - Tizen toolchain"
echo "  - Clone Kodi repository"
echo "  - Apply C++17 patches"
echo ""
echo "Estimated time: 15-20 minutes"
echo ""
read -p "Press Enter to start setup..."

ssh -t builder@$VM_IP "bash ~/utm-setup-script.sh"

# Final summary
print_step "Setup Complete! 🎉"

echo -e "${GREEN}Your UTM VM is ready for building Kodi!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "${BLUE}VM Connection Info:${NC}"
echo "  Name: $VM_NAME"
echo "  IP: $VM_IP"
echo "  User: builder"
echo ""
echo "${BLUE}To SSH into VM:${NC}"
echo "  ${GREEN}ssh builder@$VM_IP${NC}"
echo ""
echo "${BLUE}To build Kodi (60-90 minutes):${NC}"
echo "  ${GREEN}ssh builder@$VM_IP${NC}"
echo "  ${GREEN}bash ~/build-kodi.sh${NC}"
echo ""
echo "${BLUE}Or build in one command:${NC}"
echo "  ${GREEN}ssh builder@$VM_IP 'bash ~/build-kodi.sh'${NC}"
echo ""
echo "${BLUE}After build completes, copy TPK to macOS:${NC}"
echo "  ${GREEN}scp builder@$VM_IP:~/kodi-tizen/build/*.tpk ~/Downloads/${NC}"
echo ""
echo "${BLUE}VM Management:${NC}"
echo "  Start:  ${GREEN}osascript -e 'tell application \"UTM\" to start virtual machine \"$VM_NAME\"'${NC}"
echo "  Stop:   ${GREEN}osascript -e 'tell application \"UTM\" to stop virtual machine \"$VM_NAME\"'${NC}"
echo "  Status: ${GREEN}osascript -e 'tell application \"UTM\" to get status of virtual machine \"$VM_NAME\"'${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Save connection info
cat > utm-vm-info.txt << EOF
UTM VM Connection Info
======================

VM Name: $VM_NAME
IP Address: $VM_IP
Username: builder

Quick Commands:
---------------

SSH into VM:
  ssh builder@$VM_IP

Build Kodi:
  ssh builder@$VM_IP 'bash ~/build-kodi.sh'

Copy TPK to macOS:
  scp builder@$VM_IP:~/kodi-tizen/build/*.tpk ~/Downloads/

VM Management:
  Start:  osascript -e 'tell application "UTM" to start virtual machine "$VM_NAME"'
  Stop:   osascript -e 'tell application "UTM" to stop virtual machine "$VM_NAME"'
  Status: osascript -e 'tell application "UTM" to get status of virtual machine "$VM_NAME"'

Build Time: 60-90 minutes
TPK Location: ~/kodi-tizen/build/*.tpk
EOF

print_success "Connection info saved to: utm-vm-info.txt"
echo ""
echo "Next step: Run the build!"
echo "  ${GREEN}ssh builder@$VM_IP 'bash ~/build-kodi.sh'${NC}"
