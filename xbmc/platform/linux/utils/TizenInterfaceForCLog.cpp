/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "TizenInterfaceForCLog.h"

#include "CompileInfo.h"
#include "DlogSink.h"

#include <spdlog/sinks/dist_sink.h>

#if defined(TARGET_TIZEN)
std::unique_ptr<IPlatformLog> IPlatformLog::CreatePlatformLog()
{
  return std::make_unique<CTizenInterfaceForCLog>();
}
#endif

void CTizenInterfaceForCLog::AddSinks(
    std::shared_ptr<spdlog::sinks::dist_sink<std::mutex>> distributionSink) const
{
  // Add the dlog sink for Tizen logging
  // Use single-threaded sink (_st) as the distribution sink already handles thread safety
  distributionSink->add_sink(
      std::make_shared<spdlog::sinks::dlog_sink_st>(CCompileInfo::GetAppName()));
}
