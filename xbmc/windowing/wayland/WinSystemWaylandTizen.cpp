/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "WinSystemWaylandTizen.h"

#include "Connection.h"
#include "OSScreenSaverIdleInhibitUnstableV1.h"
#include "OSScreenSaverTizen.h"
#include "Registry.h"
#include "Seat.h"
#include "SeatTizen.h"
#include "ShellSurfaceXdgShell.h"
#include "settings/DisplaySettings.h"
#include "settings/Settings.h"
#include "settings/SettingsComponent.h"
#include "utils/log.h"

#include <CompileInfo.h>

#if defined(TARGET_TIZEN)
#include <system_info.h>
#endif

#include <string>

namespace KODI
{
namespace WINDOWING
{
namespace WAYLAND
{

bool CWinSystemWaylandTizen::InitWindowSystem()
{
  if (!CWinSystemWayland::InitWindowSystem())
    return false;

  // Initialize Tizen-specific registry for any Tizen extensions
  m_tizenRegistry = std::make_unique<CRegistry>(*GetConnection());
  m_tizenRegistry->Bind();

  // Query display capabilities for HDR support
  if (!QueryDisplayCapabilities())
  {
    CLog::LogF(LOGWARNING, "Failed to query Tizen display capabilities");
  }

  CLog::LogF(LOGINFO, "Tizen windowing system initialized successfully");
  return true;
}

bool CWinSystemWaylandTizen::DestroyWindowSystem()
{
  if (m_tizenRegistry)
  {
    m_tizenRegistry->UnbindSingletons();
  }
  m_tizenRegistry.reset();

  return CWinSystemWayland::DestroyWindowSystem();
}

bool CWinSystemWaylandTizen::CreateNewWindow(const std::string& name,
                                             bool fullScreen,
                                             RESOLUTION_INFO& res)
{
  CLog::LogF(LOGINFO, "Creating Tizen window - name: '{}', fullscreen: {}, resolution: {}x{}",
             name, fullScreen, res.iWidth, res.iHeight);

  if (!CWinSystemWayland::CreateNewWindow(name, fullScreen, res))
  {
    CLog::LogF(LOGERROR, "Failed to create Tizen window");
    return false;
  }

  // Log fullscreen configuration status
  if (fullScreen)
  {
    CLog::LogF(LOGINFO, "Tizen window configured for fullscreen mode at {}x{}", res.iWidth,
               res.iHeight);
  }
  else
  {
    CLog::LogF(LOGINFO, "Tizen window configured for windowed mode at {}x{}", res.iWidth,
               res.iHeight);
  }

  return true;
}

bool CWinSystemWaylandTizen::HasCursor()
{
  // TV platforms don't have a cursor
  return false;
}

IShellSurface* CWinSystemWaylandTizen::CreateShellSurface(const std::string& name)
{
  // Use standard xdg_shell for Tizen
  return CShellSurfaceXdgShell::TryCreate(*this, *GetConnection(), GetMainSurface(), name,
                                          std::string(CCompileInfo::GetAppName()));
}

void CWinSystemWaylandTizen::OnConfigure(std::uint32_t serial,
                                         CSizeInt size,
                                         IShellSurface::StateBitset state)
{
  // Log resolution changes for debugging
  CLog::LogF(LOGDEBUG, "OnConfigure called - serial: {}, size: {}x{}, fullscreen: {}", serial,
             size.Width(), size.Height(), state.test(IShellSurface::STATE_FULLSCREEN));

  // Check if this is a resolution change
  CSizeInt currentSize = GetBufferSize();
  if (currentSize.Width() != size.Width() || currentSize.Height() != size.Height())
  {
    CLog::LogF(LOGINFO, "Resolution change detected: {}x{} -> {}x{}", currentSize.Width(),
               currentSize.Height(), size.Width(), size.Height());
  }

  // Forward to base class for standard handling
  // This will update the rendering surface dimensions
  CWinSystemWayland::OnConfigure(serial, size, state);

  CLog::LogF(LOGDEBUG, "OnConfigure completed - surface updated to {}x{}", size.Width(),
             size.Height());
}

void CWinSystemWaylandTizen::UpdateResolutions()
{
  CLog::LogF(LOGDEBUG, "Querying Tizen display modes");

  // Call base class to query Wayland outputs and populate resolutions
  CWinSystemWayland::UpdateResolutions();

  // Get the desktop resolution that was detected
  RESOLUTION_INFO& res = CDisplaySettings::GetInstance().GetResolutionInfo(RES_DESKTOP);

  // Tizen reports accurate resolutions through Wayland, no adjustment needed
  // (unlike webOS which always reports 1080p for GUI even on 4K devices)
  CLog::LogF(LOGINFO, "Tizen display resolution: {}x{} @ {:.2f}Hz", res.iWidth, res.iHeight,
             res.fRefreshRate);

  // Log additional display information for debugging
  CLog::LogF(LOGDEBUG, "Display details - Screen: {}x{}, Pixel ratio: {:.2f}, Subtitle height: {}",
             res.iScreenWidth, res.iScreenHeight, res.fPixelRatio, res.iSubtitles);

  // Verify we have valid resolution data
  if (res.iWidth <= 0 || res.iHeight <= 0)
  {
    CLog::LogF(LOGERROR, "Invalid resolution detected: {}x{}", res.iWidth, res.iHeight);
  }
}

float CWinSystemWaylandTizen::GetGuiSdrPeakLuminance() const
{
  // Get SDR peak luminance setting for GUI rendering
  const auto settings = CServiceBroker::GetSettingsComponent()->GetSettings();
  const int guiSdrPeak = settings->GetInt(CSettings::SETTING_VIDEOSCREEN_GUISDRPEAKLUMINANCE);

  // Apply scaling formula (same as webOS)
  return (0.7f * guiSdrPeak + 30.0f) / 100.0f;
}

bool CWinSystemWaylandTizen::IsHDRDisplay()
{
  return m_supportsHDR;
}

std::unique_ptr<KODI::WINDOWING::IOSScreenSaver> CWinSystemWaylandTizen::GetOSScreenSaverImpl()
{
  // Use Tizen-specific screen saver implementation with device_power API
  auto screenSaver = std::make_unique<COSScreenSaverTizen>();
  CLog::LogF(LOGINFO, "Using Tizen device_power API for screen saver inhibition");
  return screenSaver;
}

std::unique_ptr<CSeat> CWinSystemWaylandTizen::CreateSeat(std::uint32_t name,
                                                          wayland::seat_t& seat)
{
  // Use Tizen-specific seat implementation for remote control input handling
  CLog::LogF(LOGINFO, "Creating Tizen seat for remote control input");
  return std::make_unique<CSeatTizen>(name, seat, *GetConnection());
}

bool CWinSystemWaylandTizen::InitializeTizenDisplay()
{
  // Initialize Tizen-specific display features if needed
  // This is a placeholder for future Tizen-specific display initialization
  return true;
}

bool CWinSystemWaylandTizen::QueryDisplayCapabilities()
{
  // Query HDR capabilities from Tizen
  // Initialize with conservative defaults
  m_supportsHDR = false;
  m_peakLuminance = 100.0f; // Standard SDR peak luminance in nits

#if defined(TARGET_TIZEN)
  // Try to detect HDR support through Tizen system_info API
  // Note: Tizen doesn't have a specific "HDR" feature key in system_info,
  // so we use indirect indicators and platform knowledge
  
  bool hasHighResDisplay = false;
  bool hasModernPlatform = false;
  
  // Check for 4K display support (most 4K Samsung TVs support HDR)
  int ret = system_info_get_platform_bool("http://tizen.org/feature/screen.size.normal.1080.1920", 
                                          &hasHighResDisplay);
  if (ret == SYSTEM_INFO_ERROR_NONE && hasHighResDisplay)
  {
    CLog::LogF(LOGDEBUG, "Detected high resolution display (1080p+)");
  }
  
  // Check for modern OpenGL ES support (indicator of newer hardware)
  bool hasGLES3 = false;
  ret = system_info_get_platform_bool("http://tizen.org/feature/opengles.version.3_0", &hasGLES3);
  if (ret == SYSTEM_INFO_ERROR_NONE && hasGLES3)
  {
    hasModernPlatform = true;
    CLog::LogF(LOGDEBUG, "Detected OpenGL ES 3.0+ support");
  }
  
  // Get platform version to determine TV generation
  char* platformVersion = nullptr;
  ret = system_info_get_platform_string("http://tizen.org/feature/platform.version", 
                                        &platformVersion);
  if (ret == SYSTEM_INFO_ERROR_NONE && platformVersion != nullptr)
  {
    std::string version(platformVersion);
    free(platformVersion);
    
    CLog::LogF(LOGINFO, "Tizen platform version: {}", version);
    
    // Parse version (format: "Major.Minor.Patch")
    // Tizen 3.0+ (2017+ Samsung TVs) generally support HDR10
    // Tizen 4.0+ (2018+ Samsung TVs) have better HDR support
    // Tizen 5.0+ (2019+ Samsung TVs) support HDR10+
    if (!version.empty())
    {
      int majorVersion = 0;
      try
      {
        size_t dotPos = version.find('.');
        if (dotPos != std::string::npos)
        {
          majorVersion = std::stoi(version.substr(0, dotPos));
        }
      }
      catch (...)
      {
        CLog::LogF(LOGWARNING, "Failed to parse platform version: {}", version);
      }
      
      // Tizen 3.0+ on Samsung TVs typically support HDR
      if (majorVersion >= 3)
      {
        hasModernPlatform = true;
        CLog::LogF(LOGINFO, "Detected Tizen {} - HDR capable platform", majorVersion);
      }
    }
  }
  
  // Check for TV profile (Samsung Smart TVs use tv-samsung profile)
  char* profile = nullptr;
  ret = system_info_get_platform_string("http://tizen.org/feature/profile", &profile);
  if (ret == SYSTEM_INFO_ERROR_NONE && profile != nullptr)
  {
    std::string profileStr(profile);
    free(profile);
    
    CLog::LogF(LOGDEBUG, "Tizen profile: {}", profileStr);
    
    // TV profile indicates this is a Smart TV
    if (profileStr.find("tv") != std::string::npos || 
        profileStr.find("TV") != std::string::npos)
    {
      CLog::LogF(LOGINFO, "Detected TV profile");
      
      // Modern Samsung Smart TVs (Tizen 3.0+) support HDR
      if (hasModernPlatform)
      {
        m_supportsHDR = true;
        m_peakLuminance = 1000.0f; // Typical HDR10 peak for mid-range TVs
        CLog::LogF(LOGINFO, "HDR support enabled based on platform capabilities");
      }
    }
  }
  
  // Additional check: Try to detect HDR through display output capabilities
  // Check for HDMI output support (HDR requires HDMI 2.0a+)
  bool hasHDMI = false;
  ret = system_info_get_platform_bool("http://tizen.org/feature/screen.output.hdmi", &hasHDMI);
  if (ret == SYSTEM_INFO_ERROR_NONE && hasHDMI)
  {
    CLog::LogF(LOGDEBUG, "HDMI output detected");
  }
  
#else
  CLog::LogF(LOGWARNING, "Not compiled for Tizen target, using default values");
#endif

  CLog::LogF(LOGINFO, "Display capabilities - HDR: {}, Peak luminance: {} nits",
             m_supportsHDR ? "yes" : "no", m_peakLuminance);

  return true;
}

} // namespace WAYLAND
} // namespace WINDOWING
} // namespace KODI
