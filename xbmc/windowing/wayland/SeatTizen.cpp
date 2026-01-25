/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "SeatTizen.h"

#include "utils/log.h"

namespace KODI::WINDOWING::WAYLAND
{

CSeatTizen::CSeatTizen(std::uint32_t globalName,
                       wayland::seat_t const& seat,
                       CConnection& connection)
  : CSeat(globalName, seat, connection)
{
  CLog::LogF(LOGINFO, "Tizen seat created for Samsung TV remote control input");
  CLog::LogF(LOGINFO,
             "Remote control keys (navigation, playback, etc.) are mapped by xkbcommon library");
  CLog::LogF(LOGINFO, "Volume keys are handled by Tizen system");
}

void CSeatTizen::SetCursor(std::uint32_t serial,
                           wayland::surface_t const& surface,
                           std::int32_t hotspotX,
                           std::int32_t hotspotY)
{
  // TV platforms don't have a cursor, so don't set it
  // Setting cursor on Tizen may cause issues similar to webOS
  CLog::LogF(LOGDEBUG, "SetCursor called but ignored on Tizen TV platform");
}

void CSeatTizen::InstallKeyboardRepeatInfo()
{
  // Tizen may send key repeat info that's too fast for TV remote control
  // We'll let Kodi handle key repeat internally instead
  // This prevents issues with long-press detection on remote control buttons
  CLog::LogF(LOGDEBUG, "Key repeat info installation skipped for Tizen remote control");
}

} // namespace KODI::WINDOWING::WAYLAND
