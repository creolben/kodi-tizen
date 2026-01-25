/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

/*
 * Tizen Platform Implementation
 * 
 * This file implements the Tizen-specific platform layer for Kodi, including:
 * - Application lifecycle management (pause, resume, terminate)
 * - System information queries (CPU, GPU, memory)
 * - Logging integration with Tizen's dlog system
 * 
 * Logging Integration:
 * Kodi's logging is integrated with Tizen's native dlog system through a custom
 * spdlog sink (see utils/DlogSink.h and utils/TizenInterfaceForCLog.cpp).
 * This allows logs to be viewed via SDB using: sdb dlog KODI:V
 * 
 * Log level mapping:
 *   LOGDEBUG   -> DLOG_DEBUG
 *   LOGINFO    -> DLOG_INFO
 *   LOGWARNING -> DLOG_WARN
 *   LOGERROR   -> DLOG_ERROR
 *   LOGFATAL   -> DLOG_ERROR (critical)
 */

#include "PlatformTizen.h"

#include "CompileInfo.h"
#include "ServiceBroker.h"
#include "TizenCrashHandler.h"
#include "application/AppInboundProtocol.h"
#include "application/Application.h"
#include "filesystem/SpecialProtocol.h"
#include "powermanagement/TizenPowerManagement.h"
#include "utils/log.h"

#include <filesystem>
#include <fstream>
#include <memory>
#include <string>

#include <arpa/inet.h>
#include <netdb.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <sys/vfs.h>
#include <unistd.h>

#if defined(TARGET_TIZEN)
#include <app.h>
#include <app_common.h>
#include <app_event.h>
#include <dlog.h>
#include <storage.h>
#include <system_info.h>
#include <net_connection.h>
#include <wifi-manager.h>
#endif

CPlatform* CPlatform::CreateInstance()
{
  return new CPlatformTizen();
}

CPlatformTizen::CPlatformTizen()
#if defined(TARGET_TIZEN)
  : m_suspendedHandler(nullptr)
  , m_lowMemoryHandler(nullptr)
  , m_connectionHandle(nullptr)
  , m_networkConnected(false)
  , m_networkType(CONNECTION_TYPE_DISCONNECTED)
#endif
{
}

CPlatformTizen::~CPlatformTizen()
{
  ShutdownNetworkMonitoring();
  UnregisterAppLifecycleCallbacks();
  
#if defined(TARGET_TIZEN)
  // Uninstall crash handlers
  CTizenCrashHandler::Uninstall();
#endif
}

std::string CPlatformTizen::GetHomePath()
{
#if defined(TARGET_TIZEN)
  // Use Tizen's app_get_data_path() to get the application data directory
  char* dataPath = nullptr;
  int ret = app_get_data_path(&dataPath);
  
  if (ret == APP_ERROR_NONE && dataPath != nullptr)
  {
    std::string path(dataPath);
    free(dataPath);
    
    // Remove trailing slash if present
    if (!path.empty() && path.back() == '/')
      path.pop_back();
    
    return path;
  }
  
  CLog::Log(LOGERROR, "CPlatformTizen: Failed to get app data path, error: {}", ret);
#endif
  
  // Fallback to reading symlink
  std::filesystem::path self("/proc/self/exe");
  std::error_code ec;
  std::filesystem::path path = std::filesystem::read_symlink(self, ec);

  if (ec)
  {
    const char* homeEnv = getenv("HOME");
    return homeEnv ? std::string(homeEnv) : std::string("");
  }

  return path.parent_path().string();
}

bool CPlatformTizen::InitStageOne()
{
#if defined(TARGET_TIZEN)
  // Get the application home path
  const auto HOME = GetHomePath();

  // Set up environment variables for Tizen
  setenv("APPID", CCompileInfo::GetPackage(), 0);
  setenv("FONTCONFIG_FILE", "/etc/fonts/fonts.conf", 1);
  setenv("FONTCONFIG_PATH", "/etc/fonts", 1);
  setenv("GST_PLUGIN_SCANNER_1_0", (HOME + "/lib/gst-plugin-scanner").c_str(), 1);
  setenv("XDG_RUNTIME_DIR", "/tmp/xdg", 1);
  setenv("XKB_CONFIG_ROOT", "/usr/share/X11/xkb", 1);
  setenv("WAYLAND_DISPLAY", "wayland-0", 1);
  setenv("PYTHONHOME", (HOME + "/lib/python3").c_str(), 1);

  // Set up Python path
  std::string pythonPath;
  pythonPath = HOME + "/lib/python3";
  pythonPath += ":" + pythonPath + "/site-packages";

  setenv("PYTHONPATH", pythonPath.c_str(), 1);
  setenv("PYTHONIOENCODING", "UTF-8", 1);
  setenv("KODI_HOME", HOME.c_str(), 1);
  setenv("SSL_CERT_FILE",
         CSpecialProtocol::TranslatePath("special://xbmc/system/certs/cacert.pem").c_str(), 1);

  CLog::Log(LOGINFO, "CPlatformTizen: Initialized with HOME path: {}", HOME);
#endif

  return CPlatformLinux::InitStageOne();
}

bool CPlatformTizen::InitStageTwo()
{
#if defined(TARGET_TIZEN)
  // Install crash handlers (Task 13.4)
  if (!CTizenCrashHandler::Install())
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: Failed to install crash handlers");
    // Non-critical, continue
  }
  
  // Disable core dumps for production
  constexpr rlimit limit{0, 0};
  if (setrlimit(RLIMIT_CORE, &limit) != 0)
    CLog::Log(LOGERROR, "CPlatformTizen: Failed to disable core dumps");

  // Register Tizen application lifecycle callbacks
  if (!RegisterAppLifecycleCallbacks())
  {
    CLog::Log(LOGERROR, "CPlatformTizen: Failed to register app lifecycle callbacks");
    return false;
  }

  CLog::Log(LOGINFO, "CPlatformTizen: Stage two initialization complete");
#endif

  return CPlatformLinux::InitStageTwo();
}

bool CPlatformTizen::InitStageThree()
{
#if defined(TARGET_TIZEN)
  // Check storage space and warn if low
  CheckStorageSpace();
  
  // Initialize network monitoring (Task 10.1)
  if (!InitializeNetworkMonitoring())
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: Failed to initialize network monitoring");
    // Non-critical, continue
  }
  
  // Verify POSIX networking compatibility (Task 10.2)
  if (m_networkConnected)
  {
    if (!VerifyPOSIXNetworking())
    {
      CLog::Log(LOGWARNING, "CPlatformTizen: POSIX networking verification failed");
      // Non-critical, continue
    }
    
    // Log Wi-Fi information if connected via Wi-Fi (Task 10.3)
    if (IsWiFiConnected())
    {
      std::string ssid, ipAddress;
      int signalStrength;
      if (GetWiFiInfo(ssid, ipAddress, signalStrength))
      {
        CLog::Log(LOGINFO, "CPlatformTizen: Connected to Wi-Fi network: {} (IP: {}, Signal: {} dBm)",
                  ssid, ipAddress, signalStrength);
      }
    }
  }
  else
  {
    CLog::Log(LOGINFO, "CPlatformTizen: Skipping POSIX networking verification - no network connection");
  }
  
  CLog::Log(LOGINFO, "CPlatformTizen: Stage three initialization complete");
#endif

  return CPlatformLinux::InitStageThree();
}

void CPlatformTizen::RegisterPowerManagement()
{
#if defined(TARGET_TIZEN)
  // Register Tizen-specific power management
  CLog::Log(LOGINFO, "CPlatformTizen: Registering Tizen power management");
  CTizenPowerManagement::Register();
#else
  // Fallback to Linux default power management
  CPlatformLinux::RegisterPowerManagement();
#endif
}

bool CPlatformTizen::IsConfigureAddonsAtStartupEnabled()
{
  // Disable addon configuration at startup for Tizen (similar to webOS)
  return false;
}

bool CPlatformTizen::RegisterAppLifecycleCallbacks()
{
#if defined(TARGET_TIZEN)
  int ret;
  
  // Register suspended state change callback (handles pause/resume)
  ret = ui_app_add_event_handler(&m_suspendedHandler, APP_EVENT_SUSPENDED_STATE_CHANGED,
                                  OnAppSuspendedStateChanged, this);
  if (ret != APP_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CPlatformTizen: Failed to register suspended state callback, error: {}", ret);
    return false;
  }
  
  // Register low memory callback
  ret = ui_app_add_event_handler(&m_lowMemoryHandler, APP_EVENT_LOW_MEMORY,
                                  OnAppLowMemory, this);
  if (ret != APP_ERROR_NONE)
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: Failed to register low memory callback, error: {}", ret);
    // Non-critical, continue
  }
  
  CLog::Log(LOGINFO, "CPlatformTizen: App lifecycle callbacks registered successfully");
  return true;
#else
  return true;
#endif
}

void CPlatformTizen::UnregisterAppLifecycleCallbacks()
{
#if defined(TARGET_TIZEN)
  if (m_suspendedHandler != nullptr)
  {
    ui_app_remove_event_handler(m_suspendedHandler);
    m_suspendedHandler = nullptr;
  }
  
  if (m_lowMemoryHandler != nullptr)
  {
    ui_app_remove_event_handler(m_lowMemoryHandler);
    m_lowMemoryHandler = nullptr;
  }
  
  CLog::Log(LOGINFO, "CPlatformTizen: App lifecycle callbacks unregistered");
#endif
}

void CPlatformTizen::OnAppSuspendedStateChanged(app_event_info_h event_info, void* userData)
{
#if defined(TARGET_TIZEN)
  auto* platform = static_cast<CPlatformTizen*>(userData);
  if (!platform)
    return;
  
  app_suspended_state_e state;
  int ret = app_event_get_suspended_state(event_info, &state);
  
  if (ret != APP_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CPlatformTizen: Failed to get suspended state, error: {}", ret);
    return;
  }
  
  if (state == APP_SUSPENDED_STATE_SUSPENDED)
  {
    platform->OnAppPause();
  }
  else if (state == APP_SUSPENDED_STATE_RUNNING)
  {
    platform->OnAppResume();
  }
#endif
}

void CPlatformTizen::OnAppLowMemory(app_event_info_h event_info, void* userData)
{
#if defined(TARGET_TIZEN)
  CLog::Log(LOGWARNING, "CPlatformTizen: Low memory warning received");
  dlog_print(DLOG_WARN, "KODI", "Low memory warning - consider freeing resources");
  
  // TODO: Implement memory cleanup/cache clearing
  // This could trigger cache cleanup, texture unloading, etc.
#endif
}

void CPlatformTizen::OnAppPause()
{
#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CPlatformTizen: OnAppPause - Application paused");
  
  // Pause playback when app is backgrounded
  auto app = CServiceBroker::GetAppMessenger();
  if (app)
  {
    // Send pause message to the application
    app->SendMsg(TMSG_MEDIA_PAUSE);
  }
  
  dlog_print(DLOG_INFO, "KODI", "Application paused - playback stopped");
#endif
}

void CPlatformTizen::OnAppResume()
{
#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CPlatformTizen: OnAppResume - Application resumed");
  
  // Note: We don't automatically resume playback as this is typically
  // not desired behavior. The user can manually resume if needed.
  
  dlog_print(DLOG_INFO, "KODI", "Application resumed");
#endif
}

void CPlatformTizen::PlatformSyslog()
{
#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CPlatformTizen: System Information:");
  
  // Log CPU information
  std::string cpuInfo = GetCPUInfo();
  if (!cpuInfo.empty())
    CLog::Log(LOGINFO, "  CPU: {}", cpuInfo);
  
  // Log GPU information
  std::string gpuInfo = GetGPUInfo();
  if (!gpuInfo.empty())
    CLog::Log(LOGINFO, "  GPU: {}", gpuInfo);
  
  // Log memory information
  std::string memInfo = GetMemoryInfo();
  if (!memInfo.empty())
    CLog::Log(LOGINFO, "  Memory: {}", memInfo);
#endif
}

std::string CPlatformTizen::GetCPUInfo()
{
#if defined(TARGET_TIZEN)
  std::string cpuInfo;
  char* value = nullptr;
  int ret;
  
  // Get CPU architecture
  ret = system_info_get_platform_string("http://tizen.org/feature/platform.core.cpu.arch", &value);
  if (ret == SYSTEM_INFO_ERROR_NONE && value != nullptr)
  {
    cpuInfo = "Architecture: ";
    cpuInfo += value;
    free(value);
    value = nullptr;
  }
  
  // Get CPU frequency
  ret = system_info_get_platform_string("http://tizen.org/feature/platform.core.cpu.frequency", &value);
  if (ret == SYSTEM_INFO_ERROR_NONE && value != nullptr)
  {
    if (!cpuInfo.empty())
      cpuInfo += ", ";
    cpuInfo += "Frequency: ";
    cpuInfo += value;
    cpuInfo += " MHz";
    free(value);
    value = nullptr;
  }
  
  // Get number of CPU cores
  ret = system_info_get_platform_string("http://tizen.org/feature/multi_point_touch.point_count", &value);
  if (ret == SYSTEM_INFO_ERROR_NONE && value != nullptr)
  {
    // Note: This is a workaround as Tizen doesn't have a direct CPU core count API
    // We'll try to read from /proc/cpuinfo instead
    free(value);
    value = nullptr;
  }
  
  // Try to get CPU core count from system
  std::ifstream cpuinfo("/proc/cpuinfo");
  if (cpuinfo.is_open())
  {
    std::string line;
    int coreCount = 0;
    while (std::getline(cpuinfo, line))
    {
      if (line.find("processor") == 0)
        coreCount++;
    }
    cpuinfo.close();
    
    if (coreCount > 0)
    {
      if (!cpuInfo.empty())
        cpuInfo += ", ";
      cpuInfo += "Cores: ";
      cpuInfo += std::to_string(coreCount);
    }
  }
  
  if (cpuInfo.empty())
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: Failed to retrieve CPU information");
    return "Unknown";
  }
  
  return cpuInfo;
#else
  return "";
#endif
}

std::string CPlatformTizen::GetGPUInfo()
{
#if defined(TARGET_TIZEN)
  std::string gpuInfo;
  bool supported = false;
  int ret;
  
  // Check if OpenGL ES is supported
  ret = system_info_get_platform_bool("http://tizen.org/feature/opengles.version.2_0", &supported);
  if (ret == SYSTEM_INFO_ERROR_NONE && supported)
  {
    gpuInfo = "OpenGL ES 2.0";
  }
  
  // Check for OpenGL ES 3.0 support
  ret = system_info_get_platform_bool("http://tizen.org/feature/opengles.version.3_0", &supported);
  if (ret == SYSTEM_INFO_ERROR_NONE && supported)
  {
    if (!gpuInfo.empty())
      gpuInfo += ", ";
    gpuInfo += "OpenGL ES 3.0";
  }
  
  // Check for OpenGL ES 3.1 support
  ret = system_info_get_platform_bool("http://tizen.org/feature/opengles.version.3_1", &supported);
  if (ret == SYSTEM_INFO_ERROR_NONE && supported)
  {
    if (!gpuInfo.empty())
      gpuInfo += ", ";
    gpuInfo += "OpenGL ES 3.1";
  }
  
  // Check for OpenGL ES 3.2 support
  ret = system_info_get_platform_bool("http://tizen.org/feature/opengles.version.3_2", &supported);
  if (ret == SYSTEM_INFO_ERROR_NONE && supported)
  {
    if (!gpuInfo.empty())
      gpuInfo += ", ";
    gpuInfo += "OpenGL ES 3.2";
  }
  
  // Check for texture compression support
  ret = system_info_get_platform_bool("http://tizen.org/feature/opengles.texture_format.utc", &supported);
  if (ret == SYSTEM_INFO_ERROR_NONE && supported)
  {
    if (!gpuInfo.empty())
      gpuInfo += ", ";
    gpuInfo += "UTC texture compression";
  }
  
  if (gpuInfo.empty())
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: Failed to retrieve GPU information");
    return "Unknown";
  }
  
  return gpuInfo;
#else
  return "";
#endif
}

std::string CPlatformTizen::GetMemoryInfo()
{
#if defined(TARGET_TIZEN)
  std::string memInfo;
  
  // Try to read memory information from /proc/meminfo
  std::ifstream meminfo("/proc/meminfo");
  if (meminfo.is_open())
  {
    std::string line;
    long totalMem = 0;
    long availMem = 0;
    
    while (std::getline(meminfo, line))
    {
      if (line.find("MemTotal:") == 0)
      {
        // Extract memory value (in kB)
        size_t pos = line.find_first_of("0123456789");
        if (pos != std::string::npos)
        {
          std::string value = line.substr(pos);
          value = value.substr(0, value.find_first_not_of("0123456789"));
          totalMem = std::stol(value);
        }
      }
      else if (line.find("MemAvailable:") == 0)
      {
        // Extract memory value (in kB)
        size_t pos = line.find_first_of("0123456789");
        if (pos != std::string::npos)
        {
          std::string value = line.substr(pos);
          value = value.substr(0, value.find_first_not_of("0123456789"));
          availMem = std::stol(value);
        }
      }
    }
    meminfo.close();
    
    if (totalMem > 0)
    {
      // Convert kB to MB
      long totalMemMB = totalMem / 1024;
      memInfo = "Total: ";
      memInfo += std::to_string(totalMemMB);
      memInfo += " MB";
      
      if (availMem > 0)
      {
        long availMemMB = availMem / 1024;
        memInfo += ", Available: ";
        memInfo += std::to_string(availMemMB);
        memInfo += " MB";
      }
    }
  }
  
  if (memInfo.empty())
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: Failed to retrieve memory information");
    return "Unknown";
  }
  
  return memInfo;
#else
  return "";
#endif
}

// Task 9.2: Storage space monitoring implementation
bool CPlatformTizen::CheckStorageSpace()
{
#if defined(TARGET_TIZEN)
  unsigned long long total = 0;
  unsigned long long available = 0;
  
  if (!GetStorageInfo(total, available))
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: Failed to get storage information");
    return false;
  }
  
  // Warn if less than 100MB available
  const unsigned long long minSpace = 100 * 1024 * 1024; // 100 MB in bytes
  
  if (available < minSpace)
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: Low storage space - {} MB available (minimum {} MB recommended)",
              available / (1024 * 1024), minSpace / (1024 * 1024));
    dlog_print(DLOG_WARN, "KODI", "Low storage space: %llu MB available", available / (1024 * 1024));
    return false;
  }
  
  CLog::Log(LOGINFO, "CPlatformTizen: Storage space OK - {} MB available of {} MB total",
            available / (1024 * 1024), total / (1024 * 1024));
  return true;
#else
  return true;
#endif
}

bool CPlatformTizen::GetStorageInfo(unsigned long long& total, unsigned long long& available)
{
#if defined(TARGET_TIZEN)
  int storage_id = 0;
  int ret;
  
  // Get internal storage ID
  ret = storage_get_internal_memory_size(&storage_id, &total, &available);
  
  if (ret != STORAGE_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CPlatformTizen: Failed to get internal memory size, error: {}", ret);
    
    // Fallback: Try to get storage info from the data path using statfs
    char* dataPath = nullptr;
    ret = app_get_data_path(&dataPath);
    
    if (ret == APP_ERROR_NONE && dataPath != nullptr)
    {
      std::string path(dataPath);
      free(dataPath);
      
      // Use POSIX statfs as fallback
      struct statfs stat;
      if (statfs(path.c_str(), &stat) == 0)
      {
        total = static_cast<unsigned long long>(stat.f_blocks) * stat.f_bsize;
        available = static_cast<unsigned long long>(stat.f_bavail) * stat.f_bsize;
        
        CLog::Log(LOGINFO, "CPlatformTizen: Using statfs fallback for storage info");
        return true;
      }
    }
    
    return false;
  }
  
  return true;
#else
  total = 0;
  available = 0;
  return false;
#endif
}

// Task 10.1: Network status monitoring implementation
bool CPlatformTizen::InitializeNetworkMonitoring()
{
#if defined(TARGET_TIZEN)
  int ret;
  
  // Create connection handle
  ret = connection_create(&m_connectionHandle);
  if (ret != CONNECTION_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CPlatformTizen: Failed to create connection handle, error: {}", ret);
    return false;
  }
  
  // Get initial network type
  ret = connection_get_type(m_connectionHandle, &m_networkType);
  if (ret != CONNECTION_ERROR_NONE)
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: Failed to get initial network type, error: {}", ret);
    m_networkType = CONNECTION_TYPE_DISCONNECTED;
  }
  
  // Set initial connection status
  m_networkConnected = (m_networkType != CONNECTION_TYPE_DISCONNECTED);
  
  // Register network change callback
  ret = connection_set_type_changed_cb(m_connectionHandle, OnNetworkConnectionChanged, this);
  if (ret != CONNECTION_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CPlatformTizen: Failed to register network change callback, error: {}", ret);
    connection_destroy(m_connectionHandle);
    m_connectionHandle = nullptr;
    return false;
  }
  
  CLog::Log(LOGINFO, "CPlatformTizen: Network monitoring initialized - Initial state: {} (type: {})",
            m_networkConnected ? "Connected" : "Disconnected", static_cast<int>(m_networkType));
  
  return true;
#else
  return false;
#endif
}

void CPlatformTizen::ShutdownNetworkMonitoring()
{
#if defined(TARGET_TIZEN)
  if (m_connectionHandle != nullptr)
  {
    // Unregister callback
    connection_unset_type_changed_cb(m_connectionHandle);
    
    // Destroy connection handle
    connection_destroy(m_connectionHandle);
    m_connectionHandle = nullptr;
    
    CLog::Log(LOGINFO, "CPlatformTizen: Network monitoring shutdown");
  }
#endif
}

void CPlatformTizen::OnNetworkConnectionChanged(connection_type_e type, void* userData)
{
#if defined(TARGET_TIZEN)
  auto* platform = static_cast<CPlatformTizen*>(userData);
  if (!platform)
    return;
  
  platform->HandleNetworkChange(type);
#endif
}

void CPlatformTizen::HandleNetworkChange(connection_type_e type)
{
#if defined(TARGET_TIZEN)
  bool wasConnected = m_networkConnected;
  connection_type_e oldType = m_networkType;
  
  m_networkType = type;
  m_networkConnected = (type != CONNECTION_TYPE_DISCONNECTED);
  
  // Log network state change
  if (wasConnected != m_networkConnected)
  {
    if (m_networkConnected)
    {
      CLog::Log(LOGINFO, "CPlatformTizen: Network connected - Type: {}", static_cast<int>(type));
      dlog_print(DLOG_INFO, "KODI", "Network connected - Type: %d", static_cast<int>(type));
    }
    else
    {
      CLog::Log(LOGWARNING, "CPlatformTizen: Network disconnected");
      dlog_print(DLOG_WARN, "KODI", "Network disconnected");
    }
  }
  else if (oldType != type)
  {
    CLog::Log(LOGINFO, "CPlatformTizen: Network type changed from {} to {}",
              static_cast<int>(oldType), static_cast<int>(type));
    dlog_print(DLOG_INFO, "KODI", "Network type changed from %d to %d",
               static_cast<int>(oldType), static_cast<int>(type));
  }
  
  // TODO: Notify Kodi's network manager about the change
  // This could trigger reconnection attempts for network streams, etc.
#endif
}

bool CPlatformTizen::IsNetworkConnected()
{
#if defined(TARGET_TIZEN)
  return m_networkConnected;
#else
  return false;
#endif
}

std::string CPlatformTizen::GetNetworkType()
{
#if defined(TARGET_TIZEN)
  switch (m_networkType)
  {
    case CONNECTION_TYPE_DISCONNECTED:
      return "Disconnected";
    case CONNECTION_TYPE_WIFI:
      return "Wi-Fi";
    case CONNECTION_TYPE_CELLULAR:
      return "Cellular";
    case CONNECTION_TYPE_ETHERNET:
      return "Ethernet";
    case CONNECTION_TYPE_BT:
      return "Bluetooth";
    case CONNECTION_TYPE_NET_PROXY:
      return "Network Proxy";
    default:
      return "Unknown";
  }
#else
  return "Unknown";
#endif
}

// Task 10.2: POSIX networking verification implementation
bool CPlatformTizen::VerifyPOSIXNetworking()
{
#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CPlatformTizen: Verifying POSIX networking compatibility");
  
  // Test 1: Create a socket
  int sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd < 0)
  {
    CLog::Log(LOGERROR, "CPlatformTizen: Failed to create socket - POSIX networking not available");
    return false;
  }
  
  CLog::Log(LOGDEBUG, "CPlatformTizen: Socket creation successful");
  close(sockfd);
  
  // Test 2: Test DNS resolution with a well-known hostname
  if (!TestDNSResolution("www.google.com"))
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: DNS resolution test failed for www.google.com");
    // Try another hostname
    if (!TestDNSResolution("www.kodi.tv"))
    {
      CLog::Log(LOGERROR, "CPlatformTizen: DNS resolution not working");
      return false;
    }
  }
  
  CLog::Log(LOGINFO, "CPlatformTizen: POSIX networking verification successful");
  return true;
#else
  return false;
#endif
}

bool CPlatformTizen::TestDNSResolution(const std::string& hostname)
{
#if defined(TARGET_TIZEN)
  struct addrinfo hints{};
  struct addrinfo* result = nullptr;
  
  // Set up hints for getaddrinfo
  hints.ai_family = AF_UNSPEC;     // Allow IPv4 or IPv6
  hints.ai_socktype = SOCK_STREAM; // TCP socket
  hints.ai_flags = 0;
  hints.ai_protocol = 0;
  
  // Attempt DNS resolution
  int ret = getaddrinfo(hostname.c_str(), nullptr, &hints, &result);
  
  if (ret != 0)
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: DNS resolution failed for {}: {}",
              hostname, gai_strerror(ret));
    return false;
  }
  
  // Successfully resolved - log the first address
  if (result != nullptr)
  {
    char addrstr[INET6_ADDRSTRLEN];
    void* addr = nullptr;
    
    if (result->ai_family == AF_INET)
    {
      struct sockaddr_in* ipv4 = reinterpret_cast<struct sockaddr_in*>(result->ai_addr);
      addr = &(ipv4->sin_addr);
      inet_ntop(AF_INET, addr, addrstr, sizeof(addrstr));
    }
    else if (result->ai_family == AF_INET6)
    {
      struct sockaddr_in6* ipv6 = reinterpret_cast<struct sockaddr_in6*>(result->ai_addr);
      addr = &(ipv6->sin6_addr);
      inet_ntop(AF_INET6, addr, addrstr, sizeof(addrstr));
    }
    
    CLog::Log(LOGDEBUG, "CPlatformTizen: DNS resolution successful for {} -> {}",
              hostname, addrstr);
    
    freeaddrinfo(result);
    return true;
  }
  
  freeaddrinfo(result);
  return false;
#else
  return false;
#endif
}

// Task 10.3: Wi-Fi information queries implementation
bool CPlatformTizen::IsWiFiConnected()
{
#if defined(TARGET_TIZEN)
  return (m_networkConnected && m_networkType == CONNECTION_TYPE_WIFI);
#else
  return false;
#endif
}

bool CPlatformTizen::GetWiFiInfo(std::string& ssid, std::string& ipAddress, int& signalStrength)
{
#if defined(TARGET_TIZEN)
  // Check if Wi-Fi is connected
  if (!IsWiFiConnected())
  {
    CLog::Log(LOGDEBUG, "CPlatformTizen: Wi-Fi is not connected");
    return false;
  }
  
  wifi_manager_h wifi = nullptr;
  wifi_manager_ap_h ap = nullptr;
  int ret;
  
  // Initialize Wi-Fi manager
  ret = wifi_manager_initialize(&wifi);
  if (ret != WIFI_MANAGER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CPlatformTizen: Failed to initialize Wi-Fi manager, error: {}", ret);
    return false;
  }
  
  // Get connected AP
  ret = wifi_manager_get_connected_ap(wifi, &ap);
  if (ret != WIFI_MANAGER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CPlatformTizen: Failed to get connected AP, error: {}", ret);
    wifi_manager_deinitialize(wifi);
    return false;
  }
  
  // Get SSID
  char* essid = nullptr;
  ret = wifi_manager_ap_get_essid(ap, &essid);
  if (ret == WIFI_MANAGER_ERROR_NONE && essid != nullptr)
  {
    ssid = essid;
    free(essid);
  }
  else
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: Failed to get SSID, error: {}", ret);
    ssid = "Unknown";
  }
  
  // Get IP address
  char* ip = nullptr;
  ret = wifi_manager_ap_get_ip_address(ap, WIFI_MANAGER_ADDRESS_FAMILY_IPV4, &ip);
  if (ret == WIFI_MANAGER_ERROR_NONE && ip != nullptr)
  {
    ipAddress = ip;
    free(ip);
  }
  else
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: Failed to get IP address, error: {}", ret);
    ipAddress = "0.0.0.0";
  }
  
  // Get signal strength (RSSI)
  int rssi = 0;
  ret = wifi_manager_ap_get_rssi(ap, &rssi);
  if (ret == WIFI_MANAGER_ERROR_NONE)
  {
    signalStrength = rssi;
  }
  else
  {
    CLog::Log(LOGWARNING, "CPlatformTizen: Failed to get signal strength, error: {}", ret);
    signalStrength = 0;
  }
  
  CLog::Log(LOGINFO, "CPlatformTizen: Wi-Fi Info - SSID: {}, IP: {}, Signal: {} dBm",
            ssid, ipAddress, signalStrength);
  
  // Cleanup
  wifi_manager_ap_destroy(ap);
  wifi_manager_deinitialize(wifi);
  
  return true;
#else
  ssid = "Unknown";
  ipAddress = "0.0.0.0";
  signalStrength = 0;
  return false;
#endif
}



