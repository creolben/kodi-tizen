# Tizen platform configuration for Kodi
# This configuration enables building Kodi for Samsung Tizen smart TVs

# Include base Wayland configuration as Tizen uses Wayland for windowing
include(${CMAKE_SOURCE_DIR}/cmake/platform/${CORE_SYSTEM_NAME}/wayland.cmake)

# Add wayland and tizen as platforms
# Saves reworking other assumptions for linux windowing as the platform name.
list(APPEND CORE_PLATFORM_NAME_LC wayland tizen)

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

# Tizen TPK packaging target
# This target creates a Tizen Package (TPK) file for installation on Samsung TVs
if(CMAKE_GENERATOR STREQUAL "Unix Makefiles")
  # Get application version from version.txt
  file(STRINGS ${CMAKE_SOURCE_DIR}/version.txt APP_VERSION)
  
  # Set packaging script path
  set(TIZEN_PACKAGE_SCRIPT ${CMAKE_SOURCE_DIR}/tools/tizen/packaging/package.sh)
  
  # Add custom target for TPK packaging
  add_custom_target(tpk
    COMMAND ${CMAKE_COMMAND} -E env
            BUILD_DIR=${CMAKE_BINARY_DIR}
            PACKAGE_DIR=${CMAKE_BINARY_DIR}/package
            OUTPUT_DIR=${CMAKE_BINARY_DIR}
            APP_VERSION=${APP_VERSION}
            TIZEN_SDK=$ENV{TIZEN_SDK}
            TIZEN_SECURITY_PROFILE=$ENV{TIZEN_SECURITY_PROFILE}
            ${TIZEN_PACKAGE_SCRIPT}
    DEPENDS ${APP_NAME_LC}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Creating Tizen TPK package..."
    VERBATIM
  )
  
  # Add custom target for TPK signing (separate from packaging)
  add_custom_target(sign-tpk
    COMMAND ${CMAKE_SOURCE_DIR}/tools/tizen/packaging/sign.sh
            ${CMAKE_BINARY_DIR}/org.xbmc.kodi-${APP_VERSION}.tpk
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Signing Tizen TPK package..."
    VERBATIM
  )
  
  message(STATUS "Tizen TPK packaging targets enabled:")
  message(STATUS "  - Run 'make tpk' to create TPK package")
  message(STATUS "  - Run 'make sign-tpk' to sign existing TPK")
  message(STATUS "  - Set TIZEN_SECURITY_PROFILE environment variable for automatic signing")
endif()
