/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "TizenCrashHandler.h"

#include "utils/log.h"

#include <chrono>
#include <cstring>
#include <ctime>
#include <fstream>
#include <iomanip>
#include <sstream>

#include <csignal>
#include <execinfo.h>
#include <unistd.h>

#if defined(TARGET_TIZEN)
#include <app_common.h>
#include <dlog.h>
#endif

// Static member initialization
bool CTizenCrashHandler::s_installed = false;
struct sigaction CTizenCrashHandler::s_oldHandlers[6];

bool CTizenCrashHandler::Install()
{
  if (s_installed)
  {
    CLog::Log(LOGWARNING, "CTizenCrashHandler: Handlers already installed");
    return true;
  }
  
  // Set up signal handler structure
  struct sigaction sa;
  std::memset(&sa, 0, sizeof(sa));
  sa.sa_sigaction = SignalHandler;
  sa.sa_flags = SA_SIGINFO | SA_RESTART;
  sigemptyset(&sa.sa_mask);
  
  // Install handlers for fatal signals
  const int signals[] = {
    SIGSEGV,  // Segmentation fault
    SIGABRT,  // Abort signal
    SIGFPE,   // Floating point exception
    SIGILL,   // Illegal instruction
    SIGBUS,   // Bus error
    SIGSYS    // Bad system call
  };
  
  bool success = true;
  for (size_t i = 0; i < sizeof(signals) / sizeof(signals[0]); ++i)
  {
    if (sigaction(signals[i], &sa, &s_oldHandlers[i]) != 0)
    {
      CLog::Log(LOGERROR, "CTizenCrashHandler: Failed to install handler for signal {}",
                signals[i]);
      success = false;
    }
  }
  
  if (success)
  {
    s_installed = true;
    CLog::Log(LOGINFO, "CTizenCrashHandler: Crash handlers installed successfully");
    
#if defined(TARGET_TIZEN)
    dlog_print(DLOG_INFO, "KODI", "Crash handlers installed - logs will be written to dlog and file");
#endif
  }
  
  return success;
}

void CTizenCrashHandler::Uninstall()
{
  if (!s_installed)
    return;
  
  // Restore original signal handlers
  const int signals[] = {SIGSEGV, SIGABRT, SIGFPE, SIGILL, SIGBUS, SIGSYS};
  
  for (size_t i = 0; i < sizeof(signals) / sizeof(signals[0]); ++i)
  {
    sigaction(signals[i], &s_oldHandlers[i], nullptr);
  }
  
  s_installed = false;
  CLog::Log(LOGINFO, "CTizenCrashHandler: Crash handlers uninstalled");
}

bool CTizenCrashHandler::IsInstalled()
{
  return s_installed;
}

std::string CTizenCrashHandler::GetCrashLogPath()
{
#if defined(TARGET_TIZEN)
  char* dataPath = nullptr;
  int ret = app_get_data_path(&dataPath);
  
  if (ret == APP_ERROR_NONE && dataPath != nullptr)
  {
    std::string path(dataPath);
    free(dataPath);
    return path;
  }
#endif
  
  // Fallback
  return "/tmp/";
}

void CTizenCrashHandler::SignalHandler(int signal, siginfo_t* info, void* context)
{
  // Generate crash log
  GenerateCrashLog(signal, info, context);
  
  // Restore default handler and re-raise signal
  // This ensures the process terminates properly
  struct sigaction sa;
  std::memset(&sa, 0, sizeof(sa));
  sa.sa_handler = SIG_DFL;
  sigaction(signal, &sa, nullptr);
  raise(signal);
}

void CTizenCrashHandler::GenerateCrashLog(int signal, siginfo_t* info, void* context)
{
  // Build crash log content
  std::ostringstream log;
  
  log << "========================================\n";
  log << "Kodi Crash Report\n";
  log << "========================================\n\n";
  
  // Timestamp
  auto now = std::chrono::system_clock::now();
  auto time = std::chrono::system_clock::to_time_t(now);
  log << "Time: " << std::put_time(std::localtime(&time), "%Y-%m-%d %H:%M:%S") << "\n\n";
  
  // Signal information
  log << "Signal: " << signal << " (" << GetSignalName(signal) << ")\n";
  log << "Description: " << GetSignalDescription(signal) << "\n";
  
  if (info)
  {
    log << "Signal code: " << info->si_code << "\n";
    log << "Fault address: " << info->si_addr << "\n";
    log << "Sending PID: " << info->si_pid << "\n";
  }
  
  log << "\n";
  
  // Process information
  log << "Process ID: " << getpid() << "\n";
  log << "Thread ID: " << gettid() << "\n\n";
  
  // Backtrace
  std::string backtrace = GenerateBacktrace();
  if (!backtrace.empty())
  {
    log << "Backtrace:\n";
    log << backtrace << "\n";
  }
  else
  {
    log << "Backtrace: Not available\n\n";
  }
  
  log << "========================================\n";
  log << "End of crash report\n";
  log << "========================================\n";
  
  std::string logContent = log.str();
  
  // Write to dlog (Tizen system log)
#if defined(TARGET_TIZEN)
  dlog_print(DLOG_FATAL, "KODI", "=== CRASH DETECTED ===");
  dlog_print(DLOG_FATAL, "KODI", "Signal: %d (%s)", signal, GetSignalName(signal));
  dlog_print(DLOG_FATAL, "KODI", "Description: %s", GetSignalDescription(signal));
  
  if (info)
  {
    dlog_print(DLOG_FATAL, "KODI", "Fault address: %p", info->si_addr);
  }
  
  dlog_print(DLOG_FATAL, "KODI", "Process ID: %d", getpid());
  dlog_print(DLOG_FATAL, "KODI", "Thread ID: %d", gettid());
  
  if (!backtrace.empty())
  {
    dlog_print(DLOG_FATAL, "KODI", "Backtrace available in crash log file");
  }
  
  dlog_print(DLOG_FATAL, "KODI", "=== END CRASH REPORT ===");
#endif
  
  // Write to file
  if (WriteCrashLogToFile(logContent))
  {
#if defined(TARGET_TIZEN)
    dlog_print(DLOG_FATAL, "KODI", "Crash log written to: %s", GetCrashLogPath().c_str());
#endif
  }
  
  // Also try to write to stderr (may be captured by system)
  std::cerr << logContent << std::endl;
}

const char* CTizenCrashHandler::GetSignalName(int signal)
{
  switch (signal)
  {
    case SIGSEGV:
      return "SIGSEGV";
    case SIGABRT:
      return "SIGABRT";
    case SIGFPE:
      return "SIGFPE";
    case SIGILL:
      return "SIGILL";
    case SIGBUS:
      return "SIGBUS";
    case SIGSYS:
      return "SIGSYS";
    default:
      return "UNKNOWN";
  }
}

const char* CTizenCrashHandler::GetSignalDescription(int signal)
{
  switch (signal)
  {
    case SIGSEGV:
      return "Segmentation fault (invalid memory access)";
    case SIGABRT:
      return "Abort signal (abnormal termination)";
    case SIGFPE:
      return "Floating point exception";
    case SIGILL:
      return "Illegal instruction";
    case SIGBUS:
      return "Bus error (invalid memory alignment)";
    case SIGSYS:
      return "Bad system call";
    default:
      return "Unknown signal";
  }
}

bool CTizenCrashHandler::WriteCrashLogToFile(const std::string& logContent)
{
  try
  {
    // Generate filename with timestamp
    auto now = std::chrono::system_clock::now();
    auto time = std::chrono::system_clock::to_time_t(now);
    
    std::ostringstream filename;
    filename << GetCrashLogPath();
    filename << "crash_";
    filename << std::put_time(std::localtime(&time), "%Y%m%d_%H%M%S");
    filename << ".log";
    
    // Write to file
    std::ofstream file(filename.str(), std::ios::out | std::ios::trunc);
    if (!file.is_open())
    {
#if defined(TARGET_TIZEN)
      dlog_print(DLOG_ERROR, "KODI", "Failed to open crash log file: %s", filename.str().c_str());
#endif
      return false;
    }
    
    file << logContent;
    file.close();
    
    return true;
  }
  catch (...)
  {
#if defined(TARGET_TIZEN)
    dlog_print(DLOG_ERROR, "KODI", "Exception while writing crash log file");
#endif
    return false;
  }
}

std::string CTizenCrashHandler::GenerateBacktrace()
{
  std::ostringstream backtrace;
  
  // Get backtrace
  const int maxFrames = 50;
  void* buffer[maxFrames];
  int frameCount = backtrace_symbols_fd(buffer, maxFrames, STDERR_FILENO);
  
  if (frameCount <= 0)
  {
    return "";
  }
  
  // Get symbol names
  char** symbols = backtrace_symbols(buffer, frameCount);
  if (symbols == nullptr)
  {
    return "";
  }
  
  // Format backtrace
  for (int i = 0; i < frameCount; ++i)
  {
    backtrace << "  #" << i << ": " << symbols[i] << "\n";
  }
  
  free(symbols);
  
  return backtrace.str();
}
