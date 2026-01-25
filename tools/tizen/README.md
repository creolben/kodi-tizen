# Kodi for Tizen - Build Configuration

This directory contains Tizen-specific build configuration and packaging files for Kodi.

## Prerequisites

Before building Kodi for Tizen, you need:

1. **Tizen Studio** - Download and install from https://developer.tizen.org/development/tizen-studio
2. **Tizen SDK** - Install the required SDK version (6.0 or later recommended)
3. **Tizen Certificate** - Create a certificate for signing TPK packages
4. **Build Tools** - Standard build tools (gcc, make, cmake, autotools, etc.)

## Environment Setup

Set the following environment variables:

```bash
# Path to Tizen Studio installation
export TIZEN_SDK=/path/to/tizen-studio

# Tizen SDK version (e.g., 6.0, 6.5, 7.0)
export TIZEN_VERSION=6.0

# Tizen rootstrap name (e.g., mobile-6.0-device.core, tv-samsung-6.0-device.core)
export TIZEN_ROOTSTRAP=tv-samsung-6.0-device.core
```

## Configuring Dependencies for Tizen

Kodi uses a unified depends system to build all required dependencies. To configure for Tizen:

### ARM (Most Samsung TVs)

```bash
cd tools/depends
./bootstrap
./configure \
  --prefix=$HOME/kodi-tizen-deps \
  --host=arm-tizen-linux-gnueabi \
  --with-toolchain=$TIZEN_SDK/tools/arm-linux-gnueabi-gcc-9.2 \
  --with-platform=tizen \
  --with-rendersystem=gles \
  --enable-debug=no
```

### x86 (Tizen Emulator)

```bash
cd tools/depends
./bootstrap
./configure \
  --prefix=$HOME/kodi-tizen-deps \
  --host=i686-tizen-linux-gnu \
  --with-toolchain=$TIZEN_SDK/tools/i686-linux-gnueabi-gcc-9.2 \
  --with-platform=tizen \
  --with-rendersystem=gles \
  --enable-debug=no
```

### x86_64 (Tizen Emulator)

```bash
cd tools/depends
./bootstrap
./configure \
  --prefix=$HOME/kodi-tizen-deps \
  --host=x86_64-tizen-linux-gnu \
  --with-toolchain=$TIZEN_SDK/tools/x86_64-linux-gnueabi-gcc-9.2 \
  --with-platform=tizen \
  --with-rendersystem=gles \
  --enable-debug=no
```

## Configuration Options

### Required Options

- `--prefix`: Installation directory for built dependencies
- `--host`: Target host triplet (see above for options)
- `--with-toolchain`: Path to Tizen toolchain
- `--with-platform=tizen`: Specifies Tizen as the target platform
- `--with-rendersystem=gles`: Use OpenGL ES for rendering (required for Tizen)

### Optional Options

- `--enable-debug=yes`: Build with debug symbols (default: yes)
- `--with-tarballs=/path/to/tarballs`: Directory to store downloaded source tarballs
- `--with-cpu=<cpu>`: Specify target CPU (auto-detected if not specified)
- `--enable-ccache`: Enable ccache for faster rebuilds (default: yes)

## Building Dependencies

After configuration, build all dependencies:

```bash
make -j$(nproc)
```

This will download, configure, and build all required dependencies for Kodi on Tizen.

## Host Triplets

Kodi's depends system uses standard GNU host triplets to identify the target platform:

- **arm-tizen-linux-gnueabi**: ARM architecture with soft-float ABI (most Samsung TVs)
- **i686-tizen-linux-gnu**: 32-bit x86 (Tizen emulator)
- **x86_64-tizen-linux-gnu**: 64-bit x86 (Tizen emulator)

## Toolchain Paths

The toolchain path should point to the Tizen Studio toolchain directory. Common locations:

- **Linux**: `$TIZEN_SDK/tools/arm-linux-gnueabi-gcc-9.2`
- **macOS**: `$TIZEN_SDK/tools/arm-linux-gnueabi-gcc-9.2`
- **Windows**: Not supported for cross-compilation

## Sysroot Configuration

The configure script automatically sets up the sysroot based on your Tizen SDK installation:

```
$TIZEN_SDK/platforms/tizen-$TIZEN_VERSION/mobile/rootstraps/$TIZEN_ROOTSTRAP
```

Or for TV platforms:

```
$TIZEN_SDK/platforms/tizen-$TIZEN_VERSION/tv/rootstraps/$TIZEN_ROOTSTRAP
```

## Compiler Flags

The configure script sets appropriate compiler flags for Tizen:

### ARM
- `-march=armv7-a`: Target ARMv7-A architecture
- `-mfloat-abi=softfp`: Use soft-float ABI
- `-mfpu=neon`: Enable NEON SIMD instructions
- `-mtune=cortex-a9`: Optimize for Cortex-A9

### x86/x86_64
- `-march=i686` or native: Target architecture
- `-mtune=i686` or native: Optimization target

### Common Flags
- `-fPIC -DPIC`: Position-independent code (required for shared libraries)
- `-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64`: Large file support
- `-Os`: Optimize for size (important for embedded devices)

## Troubleshooting

### Toolchain Not Found

If configure fails with "toolchain not found":

1. Verify `TIZEN_SDK` environment variable is set correctly
2. Check that the toolchain directory exists
3. Use `--with-toolchain` to specify the exact path

### Missing Dependencies

If configure fails with missing dependencies:

1. Install required build tools: `autoconf`, `automake`, `libtool`, `pkg-config`, `cmake`
2. Ensure Tizen Studio is properly installed
3. Check that the Tizen SDK version matches your rootstrap

### Compilation Errors

If dependencies fail to build:

1. Check the build log in the specific dependency directory
2. Ensure you have enough disk space
3. Try building with `--enable-debug=yes` for more verbose output
4. Check that your Tizen SDK is up to date

## Next Steps

After successfully building dependencies:

1. Configure Kodi itself using the built dependencies
2. Build Kodi for Tizen
3. Package as TPK
4. Deploy to device or emulator

See the main Kodi documentation for complete build instructions.

## References

- [Tizen Developer Documentation](https://developer.tizen.org/)
- [Tizen Studio Download](https://developer.tizen.org/development/tizen-studio)
- [Kodi Build Documentation](../../docs/README.md)
- [webOS Port](../webOS/) - Similar TV platform implementation
