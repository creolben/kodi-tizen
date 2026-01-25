/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "TizenPowerManagement.h"

#include "utils/log.h"

#if defined(TARGET_TIZEN)
#include <device/power.h>
#endif

CTizenPowerManagement::CTizenPowerManagement() : m_displayLockActive(false)
{
}

CTizenPowerManagement::~CTizenPowerManagement()
{
  // Release any active display locks
  if (m_displayLockActive)
  {
    ReleaseDisplayLock();
  }
}

bool CTizenPowerManagement::Powerdown()
{
#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CTizenPowerManagement: Requesting system powerdown");
  
  // Use device_power_reboot with "poweroff" reason to shutdown
  int ret = device_power_reboot("poweroff");
  
  if (ret != 0)
  {
    CLog::Log(LOGERROR, "CTizenPowerManagement: Failed to powerdown, error: {}", ret);
    return false;
  }
  
  return true;
#else
  return false;
#endif
}

bool CTizenPowerManagement::Reboot()
{
#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CTizenPowerManagement: Requesting system reboot");
  
  // Use device_power_reboot with "reboot" reason
  int ret = device_power_reboot("reboot");
  
  if (ret != 0)
  {
    CLog::Log(LOGERROR, "CTizenPowerManagement: Failed to reboot, error: {}", ret);
    return false;
  }
  
  return true;
#else
  return false;
#endif
}

bool CTizenPowerManagement::PumpPowerEvents(IPowerEventsCallback* callback)
{
  // Tizen handles power events through the application lifecycle callbacks
  // registered in CPlatformTizen, so we don't need to pump events here.
  // This method is called periodically to handle screen saver inhibition.
  
  // The display lock is managed by Kodi's screen saver system through
  // the OSScreenSaverTizen implementation, so we just return true here.
  return true;
}

bool CTizenPowerManagement::RequestDisplayLock()
{
#if defined(TARGET_TIZEN)
  if (m_displayLockActive)
  {
    CLog::Log(LOGDEBUG, "CTizenPowerManagement: Display lock already active");
    return true;
  }
  
  // Request a display lock to prevent screen dimming/turning off
  // Use POWER_LOCK_DISPLAY to keep the display on at normal brightness
  // Timeout of 0 means permanent lock until explicitly released
  int ret = device_power_request_lock(POWER_LOCK_DISPLAY, 0);
  
  if (ret != 0)
  {
    CLog::Log(LOGERROR, "CTizenPowerManagement: Failed to request display lock, error: {}", ret);
    return false;
  }
  
  m_displayLockActive = true;
  CLog::Log(LOGDEBUG, "CTizenPowerManagement: Display lock requested successfully");
  return true;
#else
  return false;
#endif
}

bool CTizenPowerManagement::ReleaseDisplayLock()
{
#if defined(TARGET_TIZEN)
  if (!m_displayLockActive)
  {
    CLog::Log(LOGDEBUG, "CTizenPowerManagement: No active display lock to release");
    return true;
  }
  
  // Release the display lock
  int ret = device_power_release_lock(POWER_LOCK_DISPLAY);
  
  if (ret != 0)
  {
    CLog::Log(LOGERROR, "CTizenPowerManagement: Failed to release display lock, error: {}", ret);
    return false;
  }
  
  m_displayLockActive = false;
  CLog::Log(LOGDEBUG, "CTizenPowerManagement: Display lock released successfully");
  return true;
#else
  return false;
#endif
}

IPowerSyscall* CTizenPowerManagement::CreateInstance()
{
  return new CTizenPowerManagement();
}

void CTizenPowerManagement::Register()
{
  RegisterPowerSyscall(CreateInstance);
}
