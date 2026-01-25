/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include <dlog.h>
#include <spdlog/details/null_mutex.h>
#include <spdlog/sinks/base_sink.h>

#include <mutex>
#include <string>

namespace spdlog
{
namespace sinks
{

/**
 * @brief Custom spdlog sink that outputs to Tizen's dlog system
 * 
 * This sink integrates Kodi's logging with Tizen's native dlog logging system,
 * allowing logs to be viewed via SDB (Smart Development Bridge) using:
 *   sdb dlog KODI:V
 * 
 * Log level mapping:
 *   SPDLOG_LEVEL_TRACE   -> DLOG_DEBUG
 *   SPDLOG_LEVEL_DEBUG   -> DLOG_DEBUG
 *   SPDLOG_LEVEL_INFO    -> DLOG_INFO
 *   SPDLOG_LEVEL_WARN    -> DLOG_WARN
 *   SPDLOG_LEVEL_ERROR   -> DLOG_ERROR
 *   SPDLOG_LEVEL_CRITICAL-> DLOG_ERROR
 */
template<typename Mutex>
class dlog_sink : public base_sink<Mutex>
{
public:
  explicit dlog_sink(std::string tag = "KODI") : m_tag(std::move(tag)) {}

protected:
  void sink_it_(const details::log_msg& msg) override
  {
    // Format the message
    memory_buf_t formatted;
    base_sink<Mutex>::formatter_->format(msg, formatted);
    std::string message = fmt::to_string(formatted);
    
    // Remove trailing newline if present (dlog adds its own)
    if (!message.empty() && message.back() == '\n')
      message.pop_back();
    
    // Map spdlog level to dlog level and output
    log_priority priority = map_level(msg.level);
    dlog_print(priority, m_tag.c_str(), "%s", message.c_str());
  }

  void flush_() override
  {
    // dlog doesn't require explicit flushing
  }

private:
  /**
   * @brief Map spdlog log level to dlog priority
   * 
   * @param level spdlog log level
   * @return log_priority corresponding dlog priority
   */
  log_priority map_level(level::level_enum level)
  {
    switch (level)
    {
      case level::trace:
      case level::debug:
        return DLOG_DEBUG;
      case level::info:
        return DLOG_INFO;
      case level::warn:
        return DLOG_WARN;
      case level::err:
      case level::critical:
        return DLOG_ERROR;
      default:
        return DLOG_INFO;
    }
  }

  std::string m_tag;
};

// Single-threaded dlog sink
using dlog_sink_st = dlog_sink<details::null_mutex>;

// Multi-threaded dlog sink
using dlog_sink_mt = dlog_sink<std::mutex>;

} // namespace sinks
} // namespace spdlog
