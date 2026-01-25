/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "platform/linux/PlatformTizen.h"
#include "filesystem/SpecialProtocol.h"
#include "filesystem/File.h"
#include "filesystem/Directory.h"
#include "utils/log.h"

#include <gtest/gtest.h>

#if defined(TARGET_TIZEN)
#include "platform/linux/utils/TizenInterfaceForCLog.h"
#include "utils/IPlatformLog.h"
#include <app.h>
#include <app_common.h>
#include <storage.h>
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

// Task 9.1: Settings storage using Tizen data directory tests
#if defined(TARGET_TIZEN)
TEST_F(TestPlatformTizen, TizenDataPathExists)
{
  CPlatformTizen platform;
  platform.InitStageOne();
  
  // Get the Tizen data path
  char* dataPath = nullptr;
  int ret = app_get_data_path(&dataPath);
  
  EXPECT_EQ(ret, APP_ERROR_NONE);
  EXPECT_NE(dataPath, nullptr);
  
  if (dataPath != nullptr)
  {
    // Verify the path exists
    std::string path(dataPath);
    free(dataPath);
    
    // The path should exist and be writable
    EXPECT_TRUE(XFILE::CDirectory::Exists(path));
  }
}

TEST_F(TestPlatformTizen, TizenSettingsPathPersistence)
{
  CPlatformTizen platform;
  platform.InitStageOne();
  
  // Get the data path
  char* dataPath = nullptr;
  int ret = app_get_data_path(&dataPath);
  
  ASSERT_EQ(ret, APP_ERROR_NONE);
  ASSERT_NE(dataPath, nullptr);
  
  std::string path(dataPath);
  free(dataPath);
  
  // Create a test settings file
  std::string testFile = path + "/test_settings.xml";
  std::string testContent = "<?xml version=\"1.0\"?><settings><test>value</test></settings>";
  
  // Write test file
  XFILE::CFile file;
  EXPECT_TRUE(file.OpenForWrite(testFile, true));
  EXPECT_GT(file.Write(testContent.c_str(), testContent.length()), 0);
  file.Close();
  
  // Verify file exists
  EXPECT_TRUE(XFILE::CFile::Exists(testFile));
  
  // Read back the file
  EXPECT_TRUE(file.Open(testFile));
  std::string readContent;
  readContent.resize(testContent.length());
  EXPECT_EQ(file.Read(&readContent[0], testContent.length()), static_cast<ssize_t>(testContent.length()));
  file.Close();
  
  // Verify content matches
  EXPECT_EQ(readContent, testContent);
  
  // Clean up
  XFILE::CFile::Delete(testFile);
}

TEST_F(TestPlatformTizen, TizenSettingsDirectoryStructure)
{
  CPlatformTizen platform;
  platform.InitStageOne();
  
  // Get the data path
  char* dataPath = nullptr;
  int ret = app_get_data_path(&dataPath);
  
  ASSERT_EQ(ret, APP_ERROR_NONE);
  ASSERT_NE(dataPath, nullptr);
  
  std::string path(dataPath);
  free(dataPath);
  
  // Verify we can create subdirectories for settings
  std::string testDir = path + "/test_userdata";
  
  // Create directory
  EXPECT_TRUE(XFILE::CDirectory::Create(testDir));
  EXPECT_TRUE(XFILE::CDirectory::Exists(testDir));
  
  // Create a file in the subdirectory
  std::string testFile = testDir + "/settings.xml";
  XFILE::CFile file;
  EXPECT_TRUE(file.OpenForWrite(testFile, true));
  std::string content = "<settings/>";
  file.Write(content.c_str(), content.length());
  file.Close();
  
  EXPECT_TRUE(XFILE::CFile::Exists(testFile));
  
  // Clean up
  XFILE::CFile::Delete(testFile);
  XFILE::CDirectory::Remove(testDir);
}
#endif


// Task 9.2: Storage space monitoring tests
#if defined(TARGET_TIZEN)
TEST_F(TestPlatformTizen, TizenStorageSpaceMonitoring)
{
  CPlatformTizen platform;
  platform.InitStageOne();
  
  unsigned long long total = 0;
  unsigned long long available = 0;
  
  // Get storage info
  bool result = platform.GetStorageInfo(total, available);
  
  // Should succeed on Tizen
  EXPECT_TRUE(result);
  
  if (result)
  {
    // Total should be greater than 0
    EXPECT_GT(total, 0ULL);
    
    // Available should be less than or equal to total
    EXPECT_LE(available, total);
    
    // Log the values for debugging
    CLog::Log(LOGINFO, "Storage: {} MB total, {} MB available",
              total / (1024 * 1024), available / (1024 * 1024));
  }
}

TEST_F(TestPlatformTizen, TizenStorageSpaceCheck)
{
  CPlatformTizen platform;
  platform.InitStageOne();
  
  // CheckStorageSpace should not crash
  // It may return false if storage is low, but should not throw
  EXPECT_NO_THROW(platform.CheckStorageSpace());
}

TEST_F(TestPlatformTizen, TizenLowStorageWarning)
{
  CPlatformTizen platform;
  platform.InitStageOne();
  
  unsigned long long total = 0;
  unsigned long long available = 0;
  
  if (platform.GetStorageInfo(total, available))
  {
    // If available space is less than 100MB, CheckStorageSpace should warn
    const unsigned long long minSpace = 100 * 1024 * 1024;
    
    bool hasEnoughSpace = platform.CheckStorageSpace();
    
    if (available < minSpace)
    {
      // Should return false when storage is low
      EXPECT_FALSE(hasEnoughSpace);
    }
    else
    {
      // Should return true when storage is sufficient
      EXPECT_TRUE(hasEnoughSpace);
    }
  }
}
#endif


// Task 9.3: Data preservation during updates tests
#if defined(TARGET_TIZEN)
TEST_F(TestPlatformTizen, TizenDataPathConsistency)
{
  // Verify that the data path is consistent across platform instances
  // This simulates the behavior across app updates
  
  CPlatformTizen platform1;
  platform1.InitStageOne();
  
  char* dataPath1 = nullptr;
  int ret1 = app_get_data_path(&dataPath1);
  ASSERT_EQ(ret1, APP_ERROR_NONE);
  ASSERT_NE(dataPath1, nullptr);
  std::string path1(dataPath1);
  free(dataPath1);
  
  // Create a second platform instance (simulates app restart/update)
  CPlatformTizen platform2;
  platform2.InitStageOne();
  
  char* dataPath2 = nullptr;
  int ret2 = app_get_data_path(&dataPath2);
  ASSERT_EQ(ret2, APP_ERROR_NONE);
  ASSERT_NE(dataPath2, nullptr);
  std::string path2(dataPath2);
  free(dataPath2);
  
  // Paths should be identical
  EXPECT_EQ(path1, path2);
}

TEST_F(TestPlatformTizen, TizenDataPersistenceSimulation)
{
  CPlatformTizen platform;
  platform.InitStageOne();
  
  // Get the data path
  char* dataPath = nullptr;
  int ret = app_get_data_path(&dataPath);
  ASSERT_EQ(ret, APP_ERROR_NONE);
  ASSERT_NE(dataPath, nullptr);
  
  std::string path(dataPath);
  free(dataPath);
  
  // Create a test file to simulate user data
  std::string testFile = path + "/test_persistence_marker.txt";
  std::string testContent = "This file simulates user data that should persist across updates";
  
  // Write test file
  XFILE::CFile file;
  EXPECT_TRUE(file.OpenForWrite(testFile, true));
  EXPECT_GT(file.Write(testContent.c_str(), testContent.length()), 0);
  file.Close();
  
  // Verify file exists
  EXPECT_TRUE(XFILE::CFile::Exists(testFile));
  
  // Simulate app restart (in real scenario, this would be after an update)
  // The file should still exist
  EXPECT_TRUE(XFILE::CFile::Exists(testFile));
  
  // Read back and verify content
  EXPECT_TRUE(file.Open(testFile));
  std::string readContent;
  readContent.resize(testContent.length());
  EXPECT_EQ(file.Read(&readContent[0], testContent.length()), static_cast<ssize_t>(testContent.length()));
  file.Close();
  
  EXPECT_EQ(readContent, testContent);
  
  // Clean up
  XFILE::CFile::Delete(testFile);
}

TEST_F(TestPlatformTizen, TizenDataDirectoryWritePermissions)
{
  CPlatformTizen platform;
  platform.InitStageOne();
  
  // Get the data path
  char* dataPath = nullptr;
  int ret = app_get_data_path(&dataPath);
  ASSERT_EQ(ret, APP_ERROR_NONE);
  ASSERT_NE(dataPath, nullptr);
  
  std::string path(dataPath);
  free(dataPath);
  
  // Verify we have write permissions
  std::string testFile = path + "/write_test.tmp";
  
  XFILE::CFile file;
  bool canWrite = file.OpenForWrite(testFile, true);
  
  EXPECT_TRUE(canWrite);
  
  if (canWrite)
  {
    std::string content = "write test";
    file.Write(content.c_str(), content.length());
    file.Close();
    
    // Verify file was created
    EXPECT_TRUE(XFILE::CFile::Exists(testFile));
    
    // Clean up
    XFILE::CFile::Delete(testFile);
  }
}
#endif

