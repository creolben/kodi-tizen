# Implementation Plan: Kodi Tizen Migration

## Overview

This implementation plan breaks down the Kodi Tizen migration into discrete, manageable tasks. The approach follows the established webOS pattern, adapting it for Tizen's specific APIs and requirements. Tasks are organized to enable incremental progress with early validation through testing.

The implementation will proceed in phases:
1. Build system and toolchain setup
2. Platform abstraction layer
3. Windowing system integration
4. Media pipeline implementation
5. Input handling
6. Packaging and deployment
7. Testing and validation

## Tasks

- [x] 1. Set up Tizen build system and toolchain configuration
  - [x] 1.1 Create cmake/platform/linux/tizen.cmake configuration file
    - Define TARGET_TIZEN preprocessor macro
    - Configure Tizen-specific dependencies (dlog, capi-appfw-application, capi-media-player, EGL, GLESv2)
    - Exclude incompatible dependencies (CEC, PulseAudio)
    - Set toolchain paths for Tizen SDK
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_
  
  - [x] 1.2 Configure Kodi's unified depends system for Tizen
    - Create configure script for Tizen cross-compilation
    - Set up host triplet (arm-tizen-linux-gnueabi or x86-tizen-linux-gnu)
    - Configure toolchain paths and sysroot
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 8.1_
  
  - [ ]* 1.3 Write unit tests for build system configuration
    - Test TARGET_TIZEN macro definition
    - Test Tizen library linkage
    - Test dependency exclusion
    - _Requirements: 1.1, 1.3, 1.4_

- [x] 2. Implement Tizen platform abstraction layer
  - [x] 2.1 Create CPlatformTizen class implementation
    - Implement xbmc/platform/linux/PlatformTizen.h header
    - Implement xbmc/platform/linux/PlatformTizen.cpp
    - Inherit from CPlatformLinux
    - Override InitStageOne, InitStageTwo, InitStageThree
    - Implement GetHomePath() using app_get_data_path()
    - Implement IsConfigureAddonsAtStartupEnabled()
    - _Requirements: 2.1, 2.5, 2.6_
  
  - [x] 2.2 Implement Tizen application lifecycle handling
    - Register app lifecycle callbacks using app_event_set_cb()
    - Implement OnAppPause() handler
    - Implement OnAppResume() handler
    - Implement OnAppTerminate() handler
    - Store lifecycle handler references
    - _Requirements: 2.2, 2.3, 11.1, 11.2, 11.3, 11.4, 11.5_
  
  - [x] 2.3 Implement system information queries
    - Implement CPU info using system_info APIs
    - Implement GPU info using system_info APIs
    - Implement memory info using system_info APIs
    - _Requirements: 2.4_
  
  - [x] 2.4 Integrate Tizen logging with dlog
    - Implement logging wrapper using dlog_print()
    - Map Kodi log levels to dlog levels (ERROR, WARN, INFO, DEBUG)
    - _Requirements: 9.3_
  
  - [x] 2.5 Implement power management integration
    - Override RegisterPowerManagement()
    - Integrate with Tizen power management APIs
    - _Requirements: 2.2, 11.6_
  
  - [ ]* 2.6 Write property test for application lifecycle state transitions
    - **Property 1: Application Lifecycle State Transitions**
    - Generate random sequences of lifecycle events
    - Verify correct handling of pause/resume/background/foreground/terminate
    - Verify resource management and state consistency
    - **Validates: Requirements 2.3, 11.1, 11.2, 11.3, 11.4, 11.5**
  
  - [ ]* 2.7 Write unit tests for platform abstraction layer
    - Test InitStageOne/Two/Three success
    - Test GetHomePath returns Tizen-compliant path
    - Test power management registration
    - Test system info queries return valid data
    - _Requirements: 2.1, 2.2, 2.4, 2.5_

- [x] 3. Checkpoint - Verify platform layer builds and initializes
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Implement Tizen windowing system
  - [x] 4.1 Create CWinSystemWaylandTizen class
    - Implement xbmc/windowing/wayland/WinSystemWaylandTizen.h header
    - Implement xbmc/windowing/wayland/WinSystemWaylandTizen.cpp
    - Inherit from CWinSystemWayland
    - Override InitWindowSystem() and DestroyWindowSystem()
    - _Requirements: 3.1_
  
  - [x] 4.2 Implement Wayland connection and surface creation
    - Initialize Wayland display connection
    - Create Wayland compositor and surface
    - Implement CreateShellSurface() for Tizen
    - Implement CreateNewWindow() with EGL surface creation
    - _Requirements: 3.1, 3.2, 3.7_
  
  - [x] 4.3 Implement display configuration and resolution handling
    - Implement UpdateResolutions() to query Tizen display modes
    - Implement OnConfigure() to handle resolution changes
    - Implement fullscreen mode configuration
    - _Requirements: 3.3, 3.4, 3.6_
  
  - [x] 4.4 Implement HDR capability detection
    - Implement IsHDRDisplay() using Tizen display APIs
    - Implement GetGuiSdrPeakLuminance()
    - Query and cache HDR capabilities
    - _Requirements: 3.5_
  
  - [x] 4.5 Implement Tizen screen saver integration
    - Create xbmc/windowing/wayland/OSScreenSaverTizen.h/cpp
    - Implement screen saver inhibition using Tizen APIs
    - Override GetOSScreenSaverImpl()
    - _Requirements: 11.6_
  
  - [x] 4.6 Implement cursor handling for Tizen
    - Override HasCursor() to return false (TV has no cursor)
    - _Requirements: 3.1_
  
  - [ ]* 4.7 Write property test for display resolution adaptation
    - **Property 2: Display Resolution Adaptation**
    - Generate random resolution change events
    - Verify surface dimensions update correctly
    - Verify aspect ratio and rendering quality maintained
    - **Validates: Requirements 3.3**
  
  - [ ]* 4.8 Write unit tests for windowing system
    - Test Wayland connection initialization
    - Test EGL surface creation
    - Test HDR capability queries
    - Test fullscreen mode configuration
    - _Requirements: 3.1, 3.2, 3.4, 3.5, 3.7_

- [x] 5. Checkpoint - Verify windowing system displays correctly
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Implement Tizen media pipeline
  - [x] 6.1 Create CMediaPipelineTizen class
    - Implement xbmc/cores/VideoPlayer/MediaPipelineTizen.h header
    - Implement xbmc/cores/VideoPlayer/MediaPipelineTizen.cpp
    - Define player_h member for AVPlay handle
    - Implement Initialize() and Finalize() methods
    - _Requirements: 4.1_
  
  - [x] 6.2 Implement media player lifecycle
    - Implement Open() using player_set_uri() and player_prepare()
    - Implement Close() to release player resources
    - _Requirements: 4.1_
  
  - [x] 6.3 Implement playback control
    - Implement Play() using player_start()
    - Implement Pause() using player_pause()
    - Implement Stop() using player_stop()
    - Implement Seek() using player_set_play_position()
    - Implement GetCurrentTime() and GetDuration()
    - _Requirements: 4.1, 4.3_
  
  - [x] 6.4 Implement AVPlay callbacks
    - Implement OnPlayerStateChanged() callback
    - Implement OnPlayerError() callback
    - Implement OnBufferingProgress() callback
    - Register callbacks with player_set_*_cb() functions
    - _Requirements: 4.4, 4.8_
  
  - [x] 6.5 Implement audio and video configuration
    - Implement SetVideoRect() using player_set_display()
    - Implement SetAudioStream() for audio track selection
    - Implement audio routing through Tizen audio subsystem
    - _Requirements: 4.2_
  
  - [x] 6.6 Implement codec capability reporting
    - Implement GetSupportedCodecs() using Tizen media capability APIs
    - Implement SupportsHDR() for HDR capability detection
    - Configure AVPlay for HDR output when supported
    - _Requirements: 4.5, 4.6_
  
  - [x] 6.7 Implement subtitle rendering coordination
    - Implement SetSubtitleStream() for subtitle track selection
    - Coordinate with Kodi's subtitle renderer
    - _Requirements: 4.7_
  
  - [ ]* 6.8 Write property test for media seek accuracy
    - **Property 4: Media Seek Accuracy**
    - Generate random seek positions within media duration
    - Verify seek completes within 1 second of requested position
    - Verify playback resumes from seek position
    - **Validates: Requirements 4.3**
  
  - [ ]* 6.9 Write property test for playback state synchronization
    - **Property 5: Playback State Synchronization**
    - Generate random playback state transitions
    - Verify state synchronizes with Kodi player interface within 100ms
    - Verify UI and backend state consistency
    - **Validates: Requirements 4.4**
  
  - [ ]* 6.10 Write property test for error propagation
    - **Property 6: Error Propagation Completeness**
    - Generate various error conditions (codec unsupported, network failure, file not found)
    - Verify errors propagate to Kodi error handling system
    - Verify appropriate error codes and messages
    - **Validates: Requirements 4.8**
  
  - [ ]* 6.11 Write unit tests for media pipeline
    - Test player initialization
    - Test supported codec reporting
    - Test playback control (play/pause/stop)
    - Test error callback invocation
    - _Requirements: 4.1, 4.2, 4.5, 4.8_

- [x] 7. Checkpoint - Verify media playback works correctly
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Implement Tizen input handling
  - [x] 8.1 Create CSeatTizen class for remote control input
    - Implement custom CSeat subclass in WinSystemWaylandTizen.cpp
    - Override HandleKeyPress() and HandleKeyRelease()
    - Implement in CreateSeat() override
    - _Requirements: 5.1_
  
  - [x] 8.2 Implement remote button key mapping
    - Define Tizen remote key code constants
    - Implement MapTizenKeyToKodiEvent() function
    - Map directional buttons (up/down/left/right) to Kodi navigation
    - Map select/OK button to Kodi select action
    - Map back button to previous menu
    - Map home button to home screen
    - _Requirements: 5.2, 5.3, 5.5, 5.6_
  
  - [x] 8.3 Implement playback control button mapping
    - Map play/pause button to toggle playback
    - Map stop button to stop playback
    - Map rewind/fast forward to seek actions
    - _Requirements: 5.4_
  
  - [x] 8.4 Implement volume control integration
    - Implement HandleVolumeKey() function
    - Map volume up/down buttons to Tizen volume APIs
    - Use sound_manager APIs for system volume control
    - _Requirements: 5.7_
  
  - [x] 8.5 Implement unknown key handling
    - Log unknown key codes for debugging
    - Return no-op event for unmapped keys
    - _Requirements: 5.1_
  
  - [ ]* 8.6 Write property test for remote control button mapping
    - **Property 3: Remote Control Button Mapping Completeness**
    - Generate random button press events for all supported buttons
    - Verify each button maps to correct Kodi action
    - Verify action executes correctly
    - **Validates: Requirements 5.2, 5.4**
  
  - [ ]* 8.7 Write unit tests for input handling
    - Test directional key mapping
    - Test playback control key mapping
    - Test unknown key handling (should not crash)
    - Test volume key handling
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.7_

- [x] 9. Implement configuration and settings persistence
  - [x] 9.1 Implement settings storage using Tizen data directory
    - Verify settings save to persistent storage using app_get_data_path()
    - Verify settings load on application start
    - Test settings persistence across app restarts
    - _Requirements: 10.1, 10.2_
  
  - [x] 9.2 Implement storage space monitoring
    - Implement storage space queries using storage_get_internal_memory_size()
    - Implement low storage warning
    - _Requirements: 10.4_
  
  - [x] 9.3 Implement data preservation during updates
    - Ensure user data directory is preserved during app updates
    - Document data cleanup options for uninstall
    - _Requirements: 10.3, 10.5_
  
  - [ ]* 9.4 Write property test for settings persistence
    - **Property 7: Settings Persistence Round-Trip**
    - Generate random setting key-value pairs
    - Save settings, simulate restart, load settings
    - Verify loaded values equal saved values
    - **Validates: Requirements 10.2**
  
  - [ ]* 9.5 Write unit tests for settings persistence
    - Test settings load from Tizen data directory
    - Test settings save to persistent storage
    - Test storage space queries
    - _Requirements: 10.1, 10.2, 10.4_

- [x] 10. Implement network connectivity support
  - [x] 10.1 Implement network status monitoring
    - Use connection_create() to monitor network status
    - Implement network change detection and reporting
    - _Requirements: 12.1_
  
  - [x] 10.2 Verify POSIX networking compatibility
    - Ensure standard socket APIs work on Tizen
    - Test DNS resolution using Tizen network services
    - _Requirements: 12.2, 12.3_
  
  - [x] 10.3 Implement Wi-Fi information queries
    - Use wifi_manager APIs for connection status
    - Provide Wi-Fi information to Kodi
    - _Requirements: 12.5_
  
  - [ ]* 10.4 Write unit tests for network connectivity
    - Test network status change detection
    - Test DNS resolution
    - Test Wi-Fi status queries
    - _Requirements: 12.1, 12.3, 12.5_

- [x] 11. Implement packaging and deployment system
  - [x] 11.1 Create Tizen manifest template
    - Create tools/tizen/packaging/tizen-manifest.xml.in
    - Define application metadata (package ID, version, author)
    - Declare required privileges (internet, network, media, display, storage)
    - Specify TV profile and features
    - _Requirements: 6.1, 12.4_
  
  - [x] 11.2 Create TPK packaging script
    - Create tools/tizen/packaging/package.sh
    - Implement binary collection and directory structure creation
    - Implement resource file inclusion (UI assets, skins, fonts)
    - Implement shared library dependency inclusion
    - Generate tizen-manifest.xml from template
    - _Requirements: 6.2, 6.6, 13.1_
  
  - [x] 11.3 Implement TPK signing
    - Integrate Tizen certificate signing into package script
    - Use tizen-studio CLI tools for signing
    - Validate certificate before signing
    - _Requirements: 6.3_
  
  - [x] 11.4 Create application icon assets
    - Prepare Kodi logo in required Tizen icon sizes
    - Include icons in TPK package
    - Reference icons in manifest
    - _Requirements: 6.5, 13.6_
  
  - [x] 11.5 Implement CMake packaging target
    - Add 'tpk' target to CMakeLists.txt
    - Invoke packaging script from CMake
    - _Requirements: 6.2_
  
  - [ ]* 11.6 Write unit tests for packaging
    - Test manifest generation with correct metadata
    - Test TPK file creation
    - Test icon inclusion and sizing
    - Test dependency inclusion
    - _Requirements: 6.1, 6.2, 6.5, 6.6_

- [x] 12. Implement UI asset preservation
  - [x] 12.1 Configure asset inclusion in build system
    - Ensure all Kodi UI assets are included in build
    - Include skins, icons, fonts, images from media/ directory
    - Configure installation paths for assets
    - _Requirements: 13.1_
  
  - [x] 12.2 Verify skin format compatibility
    - Test loading of various Kodi skin formats
    - Ensure skin XML parsing works correctly
    - Verify skin resource loading (images, fonts)
    - _Requirements: 13.3_
  
  - [x] 12.3 Verify font rendering
    - Ensure original Kodi font files are used
    - Test font rendering with various character sets
    - _Requirements: 13.4_
  
  - [ ]* 12.4 Write property test for skin format compatibility
    - **Property 8: Skin Format Compatibility**
    - Generate or use various valid Kodi skin packages
    - Verify each skin loads without errors
    - Verify no missing elements in rendered skin
    - **Validates: Requirements 13.3**
  
  - [ ]* 12.5 Write unit tests for asset preservation
    - Test all required assets are included in package
    - Test font file loading
    - Test icon file usage
    - _Requirements: 13.1, 13.4, 13.6_

- [x] 13. Implement debugging and development support
  - [x] 13.1 Configure SDB deployment support
    - Document SDB connection setup
    - Create deployment scripts using SDB
    - Implement log access via SDB
    - _Requirements: 9.2_
  
  - [x] 13.2 Implement developer mode support
    - Document developer mode activation on Samsung TVs
    - Support unsigned TPK installation in dev mode
    - _Requirements: 9.1_
  
  - [x] 13.3 Configure emulator compatibility
    - Ensure binaries work on Tizen emulator
    - Document emulator setup and usage
    - _Requirements: 9.4_
  
  - [x] 13.4 Implement crash logging
    - Configure crash log generation
    - Ensure crash logs are accessible via SDB
    - _Requirements: 9.5_
  
  - [ ]* 13.5 Write unit tests for debugging support
    - Test dlog logging output
    - Test crash log generation
    - _Requirements: 9.3, 9.5_

- [x] 14. Create documentation
  - [x] 14.1 Create README.Tizen.md build guide
    - Document prerequisites (Tizen Studio, SDK, certificates)
    - Document toolchain setup
    - Document dependency building
    - Document Kodi compilation steps
    - Document TPK packaging and signing
    - Document installation via SDB
    - Document debugging procedures
    - Follow format of README.webOS.md
    - _Requirements: All_
  
  - [x] 14.2 Document platform-specific considerations
    - Document Tizen API usage
    - Document known limitations
    - Document troubleshooting steps
    - _Requirements: All_

- [x] 15. Final integration and testing
  - [x] 15.1 Build complete Kodi for Tizen
    - Run full build with all components
    - Verify no compilation errors
    - Verify all dependencies are satisfied
    - _Requirements: All_
  
  - [x] 15.2 Create and sign TPK package
    - Generate TPK using packaging script
    - Sign with Tizen certificate
    - Verify package structure
    - _Requirements: 6.1, 6.2, 6.3_
  
  - [x] 15.3 Deploy to Tizen device
    - Install TPK on Samsung TV
    - Verify installation succeeds
    - Verify application launches
    - _Requirements: 6.4_
    - _Requirements: 6.4_
  
  - [ ]* 15.4 Run integration tests
    - Run end-to-end playback test
    - Test UI navigation with remote
    - Test settings persistence across restarts
    - Test network streaming
    - _Requirements: All_
  
  - [ ]* 15.5 Run all property-based tests
    - Execute all 8 property tests with 100 iterations each
    - Verify all properties pass
    - _Requirements: All correctness properties_
  
  - [ ]* 15.6 Perform manual testing on device
    - Test video playback (various codecs and resolutions)
    - Test audio playback
    - Test HDR content
    - Test remote control responsiveness
    - Test UI appearance and layout
    - Test long-running stability
    - _Requirements: All_

- [x] 16. Final checkpoint - Complete migration verification
  - Ensure all tests pass, verify Kodi runs correctly on Samsung TV, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties (8 properties total)
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end functionality
- Manual testing on physical devices is essential for final validation
- The webOS implementation serves as a reference throughout development
