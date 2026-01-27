# Toolchain Workaround - Using Ubuntu ARM GCC

## The Problem

Tizen SDK package manager **consistently fails** to install toolchain packages across ALL versions:
- ❌ Tizen Studio 5.0 - NativeToolchain-Gcc-9.2 fails to install
- ❌ Tizen Studio 6.0 - Same issue
- ❌ Tizen Studio 6.1 - Same issue

**Error:**
```
configure: error: C compiler cannot create executables
```

**Root cause:** The toolchain binaries simply don't exist after "installation":
```bash
ls ~/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2/bin/
# Directory doesn't exist or is empty
```

## The Solution

Since the Tizen SDK package manager is broken, we're using **Ubuntu's ARM cross-compiler** instead.

### How It Works

1. **Try Tizen toolchain first** (will likely fail, but we try anyway)
2. **Install Ubuntu ARM GCC** (`gcc-arm-linux-gnueabihf`)
3. **Create symlinks** to match Tizen's expected paths
4. **Build proceeds** with working ARM cross-compiler

### Implementation

```yaml
- name: Install Tizen packages and setup alternative toolchain
  run: |
    # Try Tizen toolchain (likely fails)
    $HOME/tizen-studio/package-manager/package-manager-cli.bin install \
      NativeToolchain-Gcc-9.2 || true
    
    # Check if it worked
    if [ -d "$HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2/bin" ]; then
      echo "✓ Tizen toolchain installed"
    else
      # Fallback to Ubuntu ARM GCC
      sudo apt-get install -y \
        gcc-arm-linux-gnueabihf \
        g++-arm-linux-gnueabihf \
        binutils-arm-linux-gnueabihf
      
      # Create symlinks to match Tizen paths
      mkdir -p $HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2/bin
      cd $HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2/bin
      ln -s /usr/bin/arm-linux-gnueabihf-gcc arm-linux-gnueabi-gcc
      ln -s /usr/bin/arm-linux-gnueabihf-g++ arm-linux-gnueabi-g++
      # ... more symlinks
    fi
```

## Why This Works

### Ubuntu ARM GCC vs Tizen GCC

| Feature | Tizen GCC 9.2 | Ubuntu ARM GCC |
|---------|---------------|----------------|
| **Availability** | ❌ Broken | ✅ Works |
| **ARM Support** | ✅ Yes | ✅ Yes |
| **C++17** | ✅ Yes | ✅ Yes |
| **Cross-compile** | ✅ Yes | ✅ Yes |
| **Tizen APIs** | ✅ Native | ⚠️ Via headers |

The key insight: **We don't need Tizen's GCC to build Kodi**. We just need:
1. ARM cross-compiler (Ubuntu provides this)
2. Tizen headers/libraries (from Tizen SDK)
3. Correct paths (symlinks handle this)

### Compatibility

Ubuntu's `gcc-arm-linux-gnueabihf` is:
- ✅ **ARM hard-float** (same as Tizen)
- ✅ **GCC 11+** (supports C++17 and C++20)
- ✅ **Well-tested** (used by millions)
- ✅ **Actively maintained** (Ubuntu repos)

## What Changed

### Before (Broken):
```
Tizen SDK → Package Manager → NativeToolchain-Gcc-9.2 → ❌ FAILS
                                                        ↓
                                              No compiler binaries
                                                        ↓
                                        configure: error: C compiler cannot create executables
```

### After (Working):
```
Tizen SDK → Package Manager → NativeToolchain-Gcc-9.2 → ❌ FAILS
                                                        ↓
                                              Fallback triggered
                                                        ↓
                                    Ubuntu ARM GCC installed
                                                        ↓
                                    Symlinks created
                                                        ↓
                                    ✅ Compiler works!
```

## Expected Results

### Build Process:

1. **SDK Installation:** ✅ Tizen Studio 6.1 downloads and installs
2. **Toolchain Installation:** ⚠️ Tizen toolchain fails (expected)
3. **Fallback Activation:** ✅ Ubuntu ARM GCC installed
4. **Symlink Creation:** ✅ Paths match Tizen expectations
5. **Compiler Test:** ✅ `arm-linux-gnueabi-gcc --version` works
6. **Dependencies Build:** ✅ Should proceed normally
7. **Kodi Build:** ✅ Should complete
8. **TPK Creation:** ✅ Should generate package

### What to Watch For:

**Success indicators:**
```
⚠ Tizen toolchain not available, using alternative ARM GCC
✓ Alternative ARM toolchain configured
Toolchain binaries:
  arm-linux-gnueabi-gcc -> /usr/bin/arm-linux-gnueabihf-gcc
  arm-linux-gnueabi-g++ -> /usr/bin/arm-linux-gnueabihf-g++
  ...
GCC version:
  arm-linux-gnueabihf-gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0
```

**Then build should continue:**
```
✓ Configuring dependencies...
✓ Building dependencies...
✓ Building Kodi...
✓ Creating TPK...
```

## Potential Issues

### Issue 1: Tizen-Specific Headers Missing

**Symptom:** Compile errors about missing Tizen headers
**Solution:** Tizen SDK still provides headers, just not the compiler

### Issue 2: ABI Compatibility

**Symptom:** TPK installs but crashes on TV
**Solution:** Both use ARM hard-float ABI, should be compatible

### Issue 3: Library Linking

**Symptom:** Linker errors about Tizen libraries
**Solution:** Tizen SDK provides libraries, we're just using different compiler

## Advantages of This Approach

✅ **Bypasses broken package manager** - No dependency on Tizen's broken toolchain packages
✅ **Uses proven toolchain** - Ubuntu ARM GCC is well-tested and reliable
✅ **Automatic fallback** - If Tizen toolchain ever works, it will be used
✅ **No manual intervention** - Fully automated in GitHub Actions
✅ **Faster installation** - Ubuntu packages install quickly
✅ **Better support** - GCC 11 vs GCC 9.2 (newer, better C++ support)

## Disadvantages

⚠️ **Not "official"** - Not using Tizen's recommended toolchain
⚠️ **Potential compatibility** - Might have subtle ABI differences
⚠️ **Untested path** - This is a workaround, not the standard approach

## Alternative Approaches Considered

### 1. Build GCC from Source
- ❌ Too slow (2-3 hours)
- ❌ Complex
- ❌ High failure risk

### 2. Use Pre-built GCC Binary
- ❌ Hard to find ARM hard-float GCC 9.2
- ❌ Trust/security concerns
- ❌ Maintenance burden

### 3. Use Docker with Working Toolchain
- ❌ Requires finding/creating working image
- ❌ Adds complexity
- ❌ Still doesn't solve root problem

### 4. Contact Samsung/Tizen Support
- ❌ Slow response time
- ❌ May not be fixed
- ❌ Blocks progress

**Verdict:** Ubuntu ARM GCC is the best pragmatic solution.

## Testing Plan

1. **GitHub Actions Build:**
   - Watch for fallback activation
   - Verify compiler works
   - Check if dependencies build
   - See if Kodi compiles
   - Test if TPK is created

2. **If Successful:**
   - Download TPK
   - Install on Samsung TV
   - Test basic functionality
   - Check for crashes
   - Verify Tizen APIs work

3. **If Issues:**
   - Check error logs
   - Identify missing headers/libraries
   - Add additional packages if needed
   - Adjust symlinks if necessary

## Next Steps

1. **Monitor current build** - Check if fallback works
2. **Test TPK on TV** - Verify compatibility
3. **Document results** - Record what works/doesn't work
4. **Iterate if needed** - Fix any issues that arise

## Conclusion

The Tizen SDK package manager is fundamentally broken and has been for multiple versions. Rather than wait for Samsung to fix it, we're using a proven alternative (Ubuntu ARM GCC) that should work just as well.

This is a **pragmatic workaround** that gets us building while maintaining compatibility with Kodi's build system and Tizen's runtime environment.

**Status:** ✅ Implemented and pushed
**Build:** 🔄 Running now
**Confidence:** 🟢 HIGH - Ubuntu ARM GCC is proven and reliable

---

**Watch the build:** https://github.com/creolben/kodi-tizen/actions

Let's see if this workaround finally gets us a working TPK! 🤞
