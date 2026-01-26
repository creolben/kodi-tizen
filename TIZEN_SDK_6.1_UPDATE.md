# Tizen Studio 6.1 Update

## Summary

Updated all build scripts and workflows to use **Tizen Studio 6.1** instead of 5.0, with automatic fallback to 5.0 if 6.1 is not available.

## Why This Update?

### The Problem
Tizen Studio 5.0 has persistent toolchain installation issues:
- ❌ `NativeToolchain-Gcc-9.2` packages fail to install
- ❌ Affects GitHub Actions, Podman containers, and UTM VMs
- ❌ Results in "C compiler cannot create executables" errors
- ❌ Blocks all build attempts across all platforms

### The Solution
Tizen Studio 6.1 is now available and may have:
- ✅ Updated/fixed toolchain packages
- ✅ Better compatibility with Ubuntu 22.04
- ✅ Resolved package manager issues
- ✅ Updated GCC toolchain (potentially newer than 9.2)

## What Changed

### 1. GitHub Actions Workflow (`.github/workflows/build-tizen.yml`)

**Before:**
```yaml
- name: Cache Tizen SDK
  uses: actions/cache@v4
  with:
    path: ~/tizen-studio
    key: tizen-sdk-5.0-${{ runner.os }}

- name: Download and install Tizen SDK
  run: |
    wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    ./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license $HOME/tizen-studio
```

**After:**
```yaml
- name: Cache Tizen SDK
  uses: actions/cache@v4
  with:
    path: ~/tizen-studio
    key: tizen-sdk-6.1-${{ runner.os }}

- name: Download and install Tizen SDK
  run: |
    # Try Tizen Studio 6.1 first, fallback to 5.0 if not available
    wget http://download.tizen.org/sdk/Installer/tizen-studio_6.1/web-cli_Tizen_Studio_6.1_ubuntu-64.bin || \
    wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    
    chmod +x web-cli_Tizen_Studio_*.bin
    ./web-cli_Tizen_Studio_*.bin --accept-license $HOME/tizen-studio
```

### 2. UTM Setup Script (`utm-setup-script.sh`)

**Before:**
```bash
wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
chmod +x web-cli_Tizen_Studio_5.0_ubuntu-64.bin
./web-cli_Tizen_Studio_5.0_ubuntu-64.bin --accept-license "$TIZEN_SDK_DIR"
```

**After:**
```bash
# Try Tizen Studio 6.1 first, fallback to 5.0 if not available
if wget http://download.tizen.org/sdk/Installer/tizen-studio_6.1/web-cli_Tizen_Studio_6.1_ubuntu-64.bin 2>/dev/null; then
    INSTALLER="web-cli_Tizen_Studio_6.1_ubuntu-64.bin"
else
    wget http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
    INSTALLER="web-cli_Tizen_Studio_5.0_ubuntu-64.bin"
fi

chmod +x "$INSTALLER"
./"$INSTALLER" --accept-license "$TIZEN_SDK_DIR"
```

### 3. Documentation Updates

Updated the following files:
- ✅ `M4_LOCAL_BUILD_GUIDE.md` - Updated SDK installation instructions
- ✅ `UTM_STEP_BY_STEP.md` - Updated step-by-step guide
- ✅ `.github/workflows/build-tizen.yml` - Updated workflow

## How It Works

### Fallback Strategy

All scripts now use a **try-first-fallback** approach:

1. **Try Tizen Studio 6.1** first
   - If download succeeds → use 6.1
   - If download fails → fallback to 5.0

2. **Automatic detection**
   - Scripts detect which version was downloaded
   - Use wildcard patterns to run the correct installer

3. **No manual intervention needed**
   - Works automatically in all environments
   - Graceful degradation if 6.1 not available

### URL Pattern

Based on Tizen Studio 5.0 URL pattern:
```
http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
```

Predicted Tizen Studio 6.1 URL:
```
http://download.tizen.org/sdk/Installer/tizen-studio_6.1/web-cli_Tizen_Studio_6.1_ubuntu-64.bin
```

**Note:** If the URL pattern is different, the fallback to 5.0 ensures builds don't break.

## Testing the Update

### Test 1: GitHub Actions

1. Push changes to trigger workflow
2. Monitor "Download and install Tizen SDK" step
3. Check which version is downloaded
4. Verify toolchain installation succeeds

**Expected output:**
```
Downloading Tizen Studio 6.1...
Installing Tizen SDK...
✓ Tizen SDK installed successfully
```

### Test 2: UTM VM

1. Create new Ubuntu VM
2. Run `utm-setup-script.sh`
3. Check which version is installed
4. Verify toolchain packages install

**Check version:**
```bash
ls ~/tizen-studio/
cat ~/tizen-studio/sdk.info
```

### Test 3: Manual Verification

Test if 6.1 URL exists:
```bash
wget --spider http://download.tizen.org/sdk/Installer/tizen-studio_6.1/web-cli_Tizen_Studio_6.1_ubuntu-64.bin
echo $?  # 0 = exists, non-zero = doesn't exist
```

## Expected Outcomes

### If Tizen Studio 6.1 Exists and Works:
✅ Toolchain packages install successfully
✅ GCC compiler works correctly
✅ Builds complete without errors
✅ TPK files are generated

### If Tizen Studio 6.1 Doesn't Exist:
⚠️ Falls back to 5.0 automatically
⚠️ Same toolchain issues may persist
⚠️ Need alternative solutions (see below)

### If Tizen Studio 6.1 Exists but Has Same Issues:
⚠️ Need to investigate alternative approaches
⚠️ May need to use different toolchain
⚠️ May need to build GCC from source

## Alternative Solutions (If 6.1 Doesn't Help)

### Option 1: Use Native ARM GCC
Build with Ubuntu's native ARM GCC instead of Tizen's:
- Pros: Readily available, well-tested
- Cons: May not be fully compatible with Tizen platform

### Option 2: Build GCC 9.2 from Source
Compile GCC 9.2 manually in the build environment:
- Pros: Full control over toolchain
- Cons: Very time-consuming (2-3 hours)

### Option 3: Use Docker with Pre-built Toolchain
Create custom Docker image with working toolchain:
- Pros: Reproducible, shareable
- Cons: Complex setup, large image size

### Option 4: Contact Samsung/Tizen Support
Report toolchain installation issues:
- Tizen Developer Forum: https://developer.tizen.org/forums
- GitHub Issues: https://github.com/Samsung/tizen-studio-issues

## Rollback Plan

If 6.1 causes new issues, revert changes:

```bash
# Revert GitHub Actions workflow
git checkout HEAD~1 .github/workflows/build-tizen.yml

# Revert UTM setup script
git checkout HEAD~1 utm-setup-script.sh

# Revert documentation
git checkout HEAD~1 M4_LOCAL_BUILD_GUIDE.md UTM_STEP_BY_STEP.md
```

Or manually change URLs back to:
```
http://download.tizen.org/sdk/Installer/tizen-studio_5.0/web-cli_Tizen_Studio_5.0_ubuntu-64.bin
```

## Next Steps

1. **Test GitHub Actions workflow**
   - Push changes to trigger build
   - Monitor for successful toolchain installation
   - Check build logs for version info

2. **Test UTM VM setup**
   - Create fresh Ubuntu VM
   - Run updated setup script
   - Verify toolchain installation

3. **Document results**
   - Record which version was used
   - Note any new errors or issues
   - Update documentation accordingly

4. **If successful:**
   - Update all documentation to reflect 6.1 as primary
   - Remove fallback to 5.0 after confirmation
   - Share success with community

5. **If unsuccessful:**
   - Investigate alternative toolchain sources
   - Consider manual GCC compilation
   - Explore native ARM GCC approach

## Resources

- **Tizen Studio Download**: https://developer.tizen.org/development/tizen-studio/download
- **Tizen Studio Release Notes**: https://developer.tizen.org/development/tizen-studio/download/release-notes
- **Tizen Developer Forum**: https://developer.tizen.org/forums
- **GitHub Issues**: https://github.com/Samsung/tizen-studio-issues

## Conclusion

This update attempts to resolve the persistent toolchain installation issues by using the newer Tizen Studio 6.1. The fallback mechanism ensures builds don't break if 6.1 is unavailable. This is a **low-risk, high-reward** change that could potentially solve the fundamental blocker preventing TPK builds.

**Status:** Ready to test
**Risk Level:** Low (automatic fallback)
**Expected Impact:** High (may resolve toolchain issues)

---

**Last Updated:** January 26, 2026
**Author:** Kiro AI Assistant
**Related Issues:** Toolchain installation failures across all platforms
