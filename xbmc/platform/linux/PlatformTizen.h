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
  
  // Storage space monitoring (Task 9.2)
  bool CheckStorageSpace();
  bool GetStorageInfo(unsigned long long& total, unsigned long long& available);
  
  // Network connectivity support (Task 10)
  bool InitializeNetworkMonitoring();
  void ShutdownNetworkMonitoring();
  bool IsNetworkConnected();
  std::string GetNetworkType();
  
  // POSIX networking verification (Task 10.2)
  bool VerifyPOSIXNetworking();
  bool TestDNSResolution(const std::string& hostname);
  
  // Wi-Fi information queries (Task 10.3)
  bool GetWiFiInfo(std::string& ssid, std::string& ipAddress, int& signalStrength);
  bool IsWiFiConnected();

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
  
  // Network connectivity callbacks (Task 10.1)
  static void OnNetworkConnectionChanged(connection_type_e type, void* userData);
  void HandleNetworkChange(connection_type_e type);
  
#if defined(TARGET_TIZEN)
  // Tizen-specific members for lifecycle handler references
  app_event_handler_h m_suspendedHandler;
  app_event_handler_h m_lowMemoryHandler;
  
  // Network monitoring members (Task 10.1)
  connection_h m_connectionHandle;
  bool m_networkConnected;
  connection_type_e m_networkType;
#endif
};
