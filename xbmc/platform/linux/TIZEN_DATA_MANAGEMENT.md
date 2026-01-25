# Tizen Data Management and Persistence

## Overview

This document describes how Kodi manages user data, settings, and configuration on the Tizen platform, including data preservation during application updates and cleanup options during uninstallation.

## Data Directory Structure

Kodi on Tizen uses the standard Tizen application data directory structure:

### Application Data Path
- **Location**: `/opt/usr/apps/org.xbmc.kodi/data/`
- **Access**: Via `app_get_data_path()` API
- **Purpose**: Stores all user data, settings, and configuration files

### User Data Subdirectories
```
/opt/usr/apps/org.xbmc.kodi/data/
├── .kodi/                          # Main Kodi user data directory
│   ├── userdata/                   # User settings and profiles
│   │   ├── guisettings.xml        # Main settings file
│   │   ├── sources.xml            # Media sources configuration
│   │   ├── favourites.xml         # User favorites
│   │   ├── profiles.xml           # User profiles
│   │   ├── Database/              # Media library databases
│   │   ├── Thumbnails/            # Cached thumbnails
│   │   └── addon_data/            # Addon-specific data
│   ├── addons/                    # Installed addons
│   ├── media/                     # Media files
│   └── temp/                      # Temporary files
```

## Data Persistence During Updates

### Automatic Preservation

Tizen automatically preserves the application data directory during app updates. This means:

1. **Settings Preservation**: All user settings in `guisettings.xml` and other configuration files are retained
2. **Library Preservation**: Media library databases remain intact
3. **Addon Data**: All addon configurations and data are preserved
4. **Thumbnails**: Cached thumbnails are retained (though they may be regenerated if needed)

### Implementation Details

The data preservation is handled by Tizen's application framework:

- **Update Process**: When a TPK package is installed as an update, Tizen:
  1. Extracts the new application binaries to `/opt/usr/apps/org.xbmc.kodi/bin/`
  2. Updates shared resources in `/opt/usr/apps/org.xbmc.kodi/res/`
  3. **Preserves** the data directory `/opt/usr/apps/org.xbmc.kodi/data/`
  4. Updates the manifest and metadata

- **No Manual Intervention Required**: Kodi does not need to implement any special logic for data preservation during updates

### Verification

To verify data persistence across updates:

```cpp
// In CPlatformTizen::InitStageOne()
// The GetHomePath() method uses app_get_data_path()
// which always returns the same path across updates
const auto HOME = GetHomePath();
```

## Data Cleanup Options

### During Uninstallation

Tizen provides two uninstallation modes:

#### 1. Standard Uninstall (Data Preserved)
- **Behavior**: Removes application binaries but preserves user data
- **Use Case**: User wants to reinstall later without losing settings
- **Data Retained**: All files in `/opt/usr/apps/org.xbmc.kodi/data/`

#### 2. Complete Uninstall (Data Removed)
- **Behavior**: Removes both application binaries and user data
- **Use Case**: User wants to completely remove Kodi
- **Data Removed**: Entire `/opt/usr/apps/org.xbmc.kodi/` directory

### User Control

Users can choose the uninstallation mode through:

1. **Samsung TV Settings**:
   - Navigate to: Settings → Apps → Kodi → Uninstall
   - Option: "Delete app data" checkbox

2. **SDB Command Line** (Developer Mode):
   ```bash
   # Standard uninstall (preserve data)
   sdb shell app_launcher -k org.xbmc.kodi
   
   # Complete uninstall (remove data)
   sdb shell app_launcher -k org.xbmc.kodi --remove-data
   ```

### Programmatic Data Cleanup

Kodi can implement optional data cleanup on first run after reinstall:

```cpp
bool CPlatformTizen::IsFirstRunAfterReinstall()
{
  // Check for a marker file that indicates previous installation
  std::string markerFile = GetHomePath() + "/.kodi_installed";
  
  if (!XFILE::CFile::Exists(markerFile))
  {
    // First run - create marker
    XFILE::CFile file;
    file.OpenForWrite(markerFile, true);
    file.Write("1", 1);
    file.Close();
    return true;
  }
  
  return false;
}
```

## Storage Space Management

### Monitoring

Kodi monitors available storage space during initialization:

```cpp
bool CPlatformTizen::CheckStorageSpace()
{
  unsigned long long total = 0;
  unsigned long long available = 0;
  
  if (!GetStorageInfo(total, available))
    return false;
  
  // Warn if less than 100MB available
  const unsigned long long minSpace = 100 * 1024 * 1024;
  
  if (available < minSpace)
  {
    CLog::Log(LOGWARNING, "Low storage space: {} MB available", 
              available / (1024 * 1024));
    return false;
  }
  
  return true;
}
```

### Low Storage Handling

When storage is low, Kodi can:

1. **Display Warning**: Show a notification to the user
2. **Disable Caching**: Reduce or disable thumbnail caching
3. **Clean Temporary Files**: Remove files from the temp directory
4. **Suggest Cleanup**: Prompt user to clean library or remove unused addons

### Cache Management

Kodi should implement cache cleanup when storage is low:

```cpp
void CPlatformTizen::CleanupCacheOnLowStorage()
{
  std::string tempDir = GetHomePath() + "/.kodi/temp/";
  std::string thumbDir = GetHomePath() + "/.kodi/userdata/Thumbnails/";
  
  // Remove temporary files
  XFILE::CDirectory::RemoveRecursive(tempDir);
  XFILE::CDirectory::Create(tempDir);
  
  // Optionally clean old thumbnails
  // (Implementation depends on Kodi's cache management system)
}
```

## Best Practices

### For Developers

1. **Always Use app_get_data_path()**: Never hardcode data paths
2. **Check Storage Before Large Operations**: Verify space before downloading or caching
3. **Implement Graceful Degradation**: Handle low storage conditions gracefully
4. **Log Storage Issues**: Use dlog to report storage problems for debugging

### For Users

1. **Regular Maintenance**: Periodically clean library and remove unused addons
2. **Monitor Storage**: Check available space in TV settings
3. **Backup Important Data**: Export library before major updates (optional)

## Testing Data Persistence

### Manual Testing

1. Install Kodi TPK on Samsung TV
2. Configure settings and add media sources
3. Install a newer version of Kodi TPK
4. Verify all settings and sources are preserved

### Automated Testing

```cpp
TEST_F(TestPlatformTizen, DataPersistenceAcrossUpdates)
{
  CPlatformTizen platform;
  platform.InitStageOne();
  
  // Create test data
  std::string testFile = platform.GetHomePath() + "/test_persistence.txt";
  XFILE::CFile file;
  file.OpenForWrite(testFile, true);
  file.Write("test", 4);
  file.Close();
  
  // Simulate app restart (in real scenario, this would be an update)
  CPlatformTizen platform2;
  platform2.InitStageOne();
  
  // Verify data still exists
  EXPECT_TRUE(XFILE::CFile::Exists(testFile));
  
  // Cleanup
  XFILE::CFile::Delete(testFile);
}
```

## Troubleshooting

### Data Not Persisting

If user data is not persisting across updates:

1. **Check Permissions**: Verify app has write permissions to data directory
2. **Check Manifest**: Ensure `tizen-manifest.xml` declares correct privileges
3. **Check Logs**: Review dlog output for permission errors
4. **Verify Path**: Ensure using `app_get_data_path()` not hardcoded paths

### Storage Full Errors

If encountering storage full errors:

1. **Check Available Space**: Use `storage_get_internal_memory_size()`
2. **Clean Temporary Files**: Remove files from temp directory
3. **Reduce Cache Size**: Adjust thumbnail cache settings
4. **Notify User**: Display clear error message with cleanup suggestions

## References

- Tizen Application Data Management: https://docs.tizen.org/application/native/guides/app-management/app-data/
- Tizen Storage API: https://docs.tizen.org/application/native/api/mobile/latest/group__CAPI__SYSTEM__STORAGE__MODULE.html
- Kodi Settings System: xbmc/settings/Settings.h
