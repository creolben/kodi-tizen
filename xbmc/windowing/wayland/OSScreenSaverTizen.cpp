/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "OSScreenSaverTizen.h"

#include "utils/log.h"

#if defined(TARGET_TIZEN)
#include <device/power.h>
#endif

namespace KODI::WINDOWING::WAYLAND
{

COSScreenSaverTizen::~COSScreenSaverTizen()
{
  // Ensure we release the lock on destruction
  if (m_inhibited)
  {
    Uninhibit();
  }
}

void COSScreenSaverTizen::Inhibit()
{
#if defined(TARGET_TIZEN)
  // If already inhibited, don't request the lock again
  if (m_inhibited)
  {
    CLog::LogF(LOGDEBUG, "Screen saver already inhibited");
    return;
  }

  // Request a display power lock to prevent screen dimming/turning off
  // POWER_LOCK_DISPLAY keeps the display on at normal brightness
  // Timeout of 0 means the lock is permanent until explicitly released
  int ret = device_power_request_lock(POWER_LOCK_DISPLAY, 0);

  if (ret != 0)
  {
    CLog::LogF(LOGERROR, "Failed to request display power lock, error: {}", ret);
    return;
  }

  m_inhibited = true;
  CLog::LogF(LOGDEBUG, "Screen saver inhibited - display power lock acquired");
#else
  CLog::LogF(LOGWARNING, "Screen saver inhibition not available (not compiled for Tizen)");
#endif
}

void COSScreenSaverTizen::Uninhibit()
{
#if defined(TARGET_TIZEN)
  // If not inhibited, nothing to release
  if (!m_inhibited)
  {
    CLog::LogF(LOGDEBUG, "Screen saver not inhibited, nothing to release");
    return;
  }

  // Release the display power lock
  int ret = device_power_release_lock(POWER_LOCK_DISPLAY);

  if (ret != 0)
  {
    CLog::LogF(LOGERROR, "Failed to release display power lock, error: {}", ret);
    // Still mark as not inhibited to avoid repeated failed release attempts
  }

  m_inhibited = false;
  CLog::LogF(LOGDEBUG, "Screen saver uninhibited - display power lock released");
#else
  CLog::LogF(LOGWARNING, "Screen saver uninhibition not available (not compiled for Tizen)");
#endif
}

} // namespace KODI::WINDOWING::WAYLAND
