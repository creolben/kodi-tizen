# Tizen TPK packaging configuration
# This script configures the installation of Kodi assets for Tizen packaging

# Set application directories that should be included in the TPK
# These directories are populated by the build system from cmake/installdata/*.txt files
set(APP_INSTALL_DIRS ${CMAKE_BINARY_DIR}/addons
                     ${CMAKE_BINARY_DIR}/media
                     ${CMAKE_BINARY_DIR}/system
                     ${CMAKE_BINARY_DIR}/userdata
                     ${CMAKE_BINARY_DIR}/sounds)

# Note: The actual TPK packaging is handled by tools/tizen/packaging/package.sh
# which reads from the build directory. This script ensures the build system
# properly populates the build directory with all required assets.

# The packaging script will:
# 1. Copy the Kodi binary from BUILD_DIR/kodi.bin to package/bin/kodi-tizen
# 2. Copy shared libraries from BUILD_DIR/lib to package/lib/
# 3. Copy UI assets from BUILD_DIR/{addons,media,system,userdata,sounds} to package/res/
# 4. Generate tizen-manifest.xml from template
# 5. Create and optionally sign the TPK file

message(STATUS "Tizen packaging configured:")
message(STATUS "  - Assets will be packaged from: ${CMAKE_BINARY_DIR}")
message(STATUS "  - Run 'make tpk' to create TPK package")
message(STATUS "  - Run 'make sign-tpk' to sign existing TPK")
