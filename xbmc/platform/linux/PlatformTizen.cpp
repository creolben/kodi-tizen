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
#include "application/AppInboundProtocol.h"
#include "application/Application.h"
#include "filesystem/SpecialProtocol.h"
#include "powermanagement/TizenPowerManagement.h"
#include "utils/log.h"

#include <filesystem>
#include <fstream>
#include <memory>
#include <string>

#include <sys/resource.h>

#if defined(TARGET_TIZEN)
#include <app.h>
#include <app_common.h>
#include <app_event.h>
#include <dlog.h>
#include <system_info.h>
#endif

CPlatform* CPlatform::CreateInstance()
{
  return new CPlatformTizen();
}

CPlatformTizen::CPlatformTizen()
#if defined(TARGET_TIZEN)
  : m_suspendedHandler(nullptr)
  , m_lowMemoryHandler(nullptr)
#endif
{
}

CPlatformTizen::~CPlatformTizen()
{
  UnregisterAppLifecycleCallbacks();
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
