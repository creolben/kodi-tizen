# GBS vs Standard Build System for Kodi Tizen

## Current Approach: Kodi Standard Build System ✓

We're currently using **Kodi's unified depends build system** (autotools + CMake), not Tizen's GBS (Git Build System).

### What We're Using:
- **Build System**: Kodi's autotools/CMake
- **Toolchain**: Tizen SDK GCC 9.2 cross-compiler
- **Configuration**: `tools/depends/configure.ac`
- **Target**: `arm-tizen-linux-gnueabi`

### Why This Approach:
1. ✅ **Consistent with other Kodi platforms** (webOS, Android, iOS)
2. ✅ **Well-documented** in Kodi's build system
3. ✅ **Already implemented** (tasks 1-14 complete)
4. ✅ **Works with GitHub Actions**
5. ✅ **No GBS dependencies needed**

## Alternative: Tizen GBS Build System

GBS (Git Build System) is Tizen's native build system used for official Tizen packages.

### What is GBS?

GBS is a command-line tool that:
- Builds RPM packages for Tizen
- Uses OBS (Open Build Service) infrastructure
- Requires `.gbs.conf` configuration
- Integrates with Tizen's package management

### When to Use GBS:

1. **Building official Tizen platform packages**
2. **Contributing to Tizen OS itself**
3. **Using Tizen's build infrastructure**
4. **Need RPM packages (not TPK)**

### When NOT to Use GBS:

1. ✅ **Building applications** (like Kodi) - Use Tizen SDK
2. ✅ **Creating TPK packages** - Use tizen-studio tools
3. ✅ **Cross-platform projects** - Use project's native build system
4. ✅ **GitHub Actions CI/CD** - Use standard toolchains

## Do We Need .gbs.conf?

**Short Answer: No**

We're building Kodi as a **Tizen application** (TPK), not a Tizen platform package (RPM).

### Our Build Flow:
```
Source Code
    ↓
Kodi Build System (autotools/CMake)
    ↓
Tizen SDK Toolchain (GCC 9.2)
    ↓
Kodi Binary + Libraries
    ↓
TPK Packaging (tizen-studio tools)
    ↓
TPK File (installable on Samsung TV)
```

### GBS Build Flow (Not Used):
```
Source Code
    ↓
GBS Configuration (.gbs.conf)
    ↓
GBS Build (creates build-root)
    ↓
RPM Package
    ↓
Tizen Platform Integration
```

## If You Want to Use GBS (Advanced)

If you specifically want to use GBS for some reason, here's what you'd need:

### 1. Create .gbs.conf

```ini
[general]
profile = profile.tizen
work_dir = ~/GBS-ROOT

[profile.tizen]
repos = repo.tizen_base, repo.tizen_mobile
buildroot = ~/GBS-ROOT/local/BUILD-ROOTS/scratch.armv7l.0

[repo.tizen_base]
url = http://download.tizen.org/releases/milestone/tizen/unified/latest/repos/standard/packages/

[repo.tizen_mobile]
url = http://download.tizen.org/releases/milestone/tizen/mobile/latest/repos/target-TM1/packages/
```

### 2. Create RPM spec file

You'd need to create a `kodi.spec` file for RPM packaging.

### 3. Use GBS commands

```bash
# Build with GBS
gbs build -A armv7l

# Create source RPM
gbs export

# Build in chroot
gbs chroot
```

### 4. Issues with GBS Approach:

- ❌ **More complex** than standard build
- ❌ **Requires GBS installation** (not in Tizen Studio)
- ❌ **Creates RPM, not TPK** (need conversion)
- ❌ **Tizen platform dependencies** (not app dependencies)
- ❌ **Not compatible with GitHub Actions** (easily)
- ❌ **Overkill for application development**

## Recommendation: Stick with Current Approach

### Why Current Approach is Better:

1. ✅ **Simpler** - Uses Kodi's standard build system
2. ✅ **Proven** - Works for webOS, Android, iOS
3. ✅ **GitHub Actions compatible** - Native Linux build
4. ✅ **TPK output** - Directly installable on TV
5. ✅ **No GBS dependencies** - Just Tizen SDK
6. ✅ **Already implemented** - All code is done

### Current Build Issues:

The build issues you're experiencing are **NOT** related to missing GBS configuration:

1. **C++20 vs C++17** - Compiler version issue (already patched)
2. **Zombie processes** - Container/cross-compilation issue
3. **GitHub Actions queue** - Repository settings issue

None of these would be solved by using GBS.

## What About Build-Root Issues?

If you're seeing "build-root" errors, they're likely from:

1. **Kodi's depends system** - Uses its own build-root
2. **Cross-compilation paths** - Toolchain sysroot issues
3. **Container permissions** - File access issues

These are handled by:
- Kodi's `configure.ac` (already configured for Tizen)
- Proper toolchain paths (already set)
- Container setup (already done)

## Summary

### Current Status:
- ✅ Using Kodi's standard build system
- ✅ Configured for Tizen target
- ✅ No GBS needed
- ✅ Ready to build with GitHub Actions

### If You See Build-Root Errors:

**Check these instead of GBS:**

1. **Toolchain path**:
   ```bash
   --with-toolchain=$HOME/tizen-studio/tools/arm-linux-gnueabi-gcc-9.2
   ```

2. **Prefix path**:
   ```bash
   --prefix=$HOME/kodi-tizen-deps
   ```

3. **Host triplet**:
   ```bash
   --host=arm-tizen-linux-gnueabi
   ```

4. **Platform**:
   ```bash
   --with-platform=tizen
   ```

All of these are already correctly configured in:
- `.github/workflows/build-tizen.yml`
- `fix-and-build-tizen.sh`
- `container-build.sh`

## Conclusion

**You don't need .gbs.conf** for building Kodi for Tizen.

GBS is for Tizen platform development, not application development.

Your current approach is correct. The build issues are unrelated to GBS.

**Proceed with GitHub Actions as recommended** - it will work without any GBS configuration.

## References

- **Kodi Build System**: `docs/README.Tizen.md`
- **Tizen SDK**: https://developer.tizen.org/
- **GBS Documentation**: https://source.tizen.org/documentation/reference/git-build-system
- **When to use GBS**: Platform packages, not applications

## Quick Answer

**Q: Do I need .gbs.conf?**
**A: No. You're building an application (TPK), not a platform package (RPM).**

**Q: Will GBS solve my build issues?**
**A: No. Your issues are C++ version and cross-compilation related.**

**Q: Should I use GBS?**
**A: No. Stick with Kodi's standard build system.**

**Q: What should I do instead?**
**A: Follow the GitHub Actions approach in ACTION_PLAN_NOW.md**
