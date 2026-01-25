# Kodi Tizen Packaging

This directory contains scripts and resources for packaging Kodi as a Tizen TPK (Tizen Package) file for installation on Samsung smart TVs.

## Overview

The packaging system consists of:

- **tizen-manifest.xml.in** - Tizen application manifest template
- **package.sh** - Main packaging script that creates TPK files
- **sign.sh** - TPK signing script for certificate-based signing
- **prepare-icons.sh** - Icon preparation and validation script
- **icons/** - Application icon assets

## Prerequisites

1. **Tizen Studio** - Install from https://developer.samsung.com/tizen
2. **Tizen SDK** - Set `TIZEN_SDK` environment variable to your Tizen Studio installation path
3. **Tizen Certificate** - Create a certificate profile using Tizen Studio Certificate Manager
4. **Built Kodi** - Build Kodi for Tizen before packaging

## Quick Start

### 1. Build Kodi for Tizen

```bash
cd /path/to/kodi
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/tizen.cmake
make
```

### 2. Create TPK Package

Using CMake target (recommended):
```bash
make tpk
```

Or using the script directly:
```bash
export TIZEN_SDK=/path/to/tizen-studio
export TIZEN_SECURITY_PROFILE=my-profile
./tools/tizen/packaging/package.sh
```

### 3. Sign TPK (if not auto-signed)

```bash
make sign-tpk
```

Or:
```bash
./tools/tizen/packaging/sign.sh build/org.xbmc.kodi-21.0.0.tpk
```

### 4. Install on Device

```bash
sdb connect <TV_IP_ADDRESS>
sdb install build/org.xbmc.kodi-21.0.0.tpk
```

## Environment Variables

### Required

- `TIZEN_SDK` - Path to Tizen Studio installation
  - Example: `/home/user/tizen-studio`

### Optional

- `TIZEN_SECURITY_PROFILE` - Security profile name for signing
  - If set, TPK will be automatically signed during packaging
  - If not set, an unsigned TPK will be created (developer mode only)
  
- `BUILD_DIR` - Build directory path (default: `build`)
- `PACKAGE_DIR` - Temporary packaging directory (default: `build/package`)
- `OUTPUT_DIR` - Output directory for TPK file (default: `build`)
- `APP_VERSION` - Application version (default: from version.txt)

## Packaging Process

The packaging script performs the following steps:

1. **Validate Requirements** - Check for Tizen SDK and tools
2. **Create Package Structure** - Set up Tizen app directory layout
3. **Copy Binary** - Copy Kodi executable to `bin/kodi-tizen`
4. **Copy Libraries** - Include all required shared libraries
5. **Copy Resources** - Include UI assets, skins, fonts, addons
6. **Copy Icons** - Include application icons
7. **Generate Manifest** - Create tizen-manifest.xml from template
8. **Create TPK** - Package everything into a TPK file
9. **Sign TPK** (optional) - Sign with certificate if profile is set

## Directory Structure

The TPK package contains:

```
org.xbmc.kodi-21.0.0.tpk
├── bin/
│   └── kodi-tizen              # Main executable
├── lib/
│   └── *.so                    # Shared libraries
├── res/
│   ├── media/                  # Media files (icons, images)
│   ├── addons/                 # Kodi addons
│   ├── system/                 # System files
│   └── userdata/               # User data templates
├── shared/
│   └── res/
│       └── kodi.png            # Application icon
├── tizen-manifest.xml          # Application manifest
└── author-signature.xml        # Signature (if signed)
```

## Signing

### Creating a Certificate Profile

1. Open Tizen Studio
2. Go to Tools → Certificate Manager
3. Create a new certificate profile
4. Follow the wizard to generate or import certificates
5. Note the profile name for use with `TIZEN_SECURITY_PROFILE`

### Signing Options

**Option 1: Automatic signing during packaging**
```bash
export TIZEN_SECURITY_PROFILE=my-profile
make tpk
```

**Option 2: Sign after packaging**
```bash
make tpk
make sign-tpk
```

**Option 3: Manual signing**
```bash
./tools/tizen/packaging/sign.sh -p my-profile build/org.xbmc.kodi-21.0.0.tpk
```

### Unsigned TPK

If no certificate profile is set, an unsigned TPK will be created. Unsigned TPKs can only be installed on devices in developer mode.

To enable developer mode on Samsung TV:
1. Go to Apps
2. Press 1-2-3-4-5 on the remote
3. Enable Developer Mode
4. Enter your PC's IP address
5. Restart the TV

## Installation

### Using SDB (Smart Development Bridge)

1. **Connect to TV**
   ```bash
   sdb connect <TV_IP_ADDRESS>
   ```

2. **Verify connection**
   ```bash
   sdb devices
   ```

3. **Install TPK**
   ```bash
   sdb install build/org.xbmc.kodi-21.0.0.tpk
   ```

4. **Launch Kodi**
   ```bash
   sdb shell app_launcher -s org.xbmc.kodi
   ```

### Using Tizen Studio

1. Open Tizen Studio
2. Go to Tools → Device Manager
3. Connect to your TV
4. Right-click the device → Install Application
5. Select the TPK file

## Troubleshooting

### "TIZEN_SDK not found"

Set the TIZEN_SDK environment variable:
```bash
export TIZEN_SDK=/path/to/tizen-studio
```

### "Security profile not found"

Create a certificate profile in Tizen Studio Certificate Manager, or create an unsigned TPK:
```bash
unset TIZEN_SECURITY_PROFILE
make tpk
```

### "Kodi binary not found"

Build Kodi before packaging:
```bash
make
make tpk
```

### "TPK installation failed"

- Ensure TV is in developer mode (for unsigned TPKs)
- Check that the certificate matches the TV (for signed TPKs)
- Verify SDB connection: `sdb devices`
- Check TV logs: `sdb dlog KODI:V`

### "Icon not found"

Run the icon preparation script:
```bash
./tools/tizen/packaging/prepare-icons.sh
```

## Advanced Usage

### Custom Package Version

```bash
APP_VERSION=21.1.0 make tpk
```

### Custom Output Directory

```bash
OUTPUT_DIR=/path/to/output make tpk
```

### Packaging Without CMake

```bash
export BUILD_DIR=/path/to/build
export TIZEN_SDK=/path/to/tizen-studio
./tools/tizen/packaging/package.sh
```

## Files

- `tizen-manifest.xml.in` - Manifest template with version placeholder
- `package.sh` - Main packaging script
- `sign.sh` - Signing script
- `prepare-icons.sh` - Icon preparation script
- `icons/kodi.png` - Application icon (256x256)
- `icons/README.md` - Icon documentation

## References

- [Tizen Developer Guide](https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk/installing-tv-sdk.html)
- [Tizen Application Packaging](https://developer.tizen.org/development/tizen-studio/native-tools/packaging-your-app)
- [Samsung TV Developer Documentation](https://developer.samsung.com/smarttv/develop/guides/fundamentals.html)
- [Kodi Tizen Build Guide](../../../docs/README.Tizen.md) (to be created)

## Support

For issues and questions:
- Kodi Forum: https://forum.kodi.tv/
- Kodi GitHub: https://github.com/xbmc/xbmc/issues
- Samsung Developer Forum: https://forum.developer.samsung.com/
