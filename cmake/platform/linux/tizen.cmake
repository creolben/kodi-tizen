# Tizen platform configuration for Kodi
# This configuration enables building Kodi for Samsung Tizen smart TVs

# Include base Wayland configuration as Tizen uses Wayland for windowing
include(${CMAKE_SOURCE_DIR}/cmake/platform/${CORE_SYSTEM_NAME}/wayland.cmake)

# Add wayland as platform, as we require it.
# Saves reworking other assumptions for linux windowing as the platform name.
list(APPEND CORE_PLATFORM_NAME_LC wayland)

# Tizen-specific required dependencies
list(APPEND PLATFORM_REQUIRED_DEPS
  WaylandProtocols
  dlog                        # Tizen logging system
  capi-appfw-application>=0.1 # Tizen application framework
  capi-media-player>=0.1      # Tizen media player (AVPlay)
  capi-system-info>=0.1       # Tizen system information APIs
  EGL                         # EGL for OpenGL ES context
  GLESv2                      # OpenGL ES 2.0 for rendering
)

# Exclude incompatible dependencies
# CEC: Consumer Electronics Control not available on Tizen
# PulseAudio: Tizen uses its own audio subsystem
set(PLATFORM_OPTIONAL_DEPS_EXCLUDE CEC PulseAudio)

# Disable PulseAudio explicitly
set(ENABLE_PULSEAUDIO OFF CACHE BOOL "" FORCE)

# Define TARGET_TIZEN preprocessor macro for platform detection
list(APPEND ARCH_DEFINES -DTARGET_TIZEN)

# Set TARGET_TIZEN flag for CMake conditionals
set(TARGET_TIZEN TRUE)

# Configure toolchain paths for Tizen SDK
# TIZEN_SDK, TIZEN_VERSION, and TIZEN_ROOTSTRAP should be set by the toolchain file
if(DEFINED TIZEN_SDK AND DEFINED TIZEN_VERSION AND DEFINED TIZEN_ROOTSTRAP)
  set(PREFER_TOOLCHAIN_PATH ${TIZEN_SDK}/platforms/tizen-${TIZEN_VERSION}/mobile/rootstraps/${TIZEN_ROOTSTRAP})
elseif(DEFINED TOOLCHAIN AND DEFINED HOST)
  # Fallback to generic toolchain path if Tizen-specific variables not set
  set(PREFER_TOOLCHAIN_PATH ${TOOLCHAIN}/${HOST}/sysroot)
endif()
