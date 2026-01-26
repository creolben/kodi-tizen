# Next Steps: Test Tizen Studio 6.1 Update

## What Just Happened

I've updated all build scripts and workflows to use **Tizen Studio 6.1** instead of 5.0, with automatic fallback to 5.0 if needed.

## Why This Matters

The root cause of all your build failures has been:
```
✗ Tizen SDK installation failed - toolchain not found
```

Tizen Studio 6.1 (released recently) may have fixed the toolchain package installation issues that plagued version 5.0.

## Files Updated

1. ✅ `.github/workflows/build-tizen.yml` - GitHub Actions workflow
2. ✅ `utm-setup-script.sh` - UTM VM setup script
3. ✅ `M4_LOCAL_BUILD_GUIDE.md` - Documentation
4. ✅ `UTM_STEP_BY_STEP.md` - Step-by-step guide
5. ✅ `TIZEN_SDK_6.1_UPDATE.md` - Detailed explanation (NEW)

## Test Option 1: GitHub Actions (Fastest) ⚡

**Time:** 5 minutes to trigger, 60-90 minutes to complete

```bash
# Commit and push the changes
git add .
git commit -m "Update to Tizen Studio 6.1 with fallback to 5.0"
git push origin main
```

Then:
1. Go to your GitHub repository
2. Click "Actions" tab
3. Watch the "Build Kodi for Tizen" workflow
4. Look for "Download and install Tizen SDK" step
5. Check if it downloads 6.1 or falls back to 5.0
6. Monitor "Install Tizen packages" step for success

**What to look for:**
```
✓ Tizen SDK 6.1 downloaded
✓ Toolchain installed successfully
✓ Build completes
✓ TPK file created
```

## Test Option 2: UTM VM (Local Control) 🖥️

**Time:** 2-3 hours (first time setup)

### Quick Start:

1. **Ensure UTM is installed:**
   ```bash
   brew install --cask utm
   ```

2. **Check if Ubuntu ISO is downloaded:**
   ```bash
   ls -lh ~/Downloads/ubuntu-22.04.5-live-server-arm64.iso
   ```
   
   If not, download it:
   ```bash
   cd ~/Downloads
   wget https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.5-live-server-arm64.iso
   ```

3. **Create VM in UTM:**
   - Open UTM
   - Create New Virtual Machine
   - Select "Virtualize" (NOT Emulate!)
   - Choose Linux
   - Select the Ubuntu ISO
   - Configure: 8GB RAM, 6 CPU cores, 100GB disk
   - Install Ubuntu Server

4. **After Ubuntu installation, run setup script:**
   
   First, copy the updated script to your VM. From macOS:
   ```bash
   # Get VM IP (shown in UTM or run 'ip addr' in VM)
   scp utm-setup-script.sh builder@<VM_IP>:~/
   ```
   
   Then in the Ubuntu VM:
   ```bash
   chmod +x utm-setup-script.sh
   ./utm-setup-script.sh
   ```

5. **Watch for:**
   ```
   Using Tizen Studio 6.1
   ✓ Tizen SDK installed successfully
   ✓ Toolchain packages installed
   ```

## What Success Looks Like

### GitHub Actions Success:
```
✓ Tizen SDK 6.1 downloaded and installed
✓ NativeToolchain-Gcc-9.2 installed
✓ Dependencies built successfully
✓ Kodi compiled successfully
✓ TPK package created
✓ Artifact uploaded
```

### UTM VM Success:
```bash
# Check Tizen SDK version
cat ~/tizen-studio/sdk.info

# Verify toolchain exists
ls ~/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2/bin/

# Should see:
arm-linux-gnueabi-gcc
arm-linux-gnueabi-g++
arm-linux-gnueabi-ar
arm-linux-gnueabi-ranlib
# ... and more
```

## What Failure Looks Like

### If 6.1 URL doesn't exist:
```
Downloading Tizen Studio 6.1...
HTTP request sent, awaiting response... 404 Not Found
Falling back to Tizen Studio 5.0...
```
→ This is OK! Fallback will work.

### If toolchain still fails:
```
✗ Tizen SDK installation failed - toolchain not found
```
→ Need alternative approach (see below)

## If It Still Fails

### Immediate Actions:

1. **Check if 6.1 URL exists:**
   ```bash
   wget --spider http://download.tizen.org/sdk/Installer/tizen-studio_6.1/web-cli_Tizen_Studio_6.1_ubuntu-64.bin
   ```

2. **Try manual toolchain installation:**
   ```bash
   # In VM or GitHub Actions
   $HOME/tizen-studio/package-manager/package-manager-cli.bin update
   $HOME/tizen-studio/package-manager/package-manager-cli.bin install NativeToolchain-Gcc-9.2 --accept-license
   ```

3. **Check available packages:**
   ```bash
   $HOME/tizen-studio/package-manager/package-manager-cli.bin show-pkgs
   ```

### Alternative Approaches:

**Option A: Use Native ARM GCC**
- Modify build to use Ubuntu's native ARM GCC
- May work but not officially supported

**Option B: Build GCC from Source**
- Compile GCC 9.2 manually
- Time-consuming but guaranteed to work

**Option C: Contact Tizen Support**
- Report toolchain installation issues
- Forum: https://developer.tizen.org/forums

## Recommended Approach

### For You (M4 Mac User):

1. **Start with GitHub Actions** (easiest)
   - Commit and push changes
   - Let it run automatically
   - Check results in ~90 minutes

2. **While waiting, set up UTM VM** (for future local builds)
   - Follow `UTM_STEP_BY_STEP.md`
   - Test the updated script
   - Have local environment ready

3. **If both succeed:**
   - You have working build pipeline!
   - Can build TPK locally or via GitHub
   - Install on Samsung TV

4. **If both fail:**
   - We investigate alternative toolchain sources
   - Consider manual GCC compilation
   - Explore native ARM GCC approach

## Quick Commands Reference

### Commit and Push Changes:
```bash
git add .
git commit -m "Update to Tizen Studio 6.1 with fallback"
git push origin main
```

### Check GitHub Actions:
```bash
# Open in browser
open https://github.com/creolben/kodi-tizen/actions
```

### Test URL Manually:
```bash
wget --spider http://download.tizen.org/sdk/Installer/tizen-studio_6.1/web-cli_Tizen_Studio_6.1_ubuntu-64.bin
```

### Check VM Setup:
```bash
# From macOS, SSH into VM
ssh builder@<VM_IP>

# In VM, check Tizen SDK
ls ~/tizen-studio/tools/
```

## Timeline

| Action | Time | When |
|--------|------|------|
| Commit & push | 1 min | Now |
| GitHub Actions start | 1 min | Immediately |
| GitHub Actions complete | 60-90 min | Automatic |
| UTM VM setup | 30-60 min | Parallel |
| UTM build | 60-90 min | After setup |
| **Total (parallel)** | **~2 hours** | **Today** |

## Success Criteria

✅ Tizen Studio 6.1 downloads successfully
✅ Toolchain packages install without errors
✅ Dependencies compile successfully
✅ Kodi builds without errors
✅ TPK file is created
✅ TPK installs on Samsung TV
✅ Kodi launches and runs

## What to Do Right Now

### Option 1: Quick Test (GitHub Actions)
```bash
git add .
git commit -m "Update to Tizen Studio 6.1"
git push origin main
# Then watch: https://github.com/creolben/kodi-tizen/actions
```

### Option 2: Local Test (UTM)
```bash
# 1. Ensure UTM is installed
brew install --cask utm

# 2. Open UTM and create VM
open -a UTM

# 3. Follow UTM_STEP_BY_STEP.md
```

### Option 3: Both (Recommended!)
Do both in parallel - GitHub Actions runs while you set up UTM.

## Questions?

- **"Will this definitely work?"** - Unknown, but it's our best shot. The fallback ensures nothing breaks.
- **"How long will it take?"** - 60-90 minutes for GitHub Actions, 2-3 hours for UTM first time.
- **"What if it fails?"** - We have alternative approaches ready (see above).
- **"Should I use GitHub Actions or UTM?"** - Both! GitHub for automated builds, UTM for local development.

## Ready to Go! 🚀

The changes are ready. Choose your testing approach and let's see if Tizen Studio 6.1 solves the toolchain issues!

---

**Status:** Ready to test
**Next Action:** Commit and push, or set up UTM VM
**Expected Result:** Working TPK build within 2-3 hours
