![Kodi Logo](resources/banner_slim.png)

# Tizen build guide

This guide has been tested with Tizen Studio 5.0+ and Samsung Smart TVs (2020+ models). The host OS used for compilation was Ubuntu 22.04 LTS (64-bit). Other combinations may work but we provide no assurances that other combinations will build correctly and run identically to Team Kodi releases. Kodi will build and run on Tizen 5.5+ (Samsung 2020+ models) using **[Kodi's unified depends build system](../tools/depends/README.md)**. Please read it in full before you proceed to familiarize yourself with the build procedure. Note that you do not need to "root" your TV to install Kodi.

## Table of Contents
1. **[Document conventions](#1-document-conventions)**
2. **[Prerequisites](#2-prerequisites)**
3. **[Configure the toolchain](#3-configure-the-toolchain)**
4. **[Configure SDB tools](#4-configure-sdb-tools)**
5. **[Get the source code](#5-get-the-source-code)**  
6. **[Configure and build tools and dependencies](#6-configure-and-build-tools-and-dependencies)**  
  6.1. **[Advanced Configure Options](#61-advanced-configure-options)**
7. **[Generate Kodi Build files](#7-generate-kodi-build-files)**  
  7.1. **[Generate Project Files](#71-generate-project-files)**  
  7.2. **[Add Binary Addons to Project](#72-add-binary-addons-to-project)**
8. **[Build](#8-build)**  
  8.1. **[Build Kodi binary](#81-build-kodi-binary)**
9. **[Packaging Kodi to distribute as a TPK](#9-packaging-kodi-to-distribute-as-a-tpk)**  
  9.1. **[Create the TPK](#91-create-the-tpk)**  
  9.2. **[Sign the TPK](#92-sign-the-tpk)**
10. **[Install](#10-install)**  
  10.1. **[Using deployment script](#101-using-deployment-script)**  
  10.2. **[Using SDB to install](#102-using-sdb-to-install)**
11. **[Debugging](#11-debugging)**  
  11.1. **[Viewing logs](#111-viewing-logs)**  
  11.2. **[Accessing crash logs](#112-accessing-crash-logs)**  
  11.3. **[Remote debugging](#113-remote-debugging)**
12. **[Uninstall](#12-uninstall)**  
  12.1. **[Using deployment script](#121-using-deployment-script)**  
  12.2. **[Using SDB to uninstall](#122-using-sdb-to-uninstall)**
13. **[Platform-specific considerations](#13-platform-specific-considerations)**  
  13.1. **[Tizen API usage](#131-tizen-api-usage)**  
  13.2. **[Known limitations](#132-known-limitations)**  
  13.3. **[Troubleshooting](#133-troubleshooting)**

## 1. Document conventions

This guide assumes you are using `terminal`, also known as `console`, `command-line` or simply `cli`. Commands need to be run at the terminal, one at a time and in the provided order.

This is a comment that provides context:
```
this is a command
this is another command
and yet another one
```

**Example:** Clone Kodi's current master branch:
```
git clone https://github.com/xbmc/xbmc kodi
```

Commands that contain strings enclosed in angle brackets denote something you need to change to suit your needs.
```
git clone -b <branch-name> https://github.com/xbmc/xbmc kodi
```

**Example:** Clone Kodi's current Nexus branch:
```
git clone -b Nexus https://github.com/xbmc/xbmc kodi
```

Several different strategies are used to draw your attention to certain pieces of information. In order of how critical the information is, these items are marked as a note, tip, or warning. For example:

> [!NOTE]  
> Linux is user friendly... It's just very particular about who its friends are.

> [!TIP]
> Algorithm is what developers call code they do not want to explain.

> [!WARNING]  
> Developers don't change light bulbs. It's a hardware problem.

**[back to top](#table-of-contents)** | **[back to section top](#1-document-conventions)**

## 2. Prerequisites

* **[Tizen Studio](https://developer.tizen.org/development/tizen-studio/download)**. Download and install Tizen Studio 5.0 or later. This provides the toolchain, SDK, and development tools.
* **[Tizen SDK](https://developer.tizen.org/development/tizen-studio)**. Install the TV SDK extensions via Tizen Studio Package Manager (TV Extensions 6.0 or later recommended).
* **[Tizen Certificate](https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk/creating-certificates.html)**. Create a certificate for signing TPK packages. Required for installation on physical devices.
* **[Enable Developer Mode on Samsung TV](../tools/tizen/DEVELOPER_MODE_GUIDE.md)**. Follow the instructions to enable developer mode on your Samsung TV for testing and deployment.
* **[SDB (Smart Development Bridge)](https://developer.tizen.org/development/tizen-studio/native-tools/smart-development-bridge)**. Included with Tizen Studio. Used for deploying and debugging applications.

* Device with **Tizen 5.5 or newer** (Samsung TV 2020+ models).

Team Kodi CI infrastructure is limited, and therefore we only have the single combination tested. Newer Tizen versions may work, however the team does not actively test/use these versions, so use with caution. Earlier versions may work, however we don't actively support them, so use with caution.

**[back to top](#table-of-contents)**

## 3. Configure the toolchain

Set up environment variables for Tizen Studio:

```
export TIZEN_SDK=$HOME/tizen-studio
export TIZEN_VERSION=6.0
export TIZEN_ROOTSTRAP=tv-samsung-6.0-device.core
export PATH=$PATH:$TIZEN_SDK/tools
```

Add these to your `~/.bashrc` or `~/.zshrc` to make them permanent:

```
echo 'export TIZEN_SDK=$HOME/tizen-studio' >> ~/.bashrc
echo 'export TIZEN_VERSION=6.0' >> ~/.bashrc
echo 'export TIZEN_ROOTSTRAP=tv-samsung-6.0-device.core' >> ~/.bashrc
echo 'export PATH=$PATH:$TIZEN_SDK/tools' >> ~/.bashrc
source ~/.bashrc
```

Verify the toolchain is accessible:

```
ls $TIZEN_SDK/tools/arm-linux-gnueabi-gcc-9.2/bin/arm-linux-gnueabi-gcc
```

> [!NOTE]  
> The toolchain path may vary depending on your Tizen Studio version. Common paths include `arm-linux-gnueabi-gcc-9.2`, `arm-linux-gnueabi-gcc-10.2`, etc.

**[back to top](#table-of-contents)**

## 4. Configure SDB tools

You need to add your Samsung TV so that it can be used later in this guide. This step is only required once.

First, enable developer mode on your TV (see [Developer Mode Guide](../tools/tizen/DEVELOPER_MODE_GUIDE.md)):

1. Go to Apps panel on TV
2. Enter code: **12345**
3. Toggle Developer Mode **ON**
4. Enter your PC's IP address
5. Restart TV

Then connect via SDB:

```
sdb connect <TV_IP_ADDRESS>:26101
```

Verify connection:

```
sdb devices
```

You should see your TV listed. Note the device ID for later (e.g., `192.168.1.100:26101`).

> [!TIP]
> Use the connection helper script for easier device management:
> ```
> ./tools/tizen/connect.sh -c <TV_IP_ADDRESS>
> ./tools/tizen/connect.sh -l
> ```

**[back to top](#table-of-contents)**

## 5. Get the source code

Change to your `home` directory:
```
cd $HOME
```

Clone Kodi's current master branch:
```
git clone https://github.com/xbmc/xbmc kodi
```

**[back to top](#table-of-contents)**

## 6. Configure and build tools and dependencies

Kodi should be built as a 32-bit ARM program for Tizen (Samsung TVs use ARM processors). The dependencies are built in `$HOME/kodi/tools/depends` and installed into `$HOME/kodi-tizen-deps`.

--prefix should be set to where dependencies are going to be installed  
--host=arm-tizen-linux-gnueabi for ARM devices, or i686-tizen-linux-gnu for emulator  
--with-toolchain=/path/to/tizen-toolchain  

Configure build for ARM (Samsung TV):
```
cd $HOME/kodi/tools/depends
./bootstrap
./configure \
  --prefix=$HOME/kodi-tizen-deps \
  --host=arm-tizen-linux-gnueabi \
  --with-toolchain=$TIZEN_SDK/tools/arm-linux-gnueabi-gcc-9.2 \
  --with-platform=tizen \
  --with-rendersystem=gles \
  --enable-debug=no
```

Configure build for x86 (Tizen Emulator):
```
cd $HOME/kodi/tools/depends
./bootstrap
./configure \
  --prefix=$HOME/kodi-tizen-deps \
  --host=i686-tizen-linux-gnu \
  --with-toolchain=$TIZEN_SDK/tools/i686-linux-gnueabi-gcc-9.2 \
  --with-platform=tizen \
  --with-rendersystem=gles \
  --enable-debug=no
```

Build tools and dependencies:
```
make -j$(getconf _NPROCESSORS_ONLN)
```

> [!TIP]
> By adding `-j<number>` to the make command, you can choose how many concurrent jobs will be used and expedite the build process. It is recommended to use `-j$(getconf _NPROCESSORS_ONLN)` to compile on all available processor cores. The build machine can also be configured to do this automatically by adding `export MAKEFLAGS="-j$(getconf _NPROCESSORS_ONLN)"` to your shell config (e.g. `~/.bashrc`).

> [!WARNING]  
> Look for the `Dependencies built successfully.` success message. If in doubt run a single threaded `make` command until the message appears. If the single make fails, clean the specific library by issuing `make -C target/<name_of_failed_lib> distclean` and run `make` again.

> [!NOTE]  
> You can use the helper scripts for easier configuration:
> ```
> ./tools/tizen/configure-tizen-arm.sh    # For Samsung TV
> ./tools/tizen/configure-tizen-x86.sh    # For emulator
> ```

### 6.1. Advanced Configure Options

**All platforms:**

```
--prefix=<path>
```
  specify installation path for dependencies (default: $HOME/kodi-tizen-deps)

```
--enable-debug=<yes:no>
```
  enable debugging information (default is yes)

```
--disable-ccache
```
  disable ccache

```
--with-tarballs=<path>
```
  path where tarballs will be saved [prefix/xbmc-tarballs]

```
--with-cpu=<cpu>
```
  optional. specify target cpu. guessed if not specified

```
--with-linker=<linker>
```
  specify linker to use. (default is ld)

```
--with-platform=<platform>
```
  target platform (must be "tizen")

```
--with-rendersystem=<system>
```
  render system to use (must be "gles" for Tizen)

```
--enable-gplv3=<yes:no>
```
  enable gplv3 components. (default is yes)

```
--with-target-cflags=<cflags>
```
  C compiler flags (target)

```
--with-target-cxxflags=<cxxflags>
```
  C++ compiler flags (target)

```
--with-target-ldflags=<ldflags>
```
  linker flags. Use e.g. for -l<lib> (target)

```
--with-ffmpeg-options
```
  FFmpeg configure options, e.g. --enable-v4l2-m2m (for hardware video decoding)

**[back to top](#table-of-contents)**

## 7. Generate Kodi Build files

Before you can build Kodi, the build files have to be generated with CMake. CMake is built as part of the dependencies and doesn't have to be installed separately. A toolchain file is also generated and is used to configure CMake.
Default behaviour will not build binary addons. To add addons to your build go to **[Add Binary Addons to Project](#72-add-binary-addons-to-project)**

## 7.1. Generate Project Files

Before you can build Kodi, the project has to be generated with CMake. CMake is built as part of the dependencies and doesn't have to be installed separately. A toolchain file is also generated and is used to configure CMake.

Generate project for Tizen:
```
make -C tools/depends/target/cmakebuildsys
```

> [!TIP]
> BUILD_DIR can be omitted, and project will be created in $HOME/kodi/build
> Change all relevant paths onwards if omitted.

Additional cmake arguments can be supplied via the CMAKE_EXTRA_ARGUMENTS command line variable.

An example of extra arguments to configure specific options:
````
make -C tools/depends/target/cmakebuildsys BUILD_DIR=$HOME/kodi/build \
	CMAKE_EXTRA_ARGUMENTS="-DCORE_PLATFORM_NAME=tizen -DENABLE_DBUS=OFF"
````

## 7.2. Add Binary Addons to Project

You can find a complete list of available binary add-ons **[here](https://github.com/xbmc/repo-binary-addons)**.

Binary addons are optional.

To build all add-ons:
```
make -j$(getconf _NPROCESSORS_ONLN) -C tools/depends/target/binary-addons PREFIX=$HOME/kodi/build
```

Build specific add-ons:
```
make -j$(getconf _NPROCESSORS_ONLN) -C tools/depends/target/binary-addons PREFIX=$HOME/kodi/build ADDONS="audioencoder.flac pvr.iptvsimple audiodecoder.sidplay"
```

Build a specific group of add-ons:
```
make -j$(getconf _NPROCESSORS_ONLN) -C tools/depends/target/binary-addons PREFIX=$HOME/kodi/build ADDONS="pvr.*"
```

To build specific addons or help with regular expression usage for ADDONS_TO_BUILD, view ADDONS_TO_BUILD section located at [Kodi add-ons CMake based buildsystem](../cmake/addons/README.md)

**[back to top](#table-of-contents)** | **[back to section top](#7-generate-kodi-build-files)**

## 8. Build

### 8.1. Build Kodi binary

In `$HOME/kodi/build`:

```
make -j$(getconf _NPROCESSORS_ONLN)
```

> [!WARNING]  
> Building for simulator/emulator requires x86 configuration (see section 6).

**[back to top](#table-of-contents)** | **[back to section top](#8-build)**

## 9. Packaging Kodi to distribute as a TPK

## 9.1. Create the TPK

CMake generates a target called `tpk` which will package Kodi ready for distribution.

Create package:
```
cd $HOME/kodi/build
make tpk
```

The generated TPK file will be in the build directory. The filename will be similar to `org.xbmc.kodi_21.0.0_arm.tpk`.

> [!NOTE]  
> The packaging script automatically includes:
> - Kodi binary and all required libraries
> - UI assets (skins, icons, fonts, images)
> - Tizen manifest with correct metadata and privileges
> - Application icons in required sizes

## 9.2. Sign the TPK

Before installation on a physical device, the TPK must be signed with a valid Tizen certificate.

Sign the package:
```
./tools/tizen/packaging/sign.sh org.xbmc.kodi_21.0.0_arm.tpk
```

This will create a signed TPK file: `org.xbmc.kodi_21.0.0_arm-signed.tpk`

> [!TIP]
> For development and testing, you can skip signing if developer mode is enabled on your TV. The deployment script will handle unsigned TPKs automatically.

> [!WARNING]  
> Signed TPKs are required for:
> - Distribution to end users
> - Installation on devices without developer mode
> - Submission to app stores

**[back to top](#table-of-contents)**

## 10. Install

## 10.1. Using deployment script

The easiest way to install Kodi on your Samsung TV:

```
./tools/tizen/deploy.sh -u -l
```

This will:
- Auto-detect the TPK file in the build directory
- Uninstall any existing version (`-u`)
- Install the new version
- Launch Kodi automatically (`-l`)

Deploy to specific device (if multiple connected):
```
./tools/tizen/deploy.sh -d 192.168.1.100:26101 -u -l
```

Deploy specific TPK file:
```
./tools/tizen/deploy.sh -t org.xbmc.kodi_21.0.0_arm.tpk -u -l
```

## 10.2. Using SDB to install

Alternatively, you can use SDB directly for more control:

```
sdb push org.xbmc.kodi_21.0.0_arm.tpk /tmp/kodi.tpk
sdb shell "pkgcmd -i -t tpk -p /tmp/kodi.tpk"
sdb shell "app_launcher -s org.xbmc.kodi"
```

> [!NOTE]  
> For detailed deployment instructions and troubleshooting, see the [SDB Deployment Guide](../tools/tizen/SDB_DEPLOYMENT_GUIDE.md).

**[back to top](#table-of-contents)**

## 11. Debugging

## 11.1. Viewing logs

View Kodi logs in real-time:

```
./tools/tizen/logs.sh -f
```

View only errors:
```
./tools/tizen/logs.sh -l E
```

Filter logs by keyword:
```
./tools/tizen/logs.sh -g "video"
```

Save logs to file:
```
./tools/tizen/logs.sh -s kodi-debug.log
```

Or use SDB directly:
```
sdb dlog KODI:V
```

## 11.2. Accessing crash logs

View crash logs:

```
./tools/tizen/logs.sh -C
```

Download crash logs from device:
```
sdb pull /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_*.log ./
```

View most recent crash log:
```
sdb shell "cat \$(ls -t /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_*.log | head -n1)"
```

> [!NOTE]  
> For detailed crash logging information, see the [Crash Logging Guide](../tools/tizen/CRASH_LOGGING_GUIDE.md).

## 11.3. Remote debugging

Connect via SSH to your TV (developer mode required):

```
sdb shell
```

Access application files:
```
cd /opt/usr/apps/org.xbmc.kodi/
ls -la
```

Access user data:
```
cd /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/.kodi/
ls -la
```

Monitor CPU and memory usage:
```
sdb shell "top -n 1 | grep kodi"
sdb shell "cat /proc/\$(pidof kodi-tizen)/status | grep VmRSS"
```

> [!TIP]
> Use `sdb root on` to enable root access for advanced debugging (may not work on all devices).

**[back to top](#table-of-contents)**

## 12. Uninstall

## 12.1. Using deployment script

```
./tools/tizen/deploy.sh -u
```

## 12.2. Using SDB to uninstall

```
sdb shell "pkgcmd -u -n org.xbmc.kodi"
```

Or kill the running application:
```
sdb shell "app_launcher -k org.xbmc.kodi"
```

**[back to top](#table-of-contents)**

## 13. Platform-specific considerations

## 13.1. Tizen API usage

Kodi for Tizen uses the following Tizen native APIs:

### Application Framework
- **app_event_set_cb()** - Application lifecycle management (pause, resume, terminate)
- **app_get_data_path()** - Get application data directory for settings and user data
- **app_control** - Application control and inter-app communication

### Media APIs
- **player_create()** - Create media player instance
- **player_set_uri()** - Set media source
- **player_start()**, **player_pause()**, **player_stop()** - Playback control
- **player_set_display()** - Configure video output
- **player_set_media_packet_video_frame_decoded_cb()** - Video frame callbacks

### Display and Graphics
- **Wayland** - Window management and display server protocol
- **EGL** - OpenGL ES context creation
- **OpenGL ES 2.0/3.0** - Graphics rendering
- **system_info_get_platform_string()** - Display capabilities and HDR support

### System APIs
- **dlog_print()** - System logging (accessible via `sdb dlog`)
- **system_info_get_*()** - System information (CPU, GPU, memory)
- **storage_get_internal_memory_size()** - Storage space queries

### Network APIs
- **connection_create()** - Network status monitoring
- **wifi_manager** - Wi-Fi information and status
- Standard POSIX networking (sockets, DNS resolution)

### Input APIs
- **Wayland input events** - Remote control button handling
- **sound_manager** - System volume control

## 13.2. Known limitations

### Hardware Limitations
- **Performance**: Varies by TV model and year. Older models (2020-2021) may have limited CPU/GPU performance.
- **Memory**: Typically 1-2 GB RAM available for applications. Large libraries or high-resolution artwork may cause memory pressure.
- **Storage**: Limited internal storage (typically 4-8 GB for apps). Users should manage library size accordingly.

### Platform Limitations
- **HDR Support**: HDR10 is supported on compatible TVs. Dolby Vision support depends on TV model and Tizen version.
- **Audio Formats**: Some audio codecs may require software decoding. Hardware acceleration availability varies by TV model.
- **Video Codecs**: H.264 and H.265/HEVC are hardware accelerated. AV1 support depends on TV model (2022+ models).
- **DRM**: Widevine and PlayReady support varies by TV model. Some protected content may not play.
- **Network Protocols**: SMB/CIFS, NFS, HTTP(S) are supported. AFP and other protocols may require addons.

### UI Limitations
- **Remote Control Only**: No mouse or keyboard support (unless connected via USB/Bluetooth).
- **Navigation**: Optimized for D-pad navigation. Some complex UI elements may be difficult to navigate.
- **Text Input**: On-screen keyboard only. Text entry is slower than physical keyboard.

### Functional Limitations
- **Background Playback**: Application is paused when backgrounded (Tizen platform requirement).
- **Screen Saver**: Uses Tizen's screen saver APIs. Custom screen savers may have limited functionality.
- **Power Management**: Application must respond to TV power events (standby, wake).
- **Updates**: Application updates require reinstallation of TPK package.

### Development Limitations
- **Debugging**: Limited debugging tools compared to desktop platforms. Primarily log-based debugging.
- **Emulator**: Tizen emulator performance is slower than physical devices. Not suitable for performance testing.
- **Testing**: Physical device testing is essential. Emulator cannot replicate all TV-specific behaviors.

## 13.3. Troubleshooting

### Build Issues

#### Problem: "Toolchain not found"

**Solution:**
```
# Verify TIZEN_SDK is set correctly
echo $TIZEN_SDK

# Check toolchain exists
ls $TIZEN_SDK/tools/arm-linux-gnueabi-gcc-9.2/bin/

# Set explicitly in configure
./configure --with-toolchain=$TIZEN_SDK/tools/arm-linux-gnueabi-gcc-9.2 ...
```

#### Problem: "Dependencies fail to build"

**Solution:**
```
# Clean specific dependency
make -C target/<dependency-name> distclean

# Rebuild with verbose output
make V=1

# Check build log
cat target/<dependency-name>/<dependency-name>.log
```

#### Problem: "CMake configuration fails"

**Solution:**
```
# Clean build directory
rm -rf build/
mkdir build

# Regenerate with verbose output
make -C tools/depends/target/cmakebuildsys CMAKE_EXTRA_ARGUMENTS="-DCMAKE_VERBOSE_MAKEFILE=ON"
```

### Installation Issues

#### Problem: "Installation failed - signature verification"

**Solution:**
```
# For development, enable developer mode on TV
# See: tools/tizen/DEVELOPER_MODE_GUIDE.md

# Or sign the TPK
./tools/tizen/packaging/sign.sh <tpk-file>
```

#### Problem: "Installation failed - insufficient storage"

**Solution:**
```
# Check available storage
sdb shell "df -h"

# Remove unused apps from TV
# Or reduce Kodi package size by removing optional components
```

#### Problem: "Cannot connect to TV via SDB"

**Solution:**
```
# Verify developer mode is enabled
# Check TV and PC are on same network
ping <TV_IP>

# Restart SDB server
sdb kill-server
sdb start-server

# Connect with explicit port
sdb connect <TV_IP>:26101

# Check firewall allows port 26101
```

### Runtime Issues

#### Problem: "Application crashes on startup"

**Solution:**
```
# Check crash logs
./tools/tizen/logs.sh -C

# View detailed logs
./tools/tizen/logs.sh -l E -f

# Verify all dependencies are included
sdb shell "ldd /opt/usr/apps/org.xbmc.kodi/bin/kodi-tizen"
```

#### Problem: "Video playback fails or stutters"

**Solution:**
```
# Check codec support
sdb shell "gst-inspect-1.0"

# Try different video file
# Check network bandwidth for streaming

# View playback logs
./tools/tizen/logs.sh -g "video" -f
```

#### Problem: "Remote control not responding"

**Solution:**
```
# Check input logs
./tools/tizen/logs.sh -g "input" -f

# Verify remote is paired with TV
# Try different remote buttons

# Restart application
sdb shell "app_launcher -k org.xbmc.kodi"
sdb shell "app_launcher -s org.xbmc.kodi"
```

#### Problem: "Settings not persisting"

**Solution:**
```
# Check data directory permissions
sdb shell "ls -la /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/"

# Verify settings file exists
sdb shell "cat /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/.kodi/userdata/guisettings.xml"

# Check storage space
sdb shell "df -h"
```

### Performance Issues

#### Problem: "UI is slow or laggy"

**Solution:**
- Reduce thumbnail cache size in settings
- Disable animations in skin settings
- Use a lighter skin (Estuary is recommended)
- Clear thumbnail cache periodically
- Check CPU usage: `sdb shell "top -n 1 | grep kodi"`

#### Problem: "High memory usage"

**Solution:**
- Reduce library size
- Clear thumbnail cache
- Disable unused addons
- Monitor memory: `sdb shell "cat /proc/$(pidof kodi-tizen)/status | grep VmRSS"`

#### Problem: "Slow library scanning"

**Solution:**
- Use wired Ethernet instead of Wi-Fi
- Reduce number of media sources
- Use local storage instead of network shares
- Enable "Background scanning" in settings

### Network Issues

#### Problem: "Cannot access network shares"

**Solution:**
```
# Test network connectivity
sdb shell "ping -c 3 <server-ip>"

# Check DNS resolution
sdb shell "nslookup <hostname>"

# Verify network permissions in manifest
sdb shell "cat /opt/usr/apps/org.xbmc.kodi/tizen-manifest.xml | grep network"

# Check firewall on server
```

#### Problem: "Streaming buffering or stuttering"

**Solution:**
- Use wired Ethernet connection
- Reduce video quality/bitrate
- Check network bandwidth
- Adjust cache settings in advancedsettings.xml
- Test with local files to isolate network issues

### Additional Resources

For more detailed troubleshooting and guides:

- **[Developer Mode Guide](../tools/tizen/DEVELOPER_MODE_GUIDE.md)** - Enable developer mode and unsigned TPK installation
- **[SDB Deployment Guide](../tools/tizen/SDB_DEPLOYMENT_GUIDE.md)** - Detailed deployment and debugging instructions
- **[Emulator Guide](../tools/tizen/EMULATOR_GUIDE.md)** - Set up and use Tizen emulator for development
- **[Crash Logging Guide](../tools/tizen/CRASH_LOGGING_GUIDE.md)** - Access and analyze crash logs
- **[Data Management Guide](../xbmc/platform/linux/TIZEN_DATA_MANAGEMENT.md)** - Settings persistence and storage management

**[back to top](#table-of-contents)**

