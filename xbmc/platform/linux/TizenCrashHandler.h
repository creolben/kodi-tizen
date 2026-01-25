/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include <string>

/**
 * @brief Tizen Crash Handler
 * 
 * This class provides crash logging functionality for Kodi on Tizen.
 * It installs signal handlers for fatal signals (SIGSEGV, SIGABRT, etc.)
 * and generates crash logs that can be accessed via SDB.
 * 
 * Crash logs are written to:
 * - dlog (accessible via: sdb dlog KODI:F)
 * - File: /opt/usr/home/owner/apps_rw/org.xbmc.kodi/data/crash_YYYYMMDD_HHMMSS.log
 * 
 * Usage:
 *   CTizenCrashHandler::Install();  // Call during platform initialization
 */
class CTizenCrashHandler
{
public:
  /**
   * @brief Install crash handlers for fatal signals
   * @return true if handlers were installed successfully
   */
  static bool Install();
  
  /**
   * @brief Uninstall crash handlers (restore default handlers)
   */
  static void Uninstall();
  
  /**
   * @brief Check if crash handlers are installed
   * @return true if handlers are currently installed
   */
  static bool IsInstalled();
  
  /**
   * @brief Get the path where crash logs are stored
   * @return Path to crash log directory
   */
  static std::string GetCrashLogPath();
  
private:
  // Signal handler function
  static void SignalHandler(int signal, siginfo_t* info, void* context);
  
  // Generate crash log
  static void GenerateCrashLog(int signal, siginfo_t* info, void* context);
  
  // Get signal name from signal number
  static const char* GetSignalName(int signal);
  
  // Get signal description
  static const char* GetSignalDescription(int signal);
  
  // Write crash log to file
  static bool WriteCrashLogToFile(const std::string& logContent);
  
  // Generate backtrace (if available)
  static std::string GenerateBacktrace();
  
  // Flag to track if handlers are installed
  static bool s_installed;
  
  // Original signal handlers (for restoration)
  static struct sigaction s_oldHandlers[6];
};
