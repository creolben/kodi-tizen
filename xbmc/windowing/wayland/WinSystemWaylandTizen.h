/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "Registry.h"
#include "WinSystemWayland.h"

namespace KODI
{
namespace WINDOWING
{
namespace WAYLAND
{

class CWinSystemWaylandTizen : public CWinSystemWayland
{
public:
  bool InitWindowSystem() override;
  bool DestroyWindowSystem() override;

  IShellSurface* CreateShellSurface(const std::string& name) override;
  bool CreateNewWindow(const std::string& name,
                       bool fullScreen,
                       RESOLUTION_INFO& res) override;
  bool HasCursor() override;
  void OnConfigure(std::uint32_t serial,
                   CSizeInt size,
                   IShellSurface::StateBitset state) override;
  void UpdateResolutions() override;

  float GetGuiSdrPeakLuminance() const override;
  bool IsHDRDisplay() override;

protected:
  std::unique_ptr<KODI::WINDOWING::IOSScreenSaver> GetOSScreenSaverImpl() override;
  std::unique_ptr<CSeat> CreateSeat(std::uint32_t name, wayland::seat_t& seat) override;

private:
  bool InitializeTizenDisplay();
  bool QueryDisplayCapabilities();

  std::unique_ptr<CRegistry> m_tizenRegistry;
  bool m_supportsHDR{false};
  float m_peakLuminance{100.0f};
};

} // namespace WAYLAND
} // namespace WINDOWING
} // namespace KODI
