# Tizen Logging Integration Implementation

## Overview

This document describes the implementation of Tizen logging integration with dlog for the Kodi Tizen migration project.

## Implementation Details

### Files Created

1. **xbmc/platform/linux/utils/DlogSink.h**
   - Custom spdlog sink that outputs to Tizen's dlog system
   - Implements template class `dlog_sink<Mutex>` inheriting from `spdlog::sinks::base_sink<Mutex>`
   - Maps spdlog log levels to dlog priorities
   - Provides both single-threaded (`dlog_sink_st`) and multi-threaded (`dlog_sink_mt`) variants

2. **xbmc/platform/linux/utils/TizenInterfaceForCLog.h**
   - Header file for Tizen-specific logging interface
   - Declares `CTizenInterfaceForCLog` class inheriting from `CPosixInterfaceForCLog`
   - Overrides `AddSinks()` method to add dlog sink

3. **xbmc/platform/linux/utils/TizenInterfaceForCLog.cpp**
   - Implementation of Tizen logging interface
   - Creates platform log instance for TARGET_TIZEN builds
   - Adds dlog sink to the distribution sink

### Files Modified

1. **xbmc/platform/linux/CMakeLists.txt**
   - Added TizenInterfaceForCLog.cpp to SOURCES for TARGET_TIZEN
   - Added TizenInterfaceForCLog.h and DlogSink.h to HEADERS for TARGET_TIZEN

2. **xbmc/platform/linux/PlatformTizen.cpp**
   - Added documentation comment explaining logging integration
   - Existing dlog_print() calls remain for direct Tizen logging in specific scenarios

3. **xbmc/platform/linux/test/TestPlatformTizen.cpp**
   - Added tests for Tizen logging integration
   - Added tests for dlog logging at various levels
   - Added tests for log level mapping

## Log Level Mapping

The implementation maps Kodi log levels to Tizen dlog priorities as follows:

| Kodi Log Level | spdlog Level | dlog Priority |
|----------------|--------------|---------------|
| LOGDEBUG       | debug        | DLOG_DEBUG    |
| LOGINFO        | info         | DLOG_INFO     |
| LOGWARNING     | warn         | DLOG_WARN     |
| LOGERROR       | err          | DLOG_ERROR    |
| LOGFATAL       | critical     | DLOG_ERROR    |

## Usage

### Viewing Logs

Logs can be viewed on a Tizen device using SDB (Smart Development Bridge):

```bash
# View all Kodi logs
sdb dlog KODI:V

# View only error logs
sdb dlog KODI:E

# View info and above
sdb dlog KODI:I
```

### Logging in Code

No changes are required to existing Kodi logging code. All `CLog::Log()` calls will automatically output to dlog when running on Tizen:

```cpp
CLog::Log(LOGDEBUG, "Debug message");
CLog::Log(LOGINFO, "Info message");
CLog::Log(LOGWARNING, "Warning message");
CLog::Log(LOGERROR, "Error message");
CLog::Log(LOGFATAL, "Fatal message");
```

## Architecture

The logging integration follows the established pattern used by Android:

1. **IPlatformLog Interface**: Base interface for platform-specific logging
2. **CPosixInterfaceForCLog**: POSIX implementation (base class)
3. **CTizenInterfaceForCLog**: Tizen-specific implementation
4. **DlogSink**: Custom spdlog sink for dlog output

```
IPlatformLog (interface)
    ↓
CPosixInterfaceForCLog (base implementation)
    ↓
CTizenInterfaceForCLog (Tizen-specific)
    ↓
DlogSink (custom spdlog sink)
    ↓
dlog_print() (Tizen native API)
```

## Testing

Unit tests have been added to verify:

1. Tizen logging interface can be created
2. Logging at various levels doesn't crash
3. Log level mapping works correctly

Tests are located in: `xbmc/platform/linux/test/TestPlatformTizen.cpp`

## Requirements Satisfied

This implementation satisfies **Requirement 9.3** from the Kodi Tizen Migration specification:

> **9.3** WHEN logs are written, THE Tizen_Platform SHALL use Tizen's dlog system for logging

## Benefits

1. **Native Integration**: Logs appear in Tizen's native logging system
2. **Remote Debugging**: Logs can be viewed remotely via SDB
3. **Filtering**: dlog supports filtering by tag and priority
4. **Performance**: Efficient logging using Tizen's optimized dlog system
5. **Consistency**: Follows the same pattern as Android logging integration

## Future Enhancements

Potential future improvements:

1. Add log rotation/cleanup for persistent logs
2. Add performance metrics logging
3. Add crash dump integration with dlog
4. Add log filtering configuration
