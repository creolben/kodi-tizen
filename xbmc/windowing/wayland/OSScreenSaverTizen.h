/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "windowing/OSScreenSaver.h"

namespace KODI::WINDOWING::WAYLAND
{

/**
 * Tizen screen saver inhibitor implementation
 * 
 * Uses Tizen's device_power API to prevent the screen from dimming or turning off.
 * The implementation uses POWER_LOCK_DISPLAY to keep the display active at normal
 * brightness during media playback or other activities that require the screen to
 * remain on.
 */
class COSScreenSaverTizen : public IOSScreenSaver
{
public:
  COSScreenSaverTizen() = default;
  ~COSScreenSaverTizen() override;

  /**
   * Inhibit the screen saver by requesting a display power lock
   * 
   * This prevents the TV screen from dimming or turning off. Multiple calls
   * to Inhibit() without Uninhibit() are safe and will not produce side effects.
   */
  void Inhibit() override;

  /**
   * Allow the screen saver to become active by releasing the display power lock
   * 
   * Multiple calls to Uninhibit() are safe and will not produce side effects.
   */
  void Uninhibit() override;

private:
  bool m_inhibited{false};
};

} // namespace KODI::WINDOWING::WAYLAND
