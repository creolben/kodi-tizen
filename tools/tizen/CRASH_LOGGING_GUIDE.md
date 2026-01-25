# Tizen Crash Logging Guide

This guide explains how crash logging works in Kodi for Tizen and how to access and analyze crash logs.

## Table of Contents

1. [Overview](#overview)
2. [Crash Handler](#crash-handler)
3. [Accessing Crash Logs](#accessing-crash-logs)
4. [Analyzing Crash Logs](#analyzing-crash-logs)
5. [Common Crash Scenarios](#common-crash-scenarios)
6. [Debugging Crashes](#debugging-crashes)

## Overview

Kodi for Tizen includes a comprehensive crash logging system that captures fatal errors and generates detailed crash reports. When a crash occurs, the system:

1. Captures the signal that caused the crash (SIGSEGV, SIGABRT, etc.)
2. Generates a backtrace showing the call stack
3. Logs crash information to dlog (Tizen system log)
4. Writes a detailed crash report to a file
5. Terminates the application gracefully

### Crash Log Locations

Crash information is written to two locations:

1. **dlog (System Log)**
   - Accessible via: `sdb dlog KODI:F`
   - Contains summary of crash information
   - Viewable in real-time

2. **Crash Log Files**
   - Location: `/opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_YYYYMMDD_HHMMSS.log`
   - Contains detailed crash report with backtrace
   - Persists across reboots

## Crash Handler

### Signals Handled

The crash handler intercepts the following fatal signals:

| Signal | Description |
|--------|-------------|
| SIGSEGV | Segmentation fault (invalid memory access) |
| SIGABRT | Abort signal (abnormal termination) |
| SIGFPE | Floating point exception |
| SIGILL | Illegal instruction |
| SIGBUS | Bus error (invalid memory alignment) |
| SIGSYS | Bad system call |

### Crash Report Contents

Each crash report includes:

- **Timestamp** - When the crash occurred
- **Signal Information** - Signal number, name, and description
- **Fault Address** - Memory address that caused the fault (if applicable)
- **Process Information** - Process ID and thread ID
- **Backtrace** - Call stack showing function calls leading to crash
- **System Information** - Platform and build details

### Example Crash Report

```
========================================
Kodi Crash Report
========================================

Time: 2024-01-15 14:32:45

Signal: 11 (SIGSEGV)
Description: Segmentation fault (invalid memory access)
Signal code: 1
Fault address: 0x0
Sending PID: 1234

Process ID: 1234
Thread ID: 1234

Backtrace:
  #0: /opt/usr/apps/org.xbmc.kodi/bin/kodi-tizen(+0x123456) [0x7f1234567890]
  #1: /opt/usr/apps/org.xbmc.kodi/bin/kodi-tizen(+0x234567) [0x7f1234567891]
  #2: /lib/libc.so.6(__libc_start_main+0xf0) [0x7f1234567892]

========================================
End of crash report
========================================
```

## Accessing Crash Logs

### Method 1: Using the Logs Script (Recommended)

```bash
# View crash logs
./tools/tizen/logs.sh -C

# View crash logs from specific device
./tools/tizen/logs.sh -d emulator-26101 -C
```

This will show:
- Recent fatal errors from dlog
- List of crash log files on the device
- Instructions for downloading crash logs

### Method 2: Using SDB Directly

#### View Fatal Errors in dlog

```bash
# View all fatal errors
sdb dlog KODI:F

# View fatal errors with context
sdb dlog KODI:F *:S

# Follow fatal errors in real-time
sdb dlog KODI:F | grep --color=auto "CRASH"
```

#### List Crash Log Files

```bash
# List crash logs
sdb shell "ls -lh /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_*.log"

# Count crash logs
sdb shell "ls /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_*.log 2>/dev/null | wc -l"
```

#### Download Crash Logs

```bash
# Download all crash logs
sdb pull /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_*.log ./

# Download specific crash log
sdb pull /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_20240115_143245.log ./

# Download and view immediately
sdb pull /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_20240115_143245.log - | less
```

#### View Crash Log on Device

```bash
# View crash log directly on device
sdb shell "cat /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_20240115_143245.log"

# View most recent crash log
sdb shell "cat \$(ls -t /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_*.log | head -n1)"
```

### Method 3: Using Tizen Studio

1. Open **Device Manager** in Tizen Studio
2. Select your device
3. Click **File Manager**
4. Navigate to: `/opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/`
5. Download crash log files

## Analyzing Crash Logs

### Understanding the Backtrace

The backtrace shows the sequence of function calls that led to the crash:

```
Backtrace:
  #0: /opt/usr/apps/org.xbmc.kodi/bin/kodi-tizen(+0x123456) [0x7f1234567890]
  #1: /opt/usr/apps/org.xbmc.kodi/bin/kodi-tizen(+0x234567) [0x7f1234567891]
  #2: /lib/libc.so.6(__libc_start_main+0xf0) [0x7f1234567892]
```

- **#0** is the function where the crash occurred
- **#1, #2, etc.** are the calling functions
- **+0x123456** is the offset within the binary
- **[0x7f1234567890]** is the absolute memory address

### Resolving Symbols

To get function names from addresses, use `addr2line`:

```bash
# Get function name from address
arm-tizen-linux-gnueabi-addr2line -e kodi-tizen -f 0x123456

# Process entire backtrace
cat crash.log | grep "#" | while read line; do
    addr=$(echo $line | grep -oP '\+0x[0-9a-f]+')
    arm-tizen-linux-gnueabi-addr2line -e kodi-tizen -f $addr
done
```

### Using GDB for Analysis

```bash
# Start GDB with crash log
arm-tizen-linux-gnueabi-gdb kodi-tizen

# Load crash addresses
(gdb) info symbol 0x123456
(gdb) list *0x123456

# Examine memory
(gdb) x/10i 0x123456
```

### Common Crash Patterns

#### Null Pointer Dereference

```
Signal: 11 (SIGSEGV)
Fault address: 0x0
```

**Cause:** Attempting to access memory at address 0 (null pointer)

**Solution:** Check for null pointer checks before dereferencing

#### Stack Overflow

```
Signal: 11 (SIGSEGV)
Fault address: 0x7fff...
Backtrace shows recursive calls
```

**Cause:** Stack exhausted due to deep recursion or large stack allocations

**Solution:** Reduce recursion depth or stack usage

#### Invalid Memory Access

```
Signal: 11 (SIGSEGV)
Fault address: 0xdeadbeef (or other invalid address)
```

**Cause:** Accessing freed memory or corrupted pointer

**Solution:** Check memory management, use-after-free, double-free

#### Assertion Failure

```
Signal: 6 (SIGABRT)
Backtrace shows assert() or abort()
```

**Cause:** Assertion failed or explicit abort() call

**Solution:** Check assertion condition and fix logic error

## Common Crash Scenarios

### Scenario 1: Crash on Startup

**Symptoms:**
- Application crashes immediately after launch
- Crash log shows early initialization code

**Debugging Steps:**

1. Check crash log for initialization functions
2. Verify all dependencies are present
3. Check file permissions
4. Verify Tizen API initialization

```bash
# Check if all libraries are present
sdb shell "ldd /opt/usr/apps/org.xbmc.kodi/bin/kodi-tizen"

# Check file permissions
sdb shell "ls -la /opt/usr/apps/org.xbmc.kodi/"
```

### Scenario 2: Crash During Playback

**Symptoms:**
- Crash occurs when playing media
- Crash log shows media pipeline code

**Debugging Steps:**

1. Check codec support
2. Verify media file format
3. Check AVPlay initialization
4. Test with different media files

```bash
# Check supported codecs
sdb shell "gst-inspect-1.0"

# Test with simple media file
sdb push test.mp4 /tmp/
```

### Scenario 3: Crash on Network Operation

**Symptoms:**
- Crash during network streaming
- Crash log shows network code

**Debugging Steps:**

1. Verify network connectivity
2. Check DNS resolution
3. Test with local files
4. Check network permissions

```bash
# Test network connectivity
sdb shell "ping -c 3 www.google.com"

# Check network permissions
sdb shell "cat /opt/usr/apps/org.xbmc.kodi/tizen-manifest.xml | grep network"
```

### Scenario 4: Random Crashes

**Symptoms:**
- Crashes occur unpredictably
- Different crash locations each time

**Possible Causes:**
- Memory corruption
- Race condition
- Use-after-free
- Buffer overflow

**Debugging Steps:**

1. Enable memory debugging tools
2. Run with Valgrind (if available)
3. Add memory guards
4. Check for threading issues

## Debugging Crashes

### Enable Debug Build

Build with debug symbols for better crash analysis:

```bash
# Configure with debug enabled
cd tools/depends
./configure --enable-debug=yes ...

# Build Kodi with debug symbols
cd ../../build
cmake .. -DCMAKE_BUILD_TYPE=Debug ...
make
```

### Using GDB for Live Debugging

```bash
# Enable root access
sdb root on

# Start gdbserver on device
sdb shell "gdbserver :5039 /opt/usr/apps/org.xbmc.kodi/bin/kodi-tizen"

# On host, connect with GDB
arm-tizen-linux-gnueabi-gdb kodi-tizen
(gdb) target remote localhost:5039
(gdb) continue

# When crash occurs, examine state
(gdb) backtrace
(gdb) info registers
(gdb) info locals
```

### Adding Debug Logging

Add logging around suspected crash locations:

```cpp
CLog::Log(LOGDEBUG, "Before potentially crashing operation");
dlog_print(DLOG_DEBUG, "KODI", "Pointer value: %p", ptr);

// Potentially crashing operation
if (ptr != nullptr) {
    ptr->DoSomething();
}

CLog::Log(LOGDEBUG, "After potentially crashing operation");
```

### Memory Debugging

```cpp
// Add memory guards
#ifdef _DEBUG
#include <mcheck.h>
mcheck(nullptr);  // Enable memory debugging
#endif

// Check for memory leaks
#include <sanitizer/lsan_interface.h>
__lsan_do_leak_check();
```

## Best Practices

### Preventing Crashes

1. **Always check pointers before dereferencing**
   ```cpp
   if (ptr != nullptr) {
       ptr->DoSomething();
   }
   ```

2. **Use smart pointers**
   ```cpp
   std::unique_ptr<Object> obj = std::make_unique<Object>();
   ```

3. **Validate input parameters**
   ```cpp
   if (size == 0 || buffer == nullptr) {
       return ERROR_INVALID_PARAMETER;
   }
   ```

4. **Handle exceptions**
   ```cpp
   try {
       RiskyOperation();
   } catch (const std::exception& e) {
       CLog::Log(LOGERROR, "Exception: {}", e.what());
   }
   ```

5. **Use assertions for invariants**
   ```cpp
   assert(index < array.size());
   ```

### Crash Log Maintenance

```bash
# Clean up old crash logs (keep last 10)
sdb shell "cd /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data && ls -t crash_*.log | tail -n +11 | xargs rm -f"

# Archive crash logs
sdb pull /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_*.log ./crash_logs/
tar czf crash_logs_$(date +%Y%m%d).tar.gz crash_logs/
```

## Additional Resources

- [GDB Documentation](https://www.gnu.org/software/gdb/documentation/)
- [Linux Signal Handling](https://man7.org/linux/man-pages/man7/signal.7.html)
- [Tizen Native Debugging](https://developer.tizen.org/development/training/native-application/debugging)
- [Kodi Development Guide](https://kodi.wiki/view/Development)

## Quick Reference

### View Recent Crashes

```bash
# Using script
./tools/tizen/logs.sh -C

# Using SDB
sdb dlog KODI:F
```

### Download Crash Logs

```bash
# All crash logs
sdb pull /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_*.log ./

# Most recent
sdb pull $(sdb shell "ls -t /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_*.log | head -n1") ./
```

### Analyze Backtrace

```bash
# Resolve symbols
arm-tizen-linux-gnueabi-addr2line -e kodi-tizen -f 0x123456

# Use GDB
arm-tizen-linux-gnueabi-gdb kodi-tizen
(gdb) list *0x123456
```
