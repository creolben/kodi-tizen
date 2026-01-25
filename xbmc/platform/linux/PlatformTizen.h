/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "PlatformLinux.h"

class CPlatformTizen : public CPlatformLinux
{
public:
  CPlatformTizen();
  ~CPlatformTizen() override;
  
  bool InitStageOne() override;
  bool InitStageTwo() override;
  bool InitStageThree() override;
  static CPlatform* CreateInstance();

protected:
  void RegisterPowerManagement() override;

public:
  bool IsConfigureAddonsAtStartupEnabled() override;
  void PlatformSyslog() override;

private:
  std::string GetHomePath();
  bool RegisterAppLifecycleCallbacks();
  void UnregisterAppLifecycleCallbacks();
  
  // System information query methods
  std::string GetCPUInfo();
  std::string GetGPUInfo();
  std::string GetMemoryInfo();
  
  // Tizen lifecycle callback handlers
  static void OnAppSuspendedStateChanged(app_event_info_h event_info, void* userData);
  static void OnAppLowMemory(app_event_info_h event_info, void* userData);
  void OnAppPause();
  void OnAppResume();
  
#if defined(TARGET_TIZEN)
  // Tizen-specific members for lifecycle handler references
  app_event_handler_h m_suspendedHandler;
  app_event_handler_h m_lowMemoryHandler;
#endif
};
