# Kodi for Tizen - Platform-Specific Notes

This document provides detailed information about Tizen-specific implementation details, API usage, known limitations, and troubleshooting guidance for developers working on or maintaining the Kodi Tizen port.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Tizen API Usage](#tizen-api-usage)
3. [Platform Integration](#platform-integration)
4. [Known Limitations](#known-limitations)
5. [Performance Considerations](#performance-considerations)
6. [Troubleshooting Guide](#troubleshooting-guide)
7. [Best Practices](#best-practices)
8. [Testing Recommendations](#testing-recommendations)

## Architecture Overview

### Platform Layer Structure

```
Kodi Core
    ↓
CPlatformTizen (xbmc/platform/linux/PlatformTizen.cpp)
    ↓
Tizen Native APIs
    ↓
Tizen OS (Linux-based)
```

### Key Components

1. **Platform Abstraction** (`CPlatformTizen`)
   - Application lifecycle management
   - System information queries
   - Power management
   - File system paths

2. **Windowing System** (`CWinSystemWaylandTizen`)
   - Wayland display server integration
   - EGL context management
   - Display configuration
   - HDR capability detection

3. **Media Pipeline** (`CMediaPipelineTizen`)
   - AVPlay integration for hardware acceleration
   - Audio/video playback control
   - Codec capability reporting
   - Subtitle rendering

4. **Input Handling** (`CSeatTizen`)
   - Remote control event processing
   - Key mapping to Kodi actions
   - Volume control integration

## Tizen API Usage

### Application Framework APIs

#### Lifecycle Management

```cpp
// Register lifecycle callbacks
app_event_handler_h handlers[3];
app_event_set_cb(APP_EVENT_LOW_MEMORY, OnLowMemory, nullptr, &handlers[0]);
app_event_set_cb(APP_EVENT_LOW_BATTERY, OnLowBattery, nullptr, &handlers[1]);
app_event_set_cb(APP_EVENT_DEVICE_ORIENTATION_CHANGED, OnOrientationChanged, nullptr, &handlers[2]);
```

**Key Functions:**
- `app_event_set_cb()` - Register event callbacks
- `app_get_data_path()` - Get application data directory
- `app_control_*()` - Application control and IPC

**Lifecycle Events:**
- `APP_EVENT_LOW_MEMORY` - System low memory warning
- `APP_EVENT_LOW_BATTERY` - Low battery warning (for portable devices)
- `APP_EVENT_DEVICE_ORIENTATION_CHANGED` - Screen orientation change

**Implementation Notes:**
- Always save state in pause handler
- Release resources in low memory handler
- Respond to terminate event within 5 seconds

#### Data Directory Management

```cpp
// Get application data path
char* dataPath = nullptr;
app_get_data_path(&dataPath);
std::string homePath(dataPath);
free(dataPath);

// Typical path: /opt/usr/apps/org.xbmc.kodi/data/
```

**Directory Structure:**
```
/opt/usr/apps/org.xbmc.kodi/
├── bin/                    # Application binaries
├── data/                   # User data (preserved across updates)
│   └── .kodi/             # Kodi user directory
│       ├── userdata/      # Settings and profiles
│       ├── addons/        # Installed addons
│       └── temp/          # Temporary files
├── res/                   # Application resources
└── shared/                # Shared resources
```

### Media APIs (AVPlay)

#### Player Creation and Configuration

```cpp
// Create player
player_h player;
player_create(&player);

// Set URI
player_set_uri(player, "file:///path/to/video.mp4");

// Configure display
player_set_display(player, PLAYER_DISPLAY_TYPE_OVERLAY, GET_DISPLAY(evas_object));

// Set callbacks
player_set_completed_cb(player, OnPlaybackComplete, userData);
player_set_error_cb(player, OnPlaybackError, userData);
player_set_buffering_cb(player, OnBuffering, userData);

// Prepare and start
player_prepare(player);
player_start(player);
```

**Key Functions:**
- `player_create()` / `player_destroy()` - Player lifecycle
- `player_set_uri()` - Set media source (file://, http://, rtsp://)
- `player_prepare()` - Prepare for playback (async)
- `player_start()` / `player_pause()` / `player_stop()` - Playback control
- `player_set_play_position()` - Seek to position
- `player_get_play_position()` / `player_get_duration()` - Query playback state

**Supported URI Schemes:**
- `file://` - Local files
- `http://` / `https://` - HTTP streaming
- `rtsp://` - RTSP streaming
- `hls://` - HLS streaming (HTTP Live Streaming)

**Implementation Notes:**
- Always call `player_prepare()` before `player_start()`
- Handle async callbacks for state changes
- Check return codes for all player operations
- Release player resources in `player_destroy()`

#### Codec Capability Detection

```cpp
// Query supported codecs
bool isCodecSupported = false;
player_is_supported_codec(PLAYER_CODEC_TYPE_VIDEO, "h264", &isCodecSupported);

// Common video codecs
player_is_supported_codec(PLAYER_CODEC_TYPE_VIDEO, "h264", &supported);    // H.264/AVC
player_is_supported_codec(PLAYER_CODEC_TYPE_VIDEO, "hevc", &supported);    // H.265/HEVC
player_is_supported_codec(PLAYER_CODEC_TYPE_VIDEO, "vp9", &supported);     // VP9
player_is_supported_codec(PLAYER_CODEC_TYPE_VIDEO, "av1", &supported);     // AV1 (2022+ models)

// Common audio codecs
player_is_supported_codec(PLAYER_CODEC_TYPE_AUDIO, "aac", &supported);     // AAC
player_is_supported_codec(PLAYER_CODEC_TYPE_AUDIO, "mp3", &supported);     // MP3
player_is_supported_codec(PLAYER_CODEC_TYPE_AUDIO, "ac3", &supported);     // AC3/Dolby Digital
player_is_supported_codec(PLAYER_CODEC_TYPE_AUDIO, "eac3", &supported);    // E-AC3/Dolby Digital Plus
```

**Hardware Acceleration:**
- H.264: Hardware accelerated on all models
- H.265/HEVC: Hardware accelerated on 2016+ models
- VP9: Hardware accelerated on 2018+ models
- AV1: Hardware accelerated on 2022+ models (select models)

### Display and Graphics APIs

#### Wayland Integration

```cpp
// Connect to Wayland display
wl_display* display = wl_display_connect(nullptr);

// Get registry and bind interfaces
wl_registry* registry = wl_display_get_registry(display);
wl_registry_add_listener(registry, &registryListener, nullptr);

// Create surface
wl_compositor* compositor = /* from registry */;
wl_surface* surface = wl_compositor_create_surface(compositor);
```

**Key Wayland Protocols:**
- `wl_compositor` - Surface creation
- `wl_surface` - Window surface
- `wl_shell` / `xdg_shell` - Window management
- `wl_seat` - Input device management
- `wl_output` - Display output information

#### EGL Context Creation

```cpp
// Get EGL display
EGLDisplay eglDisplay = eglGetDisplay((EGLNativeDisplayType)waylandDisplay);
eglInitialize(eglDisplay, nullptr, nullptr);

// Choose config
EGLint configAttribs[] = {
    EGL_RED_SIZE, 8,
    EGL_GREEN_SIZE, 8,
    EGL_BLUE_SIZE, 8,
    EGL_ALPHA_SIZE, 8,
    EGL_DEPTH_SIZE, 16,
    EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
    EGL_NONE
};
EGLConfig config;
EGLint numConfigs;
eglChooseConfig(eglDisplay, configAttribs, &config, 1, &numConfigs);

// Create context
EGLint contextAttribs[] = {
    EGL_CONTEXT_CLIENT_VERSION, 2,
    EGL_NONE
};
EGLContext context = eglCreateContext(eglDisplay, config, EGL_NO_CONTEXT, contextAttribs);

// Create window surface
EGLSurface surface = eglCreateWindowSurface(eglDisplay, config, waylandWindow, nullptr);

// Make current
eglMakeCurrent(eglDisplay, surface, surface, context);
```

**OpenGL ES Support:**
- OpenGL ES 2.0: All Tizen TV models
- OpenGL ES 3.0: 2016+ models
- OpenGL ES 3.1: 2018+ models

#### HDR Capability Detection

```cpp
// Query HDR support
bool isHDRSupported = false;
system_info_get_platform_bool("http://tizen.org/feature/display.hdr", &isHDRSupported);

// Query peak luminance
int peakLuminance = 0;
system_info_get_platform_int("http://tizen.org/feature/display.peak_luminance", &peakLuminance);
```

**HDR Formats:**
- HDR10: Supported on 2016+ models
- HDR10+: Supported on 2018+ models (Samsung proprietary)
- Dolby Vision: Supported on select 2018+ models
- HLG: Supported on 2017+ models

### System Information APIs

```cpp
// Get platform information
char* platformName = nullptr;
system_info_get_platform_string("http://tizen.org/system/platform.name", &platformName);

// Get model name
char* modelName = nullptr;
system_info_get_platform_string("http://tizen.org/system/model_name", &modelName);

// Get CPU architecture
char* cpuArch = nullptr;
system_info_get_platform_string("http://tizen.org/feature/platform.core.cpu.arch", &cpuArch);

// Get total RAM
int totalRAM = 0;
system_info_get_platform_int("http://tizen.org/feature/platform.core.ram.size", &totalRAM);

// Free strings
free(platformName);
free(modelName);
free(cpuArch);
```

**Common System Info Keys:**
- `http://tizen.org/system/platform.name` - Platform name (e.g., "Tizen")
- `http://tizen.org/system/platform.version` - Tizen version
- `http://tizen.org/system/model_name` - Device model
- `http://tizen.org/feature/platform.core.cpu.arch` - CPU architecture
- `http://tizen.org/feature/platform.core.ram.size` - Total RAM in MB

### Logging APIs (dlog)

```cpp
// Include dlog header
#include <dlog.h>

// Define log tag
#define LOG_TAG "KODI"

// Log messages
dlog_print(DLOG_ERROR, LOG_TAG, "Error occurred: %s", errorMsg);
dlog_print(DLOG_WARN, LOG_TAG, "Warning: %s", warningMsg);
dlog_print(DLOG_INFO, LOG_TAG, "Info: %s", infoMsg);
dlog_print(DLOG_DEBUG, LOG_TAG, "Debug: %s", debugMsg);
dlog_print(DLOG_VERBOSE, LOG_TAG, "Verbose: %s", verboseMsg);
```

**Log Levels:**
- `DLOG_FATAL` - Fatal errors (application will crash)
- `DLOG_ERROR` - Errors (operation failed)
- `DLOG_WARN` - Warnings (potential issues)
- `DLOG_INFO` - Informational messages
- `DLOG_DEBUG` - Debug messages
- `DLOG_VERBOSE` - Verbose debug messages

**Viewing Logs:**
```bash
# View all Kodi logs
sdb dlog KODI:V

# View only errors
sdb dlog KODI:E

# View with timestamps
sdb dlog -v time KODI:V
```

### Storage APIs

```cpp
// Get internal storage info
unsigned long long total = 0;
unsigned long long available = 0;

storage_info_h storage;
storage_get_internal_memory_size(&storage);
storage_get_total_space(storage, &total);
storage_get_available_space(storage, &available);
storage_free(storage);

// Check if storage is low
if (available < 100 * 1024 * 1024) {  // Less than 100 MB
    // Warn user about low storage
}
```

### Network APIs

```cpp
// Create connection handle
connection_h connection;
connection_create(&connection);

// Get connection type
connection_type_e netType;
connection_get_type(connection, &netType);

// Check if connected
if (netType != CONNECTION_TYPE_DISCONNECTED) {
    // Network is available
}

// Get IP address
char* ipAddress = nullptr;
connection_get_ip_address(connection, CONNECTION_ADDRESS_FAMILY_IPV4, &ipAddress);
free(ipAddress);

// Destroy connection handle
connection_destroy(connection);
```

**Connection Types:**
- `CONNECTION_TYPE_DISCONNECTED` - No connection
- `CONNECTION_TYPE_WIFI` - Wi-Fi connection
- `CONNECTION_TYPE_ETHERNET` - Wired Ethernet
- `CONNECTION_TYPE_CELLULAR` - Cellular (not applicable to TVs)

## Platform Integration

### Application Lifecycle

```
┌─────────────┐
│   Created   │
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Running   │ ←──────┐
└──────┬──────┘        │
       │               │
       ↓               │
┌─────────────┐        │
│   Paused    │ ───────┘
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Terminated  │
└─────────────┘
```

**State Transitions:**

1. **Created → Running**
   - Initialize platform
   - Load settings
   - Initialize windowing system
   - Start Kodi application

2. **Running → Paused**
   - User presses Home button
   - Another app is launched
   - TV enters standby mode
   - **Action**: Pause playback, save state

3. **Paused → Running**
   - User returns to Kodi
   - TV wakes from standby
   - **Action**: Resume playback, restore state

4. **Running/Paused → Terminated**
   - User closes app
   - System terminates app
   - **Action**: Save all data, release resources

### Power Management

```cpp
// Prevent screen dimming during playback
device_power_request_lock(POWER_LOCK_DISPLAY, 0);

// Allow screen dimming when idle
device_power_release_lock(POWER_LOCK_DISPLAY);
```

**Power Lock Types:**
- `POWER_LOCK_CPU` - Keep CPU active
- `POWER_LOCK_DISPLAY` - Keep display on
- `POWER_LOCK_DISPLAY_DIM` - Allow display dimming but stay on

### Input Event Flow

```
Remote Control Button Press
         ↓
Wayland Input Event
         ↓
CSeatTizen::HandleKeyPress()
         ↓
MapTizenKeyToKodiEvent()
         ↓
Kodi Input Manager
         ↓
Action Execution
```

**Key Mapping Example:**
```cpp
XBMC_Event CSeatTizen::MapTizenKeyToKodiEvent(uint32_t tizenKey)
{
    XBMC_Event event;
    event.type = XBMC_KEYDOWN;
    
    switch (tizenKey)
    {
        case TIZEN_KEY_UP:
            event.key.keysym.sym = XBMCK_UP;
            break;
        case TIZEN_KEY_DOWN:
            event.key.keysym.sym = XBMCK_DOWN;
            break;
        case TIZEN_KEY_SELECT:
            event.key.keysym.sym = XBMCK_RETURN;
            break;
        // ... more mappings
    }
    
    return event;
}
```

## Known Limitations

### Hardware Limitations

#### Memory Constraints
- **Available RAM**: 1-2 GB for applications (varies by model)
- **Impact**: Large libraries or high-resolution artwork may cause memory pressure
- **Mitigation**: 
  - Limit thumbnail cache size
  - Use lower resolution artwork
  - Implement aggressive cache cleanup

#### Storage Constraints
- **Available Storage**: 4-8 GB for all applications
- **Impact**: Limited space for Kodi, addons, and cache
- **Mitigation**:
  - Minimize package size
  - Store media on network shares
  - Implement cache size limits

#### CPU Performance
- **Processor**: ARM Cortex-A series (varies by model)
- **Impact**: Software decoding is slow, UI may lag on older models
- **Mitigation**:
  - Use hardware acceleration whenever possible
  - Optimize UI rendering
  - Reduce animation complexity

### Platform Limitations

#### Video Playback
- **Codec Support**: Hardware acceleration varies by model year
  - 2020-2021: H.264, H.265
  - 2022+: H.264, H.265, VP9, AV1 (select models)
- **Container Support**: MP4, MKV, AVI, TS
- **Limitation**: Some exotic codecs require software decoding
- **Workaround**: Transcode unsupported formats

#### Audio Playback
- **Codec Support**: AAC, MP3, AC3, E-AC3, DTS (passthrough)
- **Limitation**: Some lossless formats (TrueHD, DTS-HD MA) may not be supported
- **Workaround**: Use audio passthrough to external receiver

#### HDR Support
- **Formats**: HDR10 (all models), HDR10+ (2018+), Dolby Vision (select models)
- **Limitation**: HDR metadata handling varies by model
- **Workaround**: Test on target device, provide SDR fallback

#### Network Protocols
- **Supported**: HTTP(S), SMB/CIFS, NFS
- **Limited**: AFP, WebDAV (may require addons)
- **Not Supported**: Some proprietary protocols
- **Workaround**: Use supported protocols or develop addons

### UI/UX Limitations

#### Input Methods
- **Primary**: Remote control (D-pad navigation)
- **Limited**: USB keyboard/mouse (if supported by TV)
- **Not Supported**: Touch input, gesture control
- **Impact**: Text entry is slow, complex navigation is difficult

#### Screen Resolution
- **Supported**: 1080p (all models), 4K (2016+), 8K (2020+ select models)
- **Limitation**: UI must scale appropriately
- **Consideration**: Design for 10-foot UI (TV viewing distance)

#### Remote Control Responsiveness
- **Latency**: 50-100ms typical
- **Impact**: UI must feel responsive despite latency
- **Mitigation**: Optimize event handling, provide visual feedback

### Functional Limitations

#### Background Execution
- **Limitation**: Application is paused when backgrounded (Tizen requirement)
- **Impact**: No background playback, downloads pause
- **Workaround**: None - platform restriction

#### Multitasking
- **Limitation**: Only one foreground app at a time
- **Impact**: Cannot run Kodi alongside other apps
- **Workaround**: None - platform restriction

#### System Integration
- **Limitation**: Limited integration with TV's native features
- **Impact**: Cannot control TV settings, limited CEC support
- **Workaround**: Use Tizen APIs where available

#### Updates
- **Limitation**: Application updates require full TPK reinstall
- **Impact**: User data must be preserved across updates
- **Mitigation**: Use Tizen's data preservation mechanism

### Development Limitations

#### Debugging Tools
- **Available**: dlog (system log), SDB (remote shell)
- **Limited**: GDB support (requires root), profiling tools
- **Not Available**: Visual debuggers, memory profilers
- **Workaround**: Extensive logging, manual analysis

#### Emulator Limitations
- **Performance**: Slower than physical devices
- **Accuracy**: May not replicate all TV-specific behaviors
- **Graphics**: Software rendering, no hardware acceleration
- **Recommendation**: Use for development, test on physical device

#### Testing Challenges
- **Device Access**: Requires physical Samsung TV
- **Variety**: Many models with different capabilities
- **Automation**: Limited automated testing support
- **Recommendation**: Manual testing on representative devices

## Performance Considerations

### Optimization Strategies

#### Memory Management
```cpp
// Monitor memory usage
void CheckMemoryUsage()
{
    unsigned long long available = GetAvailableMemory();
    
    if (available < LOW_MEMORY_THRESHOLD)
    {
        // Clear thumbnail cache
        ClearThumbnailCache();
        
        // Reduce texture quality
        ReduceTextureQuality();
        
        // Notify user
        ShowLowMemoryWarning();
    }
}
```

#### Rendering Optimization
- Use texture atlases to reduce draw calls
- Implement view frustum culling
- Reduce overdraw with proper z-ordering
- Use mipmaps for scaled textures
- Limit animation complexity

#### Network Optimization
- Implement connection pooling
- Use HTTP keep-alive
- Cache DNS lookups
- Implement retry logic with exponential backoff
- Monitor bandwidth usage

#### Storage Optimization
- Implement cache size limits
- Use compression for cached data
- Clean up temporary files regularly
- Monitor available storage space

### Performance Monitoring

```cpp
// CPU usage
void MonitorCPUUsage()
{
    // Read /proc/stat for CPU usage
    // Log if usage exceeds threshold
}

// Memory usage
void MonitorMemoryUsage()
{
    // Read /proc/self/status for memory info
    // Log if usage exceeds threshold
}

// Frame rate
void MonitorFrameRate()
{
    // Track frame times
    // Log if FPS drops below threshold
}
```

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue: Application Fails to Start

**Symptoms:**
- App icon appears but doesn't launch
- Immediate crash after launch
- Black screen then exit

**Diagnosis:**
```bash
# Check crash logs
./tools/tizen/logs.sh -C

# View system logs
sdb dlog *:E

# Check if binary exists
sdb shell "ls -la /opt/usr/apps/org.xbmc.kodi/bin/"
```

**Solutions:**
1. Verify all dependencies are included in TPK
2. Check file permissions
3. Verify Tizen API initialization
4. Check for missing libraries: `sdb shell "ldd /opt/usr/apps/org.xbmc.kodi/bin/kodi-tizen"`

#### Issue: Video Playback Fails

**Symptoms:**
- Black screen during playback
- Audio but no video
- Immediate playback failure

**Diagnosis:**
```bash
# Check codec support
sdb shell "gst-inspect-1.0 | grep video"

# View playback logs
./tools/tizen/logs.sh -g "player" -f

# Test with known-good file
```

**Solutions:**
1. Verify codec is supported on device
2. Check video file format and codec
3. Try different video file
4. Check AVPlay initialization
5. Verify display configuration

#### Issue: Remote Control Not Working

**Symptoms:**
- No response to button presses
- Some buttons work, others don't
- Delayed response

**Diagnosis:**
```bash
# Check input logs
./tools/tizen/logs.sh -g "input" -f

# Verify Wayland connection
sdb shell "ps aux | grep wayland"
```

**Solutions:**
1. Verify remote is paired with TV
2. Check key mapping in CSeatTizen
3. Verify Wayland input event handling
4. Test with different remote
5. Restart application

#### Issue: Settings Not Persisting

**Symptoms:**
- Settings reset after restart
- Configuration changes lost
- Library data disappears

**Diagnosis:**
```bash
# Check data directory
sdb shell "ls -la /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/"

# Verify settings file
sdb shell "cat /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/.kodi/userdata/guisettings.xml"

# Check storage space
sdb shell "df -h"
```

**Solutions:**
1. Verify data directory permissions
2. Check available storage space
3. Verify app_get_data_path() returns correct path
4. Check for write errors in logs
5. Test with fresh installation

#### Issue: Memory Leaks

**Symptoms:**
- Increasing memory usage over time
- Application becomes slow
- Eventually crashes with OOM

**Diagnosis:**
```bash
# Monitor memory usage
sdb shell "cat /proc/$(pidof kodi-tizen)/status | grep VmRSS"

# Check for memory warnings in logs
./tools/tizen/logs.sh -g "memory" -f
```

**Solutions:**
1. Profile with Valgrind (if available)
2. Review resource cleanup code
3. Check for circular references
4. Implement aggressive cache cleanup
5. Use smart pointers

#### Issue: Network Streaming Buffering

**Symptoms:**
- Frequent buffering during playback
- Stuttering video
- Playback stops and starts

**Diagnosis:**
```bash
# Test network speed
sdb shell "ping -c 10 <server>"

# Check network logs
./tools/tizen/logs.sh -g "network" -f

# Monitor bandwidth
```

**Solutions:**
1. Use wired Ethernet instead of Wi-Fi
2. Reduce video quality/bitrate
3. Adjust cache settings
4. Check server performance
5. Test with local files to isolate issue

## Best Practices

### Code Organization

1. **Separate Platform-Specific Code**
   - Keep Tizen-specific code in platform directory
   - Use `#ifdef TARGET_TIZEN` for conditional compilation
   - Implement platform interfaces, don't modify core code

2. **Error Handling**
   - Always check return codes from Tizen APIs
   - Log errors with context
   - Provide fallback behavior
   - Don't crash on API failures

3. **Resource Management**
   - Use RAII for resource cleanup
   - Release resources in destructors
   - Handle low memory conditions
   - Clean up on application pause/terminate

### Testing Strategy

1. **Unit Testing**
   - Test platform-specific code in isolation
   - Mock Tizen APIs for testing
   - Test error conditions
   - Verify resource cleanup

2. **Integration Testing**
   - Test on Tizen emulator
   - Test on physical devices
   - Test different TV models
   - Test different Tizen versions

3. **Performance Testing**
   - Profile on target hardware
   - Monitor memory usage
   - Measure frame rates
   - Test with large libraries

4. **Compatibility Testing**
   - Test on multiple TV models
   - Test different screen resolutions
   - Test HDR and SDR content
   - Test various media formats

### Deployment Best Practices

1. **Package Optimization**
   - Strip debug symbols for release builds
   - Compress resources
   - Remove unused dependencies
   - Minimize package size

2. **Version Management**
   - Use semantic versioning
   - Document breaking changes
   - Provide migration guides
   - Test upgrade paths

3. **User Communication**
   - Provide clear error messages
   - Document known issues
   - Offer troubleshooting guidance
   - Collect user feedback

## Testing Recommendations

### Test Matrix

| Test Category | Emulator | Physical Device | Required |
|--------------|----------|-----------------|----------|
| Build verification | ✓ | ✓ | Yes |
| Unit tests | ✓ | ✓ | Yes |
| Integration tests | ✓ | ✓ | Yes |
| UI navigation | ✓ | ✓ | Yes |
| Video playback | ✗ | ✓ | Yes |
| Audio playback | ✗ | ✓ | Yes |
| HDR content | ✗ | ✓ | Yes |
| Remote control | ✗ | ✓ | Yes |
| Network streaming | ✓ | ✓ | Yes |
| Performance | ✗ | ✓ | Yes |
| Long-running stability | ✗ | ✓ | Yes |

### Recommended Test Devices

**Minimum Test Coverage:**
- 1x 2020 model (Tizen 5.5)
- 1x 2022+ model (Tizen 6.5+)
- 1x 4K model
- 1x HDR-capable model

**Comprehensive Test Coverage:**
- Multiple models from each year (2020-2024)
- Various screen sizes (43", 55", 65", 75")
- Different processor generations
- HDR10, HDR10+, Dolby Vision models

### Test Scenarios

1. **Basic Functionality**
   - Application launch and exit
   - UI navigation with remote
   - Settings configuration
   - Library scanning

2. **Media Playback**
   - Local file playback (various formats)
   - Network streaming (HTTP, SMB, NFS)
   - Seek operations
   - Audio track selection
   - Subtitle display

3. **Advanced Features**
   - HDR content playback
   - 4K/8K video playback
   - Multi-channel audio
   - Addon installation and usage

4. **Stability**
   - Long-running playback (24+ hours)
   - Repeated pause/resume cycles
   - Memory leak detection
   - Crash recovery

5. **Edge Cases**
   - Low memory conditions
   - Low storage conditions
   - Network interruptions
   - Corrupted media files
   - Invalid user input

## Additional Resources

### Documentation
- [Tizen Developer Documentation](https://developer.tizen.org/)
- [Samsung Smart TV Developer Portal](https://developer.samsung.com/smarttv)
- [Tizen Native API Reference](https://developer.tizen.org/development/api-references/native-application)
- [Kodi Development Documentation](https://kodi.wiki/view/Development)

### Tools
- [Tizen Studio](https://developer.tizen.org/development/tizen-studio/download)
- [SDB Documentation](https://developer.tizen.org/development/tizen-studio/native-tools/smart-development-bridge)
- [Tizen Emulator](https://developer.tizen.org/development/tizen-studio/native-tools/emulator)

### Community
- [Kodi Forum](https://forum.kodi.tv/)
- [Tizen Developer Forum](https://developer.tizen.org/forums)
- [Samsung Developer Forum](https://forum.developer.samsung.com/)

### Related Guides
- [README.Tizen.md](README.Tizen.md) - Complete build guide
- [Developer Mode Guide](../tools/tizen/DEVELOPER_MODE_GUIDE.md)
- [SDB Deployment Guide](../tools/tizen/SDB_DEPLOYMENT_GUIDE.md)
- [Emulator Guide](../tools/tizen/EMULATOR_GUIDE.md)
- [Crash Logging Guide](../tools/tizen/CRASH_LOGGING_GUIDE.md)
- [Data Management Guide](../xbmc/platform/linux/TIZEN_DATA_MANAGEMENT.md)

