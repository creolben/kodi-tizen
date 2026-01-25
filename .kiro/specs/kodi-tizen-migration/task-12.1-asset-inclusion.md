# Task 12.1: Configure Asset Inclusion in Build System

## Implementation Summary

This task configures the Kodi build system to properly include all UI assets (skins, icons, fonts, images) in the Tizen TPK package.

## Changes Made

### 1. Created Tizen Install Script (`cmake/scripts/tizen/Install.cmake`)

Created a new CMake install script specifically for Tizen that:
- Defines `APP_INSTALL_DIRS` to specify which directories should be packaged
- Documents the packaging workflow
- Provides status messages for developers

The script ensures the following directories are marked for installation:
- `addons/` - System addons and skins (including skin.estuary)
- `media/` - Icons, fonts, images, splash screens
- `system/` - Keymaps, settings, shaders, libraries
- `userdata/` - User data templates
- `sounds/` - UI sound effects

### 2. Updated Linux Install Script (`cmake/scripts/linux/Install.cmake`)

Added conditional include for Tizen install script:
```cmake
if("tizen" IN_LIST CORE_PLATFORM_NAME_LC OR TARGET_TIZEN)
  include(${CMAKE_SOURCE_DIR}/cmake/scripts/tizen/Install.cmake)
endif()
```

### 3. Updated Tizen Platform Configuration (`cmake/platform/linux/tizen.cmake`)

Added "tizen" to `CORE_PLATFORM_NAME_LC` list to enable platform-specific install scripts:
```cmake
list(APPEND CORE_PLATFORM_NAME_LC wayland tizen)
```

### 4. Updated Packaging Script (`tools/tizen/packaging/package.sh`)

Modified `copy_resources()` function to:
- Copy assets from the **build tree** instead of source tree
- This ensures processed assets (like packed skins) are included
- Added detailed logging for each asset category
- Added validation to ensure critical assets are present
- Exits with error if critical assets are missing

Key improvements:
- Copies from `$BUILD_DIR` instead of `$PROJECT_ROOT`
- Includes all asset categories: media, addons, system, userdata, sounds
- Validates that critical assets (media, addons, system) are present
- Provides clear error messages if assets are missing

## How It Works

### Build System Flow

1. **Asset Collection**: CMake reads asset lists from `cmake/installdata/common/*.txt` and `cmake/installdata/linux/*.txt`

2. **Asset Processing**: 
   - Files are copied to build directory via `copy_files_from_filelist_to_buildtree()`
   - Skins are processed and packed via `copy_skin_to_buildtree()` and TexturePacker
   - System addons are generated via `gen_system_addons` target

3. **Build Tree Structure**:
   ```
   build/
   ├── addons/
   │   ├── skin.estuary/      # Processed skin with .xbt files
   │   ├── metadata.*/         # Metadata scrapers
   │   ├── resource.*/         # Resource addons
   │   └── ...
   ├── media/
   │   ├── Fonts/
   │   ├── icon*.png
   │   └── ...
   ├── system/
   │   ├── keymaps/
   │   ├── settings/
   │   ├── shaders/
   │   └── ...
   ├── userdata/
   └── sounds/
   ```

4. **TPK Packaging**: The `package.sh` script copies all assets from the build tree to the TPK package structure:
   ```
   package/
   ├── bin/
   │   └── kodi-tizen
   ├── lib/
   │   └── *.so
   └── res/
       ├── addons/
       ├── media/
       ├── system/
       ├── userdata/
       └── sounds/
   ```

### Asset Categories

#### Media Files (`media/`)
- Application icons (16x16 to 256x256)
- Fonts (Arial, DejaVu, etc.)
- Splash screens
- Banner images
- QR codes

#### Addons (`addons/`)
- **Skins**: skin.estuary (default skin) with processed .xbt texture files
- **Metadata scrapers**: themoviedb.org, musicbrainz, etc.
- **Resource addons**: language packs, weather icons, UI sounds
- **System addons**: audio encoders, game controllers, etc.

#### System Files (`system/`)
- **Keymaps**: Keyboard and remote control mappings
- **Settings**: Default settings schemas
- **Shaders**: OpenGL ES shaders for rendering
- **Libraries**: Platform-specific libraries
- **Certificates**: SSL certificates

#### Userdata (`userdata/`)
- Default user data templates
- RSS feeds configuration
- Mode lines templates

#### Sounds (`sounds/`)
- UI sound effects (if present)

## Validation

The packaging script validates that critical assets are present:
- `media/` - Required for UI rendering
- `addons/` - Required for skins and functionality
- `system/` - Required for core functionality

If any critical asset is missing, the packaging script exits with an error.

## Requirements Satisfied

This implementation satisfies **Requirement 13.1**:
> WHEN the application is packaged, THE Tizen_Build_System SHALL include all original Kodi UI assets (skins, icons, fonts, images)

## Testing

To verify asset inclusion:

1. **Build Kodi for Tizen**:
   ```bash
   cd build
   cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/platform/linux/tizen.cmake
   make
   ```

2. **Check build tree assets**:
   ```bash
   ls -la build/addons/skin.estuary/
   ls -la build/media/
   ls -la build/system/
   ```

3. **Create TPK package**:
   ```bash
   make tpk
   ```

4. **Verify TPK contents**:
   ```bash
   unzip -l build/org.xbmc.kodi-*.tpk | grep -E "(media|addons|system)"
   ```

5. **Check for critical assets**:
   ```bash
   unzip -l build/org.xbmc.kodi-*.tpk | grep "skin.estuary"
   unzip -l build/org.xbmc.kodi-*.tpk | grep "Fonts"
   unzip -l build/org.xbmc.kodi-*.tpk | grep "icon"
   ```

## Notes

- The build system automatically handles asset processing (e.g., skin texture packing)
- Assets are copied from the build tree, not the source tree, to ensure processed versions are included
- The packaging script validates critical assets and fails early if they're missing
- Skins are processed by TexturePacker to create .xbt files for efficient loading
- All original Kodi UI assets are preserved without modification (except for optimization)
