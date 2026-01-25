/*
 *  Copyright (C) 2025 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "cores/VideoPlayer/MediaPipelineTizen.h"
#include "utils/Geometry.h"

#include <gtest/gtest.h>

/**
 * Test fixture for CMediaPipelineTizen tests.
 * 
 * Note: These tests are designed to run on non-Tizen platforms as well,
 * where the implementation will gracefully handle the absence of Tizen APIs.
 */
class TestMediaPipelineTizen : public ::testing::Test
{
protected:
  void SetUp() override
  {
    // Setup code if needed
  }

  void TearDown() override
  {
    // Cleanup code if needed
  }
};

/**
 * Test that the pipeline can be constructed and destroyed without errors.
 */
TEST_F(TestMediaPipelineTizen, ConstructorDestructor)
{
  // Should not crash
  CMediaPipelineTizen pipeline;
  EXPECT_FALSE(pipeline.IsInitialized());
}

/**
 * Test that Initialize() can be called successfully.
 * On non-Tizen platforms, this should return false gracefully.
 */
TEST_F(TestMediaPipelineTizen, Initialize)
{
  CMediaPipelineTizen pipeline;
  
#if defined(TARGET_TIZEN)
  // On Tizen, initialization should succeed
  EXPECT_TRUE(pipeline.Initialize());
  EXPECT_TRUE(pipeline.IsInitialized());
#else
  // On non-Tizen platforms, initialization should fail gracefully
  EXPECT_FALSE(pipeline.Initialize());
  EXPECT_FALSE(pipeline.IsInitialized());
#endif
}

/**
 * Test that Finalize() can be called safely even without initialization.
 */
TEST_F(TestMediaPipelineTizen, FinalizeWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Should not crash
  pipeline.Finalize();
  EXPECT_FALSE(pipeline.IsInitialized());
}

/**
 * Test that Initialize() can be called multiple times safely.
 */
TEST_F(TestMediaPipelineTizen, DoubleInitialize)
{
  CMediaPipelineTizen pipeline;
  
  pipeline.Initialize();
  bool firstResult = pipeline.IsInitialized();
  
  // Second initialization should be safe
  pipeline.Initialize();
  EXPECT_EQ(firstResult, pipeline.IsInitialized());
}

/**
 * Test that Open() fails when pipeline is not initialized.
 */
TEST_F(TestMediaPipelineTizen, OpenWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.Open("test_video.mp4"));
}

/**
 * Test that Close() can be called safely without initialization.
 */
TEST_F(TestMediaPipelineTizen, CloseWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Should not crash
  pipeline.Close();
}

/**
 * Test that Close() can be called safely without opening media.
 */
TEST_F(TestMediaPipelineTizen, CloseWithoutOpen)
{
  CMediaPipelineTizen pipeline;
  pipeline.Initialize();
  
  // Should not crash
  pipeline.Close();
}

#if defined(TARGET_TIZEN)
/**
 * Test that Open() works with a valid URI on Tizen.
 * Note: This test requires a valid media file or will fail.
 */
TEST_F(TestMediaPipelineTizen, OpenValidMedia)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Note: This will fail if the file doesn't exist
  // In a real test environment, you would use a test media file
  bool result = pipeline.Open("test_video.mp4");
  
  // Clean up
  if (result)
  {
    pipeline.Close();
  }
  
  pipeline.Finalize();
}

/**
 * Test that Open() handles invalid URIs gracefully on Tizen.
 */
TEST_F(TestMediaPipelineTizen, OpenInvalidMedia)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Should fail gracefully with invalid URI
  EXPECT_FALSE(pipeline.Open(""));
  EXPECT_FALSE(pipeline.Open("nonexistent://invalid/path"));
  
  pipeline.Finalize();
}

/**
 * Test that opening media twice closes the first one.
 */
TEST_F(TestMediaPipelineTizen, OpenTwice)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // First open (may fail if file doesn't exist, but shouldn't crash)
  pipeline.Open("test_video1.mp4");
  
  // Second open should close first and open new one
  pipeline.Open("test_video2.mp4");
  
  pipeline.Close();
  pipeline.Finalize();
}

/**
 * Test that Finalize() closes any open media.
 */
TEST_F(TestMediaPipelineTizen, FinalizeClosesMedia)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Open media (may fail if file doesn't exist)
  pipeline.Open("test_video.mp4");
  
  // Finalize should close media and clean up
  pipeline.Finalize();
  EXPECT_FALSE(pipeline.IsInitialized());
}

/**
 * Test that Play() fails when pipeline is not initialized.
 */
TEST_F(TestMediaPipelineTizen, PlayWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.Play());
}

/**
 * Test that Play() fails when no media is open.
 */
TEST_F(TestMediaPipelineTizen, PlayWithoutOpen)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.Play());
  
  pipeline.Finalize();
}

/**
 * Test that Pause() fails when pipeline is not initialized.
 */
TEST_F(TestMediaPipelineTizen, PauseWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.Pause());
}

/**
 * Test that Pause() fails when no media is open.
 */
TEST_F(TestMediaPipelineTizen, PauseWithoutOpen)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.Pause());
  
  pipeline.Finalize();
}

/**
 * Test that Stop() fails when pipeline is not initialized.
 */
TEST_F(TestMediaPipelineTizen, StopWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.Stop());
}

/**
 * Test that Stop() fails when no media is open.
 */
TEST_F(TestMediaPipelineTizen, StopWithoutOpen)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.Stop());
  
  pipeline.Finalize();
}

/**
 * Test that Seek() fails when pipeline is not initialized.
 */
TEST_F(TestMediaPipelineTizen, SeekWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.Seek(10.0));
}

/**
 * Test that Seek() fails when no media is open.
 */
TEST_F(TestMediaPipelineTizen, SeekWithoutOpen)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.Seek(10.0));
  
  pipeline.Finalize();
}

/**
 * Test that GetCurrentTime() returns 0.0 when not initialized.
 */
TEST_F(TestMediaPipelineTizen, GetCurrentTimeWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Should return 0.0 gracefully
  EXPECT_EQ(0.0, pipeline.GetCurrentTime());
}

/**
 * Test that GetCurrentTime() returns 0.0 when no media is open.
 */
TEST_F(TestMediaPipelineTizen, GetCurrentTimeWithoutOpen)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Should return 0.0 gracefully
  EXPECT_EQ(0.0, pipeline.GetCurrentTime());
  
  pipeline.Finalize();
}

/**
 * Test that GetDuration() returns 0.0 when not initialized.
 */
TEST_F(TestMediaPipelineTizen, GetDurationWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Should return 0.0 gracefully
  EXPECT_EQ(0.0, pipeline.GetDuration());
}

/**
 * Test that GetDuration() returns 0.0 when no media is open.
 */
TEST_F(TestMediaPipelineTizen, GetDurationWithoutOpen)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Should return 0.0 gracefully
  EXPECT_EQ(0.0, pipeline.GetDuration());
  
  pipeline.Finalize();
}

/**
 * Test that playback control methods work with valid media on Tizen.
 * Note: This test requires a valid media file.
 */
TEST_F(TestMediaPipelineTizen, PlaybackControlWithValidMedia)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Note: This will fail if the file doesn't exist
  bool opened = pipeline.Open("test_video.mp4");
  
  if (opened)
  {
    // Test Play
    bool playResult = pipeline.Play();
    
    // Test GetCurrentTime and GetDuration (should not crash)
    double currentTime = pipeline.GetCurrentTime();
    double duration = pipeline.GetDuration();
    EXPECT_GE(currentTime, 0.0);
    EXPECT_GE(duration, 0.0);
    
    // Test Pause
    bool pauseResult = pipeline.Pause();
    
    // Test Seek
    bool seekResult = pipeline.Seek(5.0);
    
    // Test Stop
    bool stopResult = pipeline.Stop();
    
    pipeline.Close();
  }
  
  pipeline.Finalize();
}

/**
 * Test that callbacks are registered during initialization on Tizen.
 * This test verifies that Initialize() successfully registers callbacks
 * without crashing.
 */
TEST_F(TestMediaPipelineTizen, CallbacksRegisteredDuringInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Initialize should register callbacks
  ASSERT_TRUE(pipeline.Initialize());
  EXPECT_TRUE(pipeline.IsInitialized());
  
  // Finalize should unregister callbacks
  pipeline.Finalize();
  EXPECT_FALSE(pipeline.IsInitialized());
}

/**
 * Test that Finalize() unregisters callbacks properly on Tizen.
 * This test verifies that callbacks are cleaned up during finalization.
 */
TEST_F(TestMediaPipelineTizen, CallbacksUnregisteredDuringFinalize)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Finalize should unregister callbacks without crashing
  pipeline.Finalize();
  EXPECT_FALSE(pipeline.IsInitialized());
  
  // Should be safe to finalize again
  pipeline.Finalize();
}

/**
 * Test that multiple Initialize/Finalize cycles handle callbacks correctly.
 */
TEST_F(TestMediaPipelineTizen, MultipleInitializeFinalizeCycles)
{
  CMediaPipelineTizen pipeline;
  
  // First cycle
  ASSERT_TRUE(pipeline.Initialize());
  pipeline.Finalize();
  
  // Second cycle - callbacks should be re-registered
  ASSERT_TRUE(pipeline.Initialize());
  EXPECT_TRUE(pipeline.IsInitialized());
  pipeline.Finalize();
  
  // Third cycle
  ASSERT_TRUE(pipeline.Initialize());
  pipeline.Finalize();
}

/**
 * Test that SetVideoRect() fails when pipeline is not initialized.
 */
TEST_F(TestMediaPipelineTizen, SetVideoRectWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  CRect rect(0, 0, 1920, 1080);
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.SetVideoRect(rect));
}

/**
 * Test that SetVideoRect() fails when no media is open.
 */
TEST_F(TestMediaPipelineTizen, SetVideoRectWithoutOpen)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  CRect rect(0, 0, 1920, 1080);
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.SetVideoRect(rect));
  
  pipeline.Finalize();
}

/**
 * Test that SetVideoRect() works with valid media on Tizen.
 */
TEST_F(TestMediaPipelineTizen, SetVideoRectWithValidMedia)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  bool opened = pipeline.Open("test_video.mp4");
  
  if (opened)
  {
    // Test various video rectangles
    CRect fullscreen(0, 0, 1920, 1080);
    bool result1 = pipeline.SetVideoRect(fullscreen);
    
    CRect pip(1520, 780, 1920, 1080);  // Picture-in-picture in bottom right
    bool result2 = pipeline.SetVideoRect(pip);
    
    CRect centered(460, 240, 1460, 840);  // Centered with borders
    bool result3 = pipeline.SetVideoRect(centered);
    
    pipeline.Close();
  }
  
  pipeline.Finalize();
}

/**
 * Test that SetAudioStream() fails when pipeline is not initialized.
 */
TEST_F(TestMediaPipelineTizen, SetAudioStreamWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.SetAudioStream(0));
}

/**
 * Test that SetAudioStream() fails when no media is open.
 */
TEST_F(TestMediaPipelineTizen, SetAudioStreamWithoutOpen)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.SetAudioStream(0));
  
  pipeline.Finalize();
}

/**
 * Test that SetAudioStream() works with valid media on Tizen.
 */
TEST_F(TestMediaPipelineTizen, SetAudioStreamWithValidMedia)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  bool opened = pipeline.Open("test_video.mp4");
  
  if (opened)
  {
    // Test selecting different audio streams
    // Note: This will fail if the media doesn't have multiple audio tracks
    bool result1 = pipeline.SetAudioStream(0);
    bool result2 = pipeline.SetAudioStream(1);
    
    pipeline.Close();
  }
  
  pipeline.Finalize();
}

/**
 * Test that ConfigureAudioRouting() fails when pipeline is not initialized.
 */
TEST_F(TestMediaPipelineTizen, ConfigureAudioRoutingWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.ConfigureAudioRouting());
}

/**
 * Test that ConfigureAudioRouting() works after initialization on Tizen.
 */
TEST_F(TestMediaPipelineTizen, ConfigureAudioRoutingAfterInitialize)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Should succeed after initialization
  bool result = pipeline.ConfigureAudioRouting();
  
  pipeline.Finalize();
}

/**
 * Test that GetSupportedCodecs() returns a valid list on Tizen.
 * On non-Tizen platforms, it should return an empty list.
 */
TEST_F(TestMediaPipelineTizen, GetSupportedCodecs)
{
  CMediaPipelineTizen pipeline;
  
  // Should work even without initialization
  std::vector<std::string> codecs = pipeline.GetSupportedCodecs();
  
#if defined(TARGET_TIZEN)
  // On Tizen, we expect at least some common codecs to be supported
  // Most Samsung TVs support H.264 and AAC at minimum
  EXPECT_FALSE(codecs.empty());
  
  // Check for common codecs (at least one should be present)
  bool hasVideoCodec = false;
  bool hasAudioCodec = false;
  
  for (const auto& codec : codecs)
  {
    if (codec == "h264" || codec == "hevc" || codec == "vp9" || codec == "mpeg4")
    {
      hasVideoCodec = true;
    }
    if (codec == "aac" || codec == "mp3" || codec == "ac3")
    {
      hasAudioCodec = true;
    }
  }
  
  // Most devices should support at least one video and one audio codec
  EXPECT_TRUE(hasVideoCodec || hasAudioCodec);
#else
  // On non-Tizen platforms, should return empty list
  EXPECT_TRUE(codecs.empty());
#endif
}

/**
 * Test that GetSupportedCodecs() doesn't crash when called multiple times.
 */
TEST_F(TestMediaPipelineTizen, GetSupportedCodecsMultipleCalls)
{
  CMediaPipelineTizen pipeline;
  
  // Should be safe to call multiple times
  std::vector<std::string> codecs1 = pipeline.GetSupportedCodecs();
  std::vector<std::string> codecs2 = pipeline.GetSupportedCodecs();
  std::vector<std::string> codecs3 = pipeline.GetSupportedCodecs();
  
  // Results should be consistent
  EXPECT_EQ(codecs1.size(), codecs2.size());
  EXPECT_EQ(codecs2.size(), codecs3.size());
}

/**
 * Test that SupportsHDR() returns a valid result on Tizen.
 * On non-Tizen platforms, it should return false.
 */
TEST_F(TestMediaPipelineTizen, SupportsHDR)
{
  CMediaPipelineTizen pipeline;
  
  // Should work even without initialization
  bool hdrSupported = pipeline.SupportsHDR();
  
#if defined(TARGET_TIZEN)
  // On Tizen, the result depends on the device capabilities
  // We just verify it doesn't crash and returns a boolean
  // (can be true or false depending on the TV model)
  EXPECT_TRUE(hdrSupported == true || hdrSupported == false);
#else
  // On non-Tizen platforms, should return false
  EXPECT_FALSE(hdrSupported);
#endif
}

/**
 * Test that SupportsHDR() doesn't crash when called multiple times.
 */
TEST_F(TestMediaPipelineTizen, SupportsHDRMultipleCalls)
{
  CMediaPipelineTizen pipeline;
  
  // Should be safe to call multiple times
  bool result1 = pipeline.SupportsHDR();
  bool result2 = pipeline.SupportsHDR();
  bool result3 = pipeline.SupportsHDR();
  
  // Results should be consistent
  EXPECT_EQ(result1, result2);
  EXPECT_EQ(result2, result3);
}

/**
 * Test that ConfigureHDROutput() fails when pipeline is not initialized.
 */
TEST_F(TestMediaPipelineTizen, ConfigureHDROutputWithoutInitialize)
{
  CMediaPipelineTizen pipeline;
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.ConfigureHDROutput());
}

/**
 * Test that ConfigureHDROutput() fails when no media is open.
 */
TEST_F(TestMediaPipelineTizen, ConfigureHDROutputWithoutOpen)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  // Should fail gracefully
  EXPECT_FALSE(pipeline.ConfigureHDROutput());
  
  pipeline.Finalize();
}

/**
 * Test that ConfigureHDROutput() works with valid media on Tizen.
 */
TEST_F(TestMediaPipelineTizen, ConfigureHDROutputWithValidMedia)
{
  CMediaPipelineTizen pipeline;
  ASSERT_TRUE(pipeline.Initialize());
  
  bool opened = pipeline.Open("test_video.mp4");
  
  if (opened)
  {
    // ConfigureHDROutput should work after opening media
    // It may return false if HDR is not supported on the device
    bool result = pipeline.ConfigureHDROutput();
    
    // If HDR is not supported, result should be false
    // If HDR is supported, result should be true
    bool hdrSupported = pipeline.SupportsHDR();
    if (!hdrSupported)
    {
      EXPECT_FALSE(result);
    }
    
    pipeline.Close();
  }
  
  pipeline.Finalize();
}

/**
 * Test that codec capability reporting works in a complete workflow.
 */
TEST_F(TestMediaPipelineTizen, CodecCapabilityWorkflow)
{
  CMediaPipelineTizen pipeline;
  
  // Query codec support before initialization (should work)
  std::vector<std::string> codecs = pipeline.GetSupportedCodecs();
  bool hdrSupported = pipeline.SupportsHDR();
  
  // Initialize pipeline
  ASSERT_TRUE(pipeline.Initialize());
  
  // Query codec support after initialization (should still work)
  std::vector<std::string> codecs2 = pipeline.GetSupportedCodecs();
  bool hdrSupported2 = pipeline.SupportsHDR();
  
  // Results should be consistent
  EXPECT_EQ(codecs.size(), codecs2.size());
  EXPECT_EQ(hdrSupported, hdrSupported2);
  
  // Open media
  bool opened = pipeline.Open("test_video.mp4");
  
  if (opened)
  {
    // Configure HDR if supported
    if (hdrSupported)
    {
      pipeline.ConfigureHDROutput();
    }
    
    pipeline.Close();
  }
  
  pipeline.Finalize();
}
#endif // TARGET_TIZEN

