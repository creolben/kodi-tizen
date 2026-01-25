# Installing HAXM for Tizen Emulator on macOS

## Problem

The Tizen emulator requires hardware acceleration to run. On macOS, this is provided by Intel HAXM (Hardware Accelerated Execution Manager).

**Error you're seeing:**
```
Error: Failed to start this VM.
Your system cannot support HW virtualization.
Try install KVM (ubuntu) or HAX (windows or Mac)
```

## Solution: Install HAXM

### Option 1: Install via Tizen Studio Package Manager (Recommended)

1. **Open Package Manager:**
   ```bash
   ~/tizen-studio/package-manager/package-manager
   ```

2. **Install HAXM:**
   - Go to the **Main SDK** tab
   - Expand **Tizen SDK Tools**
   - Find and check **Intel Hardware Accelerated Execution Manager (HAXM)**
   - Click **Install**

3. **Run the HAXM Installer:**
   After Package Manager downloads HAXM, you need to run the installer:
   ```bash
   # The installer will be downloaded to:
   open ~/tizen-studio/tools/emulator/haxm/
   
   # Double-click the .dmg file and run the installer
   ```

4. **Follow the installer prompts:**
   - Accept the license
   - Choose memory allocation (2048 MB minimum, 4096 MB recommended)
   - Complete installation
   - **You may need to restart your Mac**

### Option 2: Download HAXM Directly

If Package Manager doesn't work, download HAXM directly:

1. **Download HAXM:**
   - Visit: https://github.com/intel/haxm/releases
   - Download the latest macOS .dmg file (e.g., `haxm-7.8.0.dmg`)

2. **Install:**
   - Open the .dmg file
   - Run the installer
   - Follow the prompts
   - Restart your Mac if prompted

### Option 3: Install via Homebrew

```bash
# Install HAXM via Homebrew Cask
brew install --cask intel-haxm
```

## Verification

After installation, verify HAXM is working:

```bash
# Check if HAXM kernel extension is loaded
kextstat | grep -i intelhaxm

# Or check system extensions (macOS 11+)
systemextensionsctl list | grep -i intel
```

You should see output indicating the Intel HAXM extension is loaded.

## macOS Security Settings

### For macOS 10.13+ (High Sierra and later)

If the installer fails or HAXM doesn't load, you may need to allow the kernel extension:

1. **Open System Preferences**
2. Go to **Security & Privacy**
3. Click the **General** tab
4. Look for a message about blocked system extension from Intel
5. Click **Allow**
6. Restart your Mac

### For macOS 11+ (Big Sur and later)

macOS 11+ uses System Extensions instead of Kernel Extensions:

1. The installer should handle this automatically
2. If prompted, allow the system extension in System Preferences
3. You may need to restart in Recovery Mode to allow the extension

## Troubleshooting

### Issue: "System Extension Blocked"

**Solution:**
1. Open **System Preferences** → **Security & Privacy**
2. Click **Allow** next to the Intel message
3. Restart your Mac

### Issue: "Installation Failed"

**Solution:**
1. Ensure you have admin privileges
2. Disable any antivirus software temporarily
3. Try installing in Safe Mode:
   - Restart Mac and hold Shift key
   - Install HAXM
   - Restart normally

### Issue: "HAXM is not compatible with macOS"

**Solution:**
- Check your macOS version
- HAXM requires macOS 10.10 or later
- For Apple Silicon Macs (M1/M2), HAXM is not supported
  - See "Alternative for Apple Silicon" below

### Issue: "Not enough memory"

**Solution:**
1. Close other applications
2. Allocate less memory to HAXM (minimum 2048 MB)
3. Increase your Mac's RAM if possible

## Alternative for Apple Silicon Macs (M1/M2/M3)

**Important:** HAXM only works on Intel Macs. If you have an Apple Silicon Mac (M1/M2/M3), you have two options:

### Option 1: Use Rosetta 2 (Limited Support)

Some emulators may work under Rosetta 2, but performance will be poor:

```bash
# Install Rosetta 2 if not already installed
softwareupdate --install-rosetta
```

### Option 2: Use a Real Samsung TV (Recommended)

For Apple Silicon Macs, testing on a real Samsung TV is the best option:

1. Enable Developer Mode on your TV
2. Connect via SDB
3. Deploy and test directly on hardware

See: `tools/tizen/TV_CONNECTION_GUIDE.md`

### Option 3: Use a Cloud-Based Solution

Consider using a cloud VM with Intel processor:
- AWS EC2 (Intel instances)
- Google Cloud Compute Engine
- Azure Virtual Machines

## After Installation

Once HAXM is installed:

1. **Restart your Mac** (important!)

2. **Verify installation:**
   ```bash
   kextstat | grep -i intelhaxm
   ```

3. **Try launching the emulator again:**
   ```bash
   ./tools/tizen/setup-emulator.sh
   ```

## Memory Allocation

HAXM needs to allocate memory for virtual machines. Recommended settings:

| Your Mac's RAM | HAXM Allocation | Emulator RAM |
|----------------|-----------------|--------------|
| 8 GB | 2048 MB | 1024 MB |
| 16 GB | 4096 MB | 2048 MB |
| 32 GB+ | 8192 MB | 4096 MB |

You can adjust HAXM memory allocation by:
1. Running the HAXM installer again
2. Choosing a different memory size
3. Restarting your Mac

## Quick Check Script

Run this to check your setup:

```bash
#!/bin/bash
echo "Checking HAXM installation..."
echo ""

# Check if Intel Mac
if sysctl -n machdep.cpu.brand_string | grep -q "Intel"; then
    echo "✓ Intel Mac detected"
    
    # Check virtualization support
    if sysctl kern.hv_support | grep -q "1"; then
        echo "✓ Virtualization supported"
    else
        echo "✗ Virtualization not supported"
    fi
    
    # Check HAXM
    if kextstat | grep -qi intelhaxm; then
        echo "✓ HAXM is installed and loaded"
    else
        echo "✗ HAXM is not loaded"
        echo "  Please install HAXM and restart your Mac"
    fi
else
    echo "⚠ Apple Silicon Mac detected"
    echo "  HAXM is not compatible with Apple Silicon"
    echo "  Please use a real Samsung TV for testing"
fi
```

Save this as `check-haxm.sh` and run it:

```bash
chmod +x check-haxm.sh
./check-haxm.sh
```

## Next Steps

After installing HAXM and restarting:

1. **Launch the emulator:**
   ```bash
   ./tools/tizen/setup-emulator.sh
   ```

2. **If it still fails:**
   - Check the emulator logs: `~/tizen-studio/tools/emulator/logs/`
   - Verify HAXM is loaded: `kextstat | grep -i intelhaxm`
   - Try launching manually: `emulator-manager`

3. **If you can't get the emulator working:**
   - Use a real Samsung TV instead
   - See: `tools/tizen/TV_CONNECTION_GUIDE.md`

## Support Resources

- **HAXM GitHub:** https://github.com/intel/haxm
- **Tizen Emulator Docs:** https://developer.tizen.org/development/tizen-studio/native-tools/emulator
- **macOS Security:** https://support.apple.com/guide/mac-help/mh40616/mac

## Summary

1. Install HAXM via Package Manager or direct download
2. Allow the system extension in Security & Privacy
3. Restart your Mac
4. Verify HAXM is loaded
5. Try launching the emulator again

Good luck! 🚀
