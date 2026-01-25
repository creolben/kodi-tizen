/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "Seat.h"

namespace KODI::WINDOWING::WAYLAND
{

/**
 * Tizen-specific seat implementation for Samsung TV remote control input
 * 
 * This class customizes input handling for Samsung TV remote controls by:
 * - Disabling cursor (TV platforms don't have cursors)
 * - Disabling automatic key repeat (Kodi handles this internally)
 * 
 * The actual key mapping from Linux input event codes to XBMC key symbols
 * is handled by the standard xkbcommon library, which properly supports
 * all standard remote control keys (navigation, playback, etc.).
 * 
 * Volume keys are typically handled by the Tizen system and don't reach
 * the application level.
 */
class CSeatTizen final : public CSeat
{
public:
  CSeatTizen(std::uint32_t globalName, wayland::seat_t const& seat, CConnection& connection);

  void SetCursor(std::uint32_t serial,
                 wayland::surface_t const& surface,
                 std::int32_t hotspotX,
                 std::int32_t hotspotY) override;

protected:
  void InstallKeyboardRepeatInfo() override;
};

} // namespace KODI::WINDOWING::WAYLAND
