# Quick Start: Building Kodi TPK on Apple Silicon M4

## TL;DR

**Best Option**: Use GitHub Actions (5 minutes setup, 90 minutes automated build)

**Local Option**: Use UTM VM with Ubuntu ARM64 (30 minutes setup, 90 minutes build)

**Don't Use**: Docker/Podman (too slow), Native macOS (doesn't work)

---

## Option 1: GitHub Actions (Recommended) ⭐

### Why?
- ✅ Easiest and most reliable
- ✅ No local resources needed
- ✅ Free for public repos
- ✅ Already configured

### Steps:
1. Go to https://github.com/creolben/kodi-tizen/settings/actions
2. Enable "Allow all actions"
3. Go to https://github.com/creolben/kodi-tizen/actions
4. Cancel any stuck workflows
5. Click "Build Kodi for Tizen" → "Run workflow"
6. Wait 60-90 minutes
7. Download TPK from Artifacts

**Full guide**: `ACTION_PLAN_NOW.md`

---

## Option 2: UTM VM (Best Local Option) ⭐

### Why?
- ✅ Near-native ARM64 performance
- ✅ Full Linux environment
- ✅ Free and open-source
- ✅ Works great on M4

### Quick Setup:

```bash
# 1. Install UTM
brew install --cask utm

# 2. Download Ubuntu ARM64
# https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.5-live-server-arm64.iso

# 3. Create VM in UTM:
# - Click "Create a New Virtual Machine"
# - Select "Virtualize" (NOT Emulate!)
# - Choose Linux
# - Boot ISO: Ubuntu ARM64 ISO
# - Memory: 8 GB
# - CPU: 4-6 cores
# - Storage: 100 GB
# - Install Ubuntu Server

# 4. In Ubuntu VM, run setup script:
wget https://raw.githubusercontent.com/creolben/kodi-tizen/main/utm-setup-script.sh
bash utm-setup-script.sh

# 5. Build Kodi:
bash ~/build-kodi.sh

# 6. Transfer TPK to macOS:
# Use shared folder or SCP
```

**Full guide**: `M4_LOCAL_BUILD_GUIDE.md`

**Time**: 30 min setup + 90 min build

---

## Comparison

| Method | Setup | Build | Complexity | Speed |
|--------|-------|-------|------------|-------|
| **GitHub Actions** | 5 min | 90 min | ⭐ Easy | ⭐⭐⭐⭐⭐ Fast |
| **UTM VM** | 30 min | 90 min | ⭐⭐ Medium | ⭐⭐⭐⭐ Fast |
| **Docker/Podman** | 2 hours | 6 hours | ⭐⭐⭐⭐ Hard | ⭐ Very Slow |
| **Native macOS** | N/A | N/A | ❌ Impossible | ❌ N/A |

---

## What About Docker/Podman?

**Don't use it on M4.** Here's why:

❌ **Very slow** (x86 emulation on ARM = 5-10x slower)
❌ **Unstable** (zombie processes, QEMU issues)
❌ **Complex** (multiple layers of abstraction)
❌ **Not worth it** (UTM is faster and easier)

Your previous container build attempts failed because:
1. Cross-architecture emulation is slow
2. QEMU has stability issues
3. Zombie processes from failed builds

**Solution**: Use UTM instead (native ARM64 virtualization)

---

## Why Can't I Build Natively on macOS?

The macOS Tizen SDK is **packaging-only**:

✅ Can package pre-built binaries into TPK
✅ Can deploy TPK to devices
✅ Can debug applications
❌ **Cannot build from source** (missing ARM sysroot)

To build from source, you need:
- Linux environment
- Tizen SDK with full toolchain
- ARM cross-compilation tools

This is why we use:
- **GitHub Actions**: Native Linux runners
- **UTM VM**: Linux on your Mac

---

## Recommended Workflow

### For Development:

1. **Edit code** on macOS (your favorite editor)
2. **Build** using GitHub Actions or UTM VM
3. **Test** TPK on Samsung TV using macOS SDB tools

### For CI/CD:

1. **Push code** to GitHub
2. **Automatic build** via GitHub Actions
3. **Download TPK** from Artifacts
4. **Deploy** to TV for testing

---

## Files Created for You

1. **`M4_LOCAL_BUILD_GUIDE.md`** - Complete guide for all options
2. **`M4_QUICK_START.md`** - This file (quick reference)
3. **`utm-setup-script.sh`** - Automated UTM VM setup
4. **`ACTION_PLAN_NOW.md`** - GitHub Actions guide
5. **`GBS_VS_STANDARD_BUILD.md`** - Build system explanation

---

## Next Steps

### Immediate (Choose One):

**Option A: GitHub Actions** (Recommended)
1. Read `ACTION_PLAN_NOW.md`
2. Enable Actions on GitHub
3. Trigger workflow
4. Wait for TPK

**Option B: UTM VM** (Local Development)
1. Read `M4_LOCAL_BUILD_GUIDE.md`
2. Install UTM
3. Create Ubuntu VM
4. Run setup script
5. Build Kodi

### After You Have TPK:

1. **Install on TV**:
   ```bash
   sdb connect <TV_IP>:26101
   sdb install kodi-tizen-*.tpk
   sdb shell app_launcher -s org.xbmc.kodi
   ```

2. **Test and iterate**

---

## Troubleshooting

### GitHub Actions stuck?
→ See `GITHUB_ACTIONS_FIX.md`

### UTM VM slow?
→ Ensure "Virtualize" is selected (not "Emulate")
→ Allocate more CPU cores and RAM

### Container build failing?
→ Don't use containers on M4
→ Use UTM VM instead

### Need help?
→ All guides are in your repository
→ Check `M4_LOCAL_BUILD_GUIDE.md` for detailed troubleshooting

---

## Summary

**Can you build locally on M4?** Yes, using UTM VM.

**Should you?** Only if you need local development.

**Best approach?** GitHub Actions for builds, macOS for development.

**Time to first TPK:**
- GitHub Actions: ~95 minutes (5 min setup + 90 min build)
- UTM VM: ~120 minutes (30 min setup + 90 min build)

**Recommendation**: Start with GitHub Actions. Set up UTM VM later if needed.

---

## Resources

- **UTM**: https://mac.getutm.app/
- **Ubuntu ARM64**: https://cdimage.ubuntu.com/releases/22.04/release/
- **GitHub Actions**: https://github.com/features/actions
- **Your Workflow**: https://github.com/creolben/kodi-tizen/actions

---

## Quick Commands

### GitHub Actions:
```bash
# 1. Enable Actions (in browser)
# 2. Trigger workflow (in browser)
# 3. Download TPK (in browser)
```

### UTM VM:
```bash
# Install UTM
brew install --cask utm

# After VM setup:
wget https://raw.githubusercontent.com/creolben/kodi-tizen/main/utm-setup-script.sh
bash utm-setup-script.sh
bash ~/build-kodi.sh
```

### Install TPK:
```bash
sdb connect <TV_IP>:26101
sdb install kodi-tizen-*.tpk
sdb shell app_launcher -s org.xbmc.kodi
```

---

**Ready to build?** Choose your method and follow the guide! 🚀
