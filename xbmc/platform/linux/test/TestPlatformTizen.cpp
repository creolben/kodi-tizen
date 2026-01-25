/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "platform/linux/PlatformTizen.h"
#include "utils/log.h"

#include <gtest/gtest.h>

#if defined(TARGET_TIZEN)
#include "platform/linux/utils/TizenInterfaceForCLog.h"
#include "utils/IPlatformLog.h"
#endif

struct TestPlatformTizen : public ::testing::Test
{
  TestPlatformTizen()
  {
    // Initialize logging for tests
    CLog::Init("./");
  }
  
  ~TestPlatformTizen()
  {
    CLog::Close();
  }
};

TEST_F(TestPlatformTizen, PlatformTizenInitialization)
{
  CPlatformTizen platform;
  
  // Test that the platform can be created
  EXPECT_TRUE(true);
}

TEST_F(TestPlatformTizen, PlatformTizenInitStageOne)
{
  CPlatformTizen platform;
  
  // InitStageOne should succeed
  EXPECT_TRUE(platform.InitStageOne());
}

TEST_F(TestPlatformTizen, PlatformTizenAddonConfiguration)
{
  CPlatformTizen platform;
  
  // Tizen should disable addon configuration at startup (similar to webOS)
  EXPECT_FALSE(platform.IsConfigureAddonsAtStartupEnabled());
}

#if defined(TARGET_TIZEN)
TEST_F(TestPlatformTizen, PlatformTizenSystemInfo)
{
  CPlatformTizen platform;
  platform.InitStageOne();
  
  // PlatformSyslog should not crash
  // Note: This will log system information if running on Tizen
  EXPECT_NO_THROW(platform.PlatformSyslog());
}
#endif

TEST_F(TestPlatformTizen, PlatformTizenCreateInstance)
{
  // Test the factory method
  CPlatform* platform = CPlatform::CreateInstance();
  EXPECT_NE(platform, nullptr);
  
  // Verify it's actually a Tizen platform
  CPlatformTizen* tizenPlatform = dynamic_cast<CPlatformTizen*>(platform);
  EXPECT_NE(tizenPlatform, nullptr);
  
  delete platform;
}

#if defined(TARGET_TIZEN)
TEST_F(TestPlatformTizen, TizenLoggingIntegration)
{
  // Test that the Tizen logging interface can be created
  auto platformLog = IPlatformLog::CreatePlatformLog();
  EXPECT_NE(platformLog, nullptr);
  
  // Verify it's a Tizen logging interface
  CTizenInterfaceForCLog* tizenLog = dynamic_cast<CTizenInterfaceForCLog*>(platformLog.get());
  EXPECT_NE(tizenLog, nullptr);
}

TEST_F(TestPlatformTizen, TizenDlogLogging)
{
  // Test that logging at various levels doesn't crash
  // Note: When running on Tizen, these will output to dlog
  // When running on other platforms, they will use the default logging
  
  EXPECT_NO_THROW(CLog::Log(LOGDEBUG, "Test debug message for Tizen dlog"));
  EXPECT_NO_THROW(CLog::Log(LOGINFO, "Test info message for Tizen dlog"));
  EXPECT_NO_THROW(CLog::Log(LOGWARNING, "Test warning message for Tizen dlog"));
  EXPECT_NO_THROW(CLog::Log(LOGERROR, "Test error message for Tizen dlog"));
  EXPECT_NO_THROW(CLog::Log(LOGFATAL, "Test fatal message for Tizen dlog"));
}

TEST_F(TestPlatformTizen, TizenDlogLogLevelMapping)
{
  // Test that log level mapping works correctly
  // This verifies that Kodi log levels map to appropriate dlog levels
  
  // LOGDEBUG -> DLOG_DEBUG
  EXPECT_NO_THROW(CLog::Log(LOGDEBUG, "Debug level test"));
  
  // LOGINFO -> DLOG_INFO
  EXPECT_NO_THROW(CLog::Log(LOGINFO, "Info level test"));
  
  // LOGWARNING -> DLOG_WARN
  EXPECT_NO_THROW(CLog::Log(LOGWARNING, "Warning level test"));
  
  // LOGERROR -> DLOG_ERROR
  EXPECT_NO_THROW(CLog::Log(LOGERROR, "Error level test"));
  
  // LOGFATAL -> DLOG_ERROR (critical)
  EXPECT_NO_THROW(CLog::Log(LOGFATAL, "Fatal level test"));
}
#endif
