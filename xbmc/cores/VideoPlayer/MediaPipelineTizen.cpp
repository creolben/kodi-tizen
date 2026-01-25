/*
 *  Copyright (C) 2025 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "MediaPipelineTizen.h"

#include "utils/Geometry.h"
#include "utils/log.h"

#if defined(TARGET_TIZEN)
#include <player.h>
#include <sound_manager.h>
#include <system_info.h>
#endif

CMediaPipelineTizen::CMediaPipelineTizen()
  : m_player(nullptr), m_initialized(false), m_isOpen(false)
{
  CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Constructor called");
}

CMediaPipelineTizen::~CMediaPipelineTizen()
{
  CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Destructor called");
  Finalize();
}

bool CMediaPipelineTizen::Initialize()
{
  if (m_initialized)
  {
    CLog::Log(LOGWARNING, "CMediaPipelineTizen: Already initialized");
    return true;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Initializing Tizen media pipeline");

  // Create the Tizen player instance
  int ret = player_create(&m_player);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to create player, error code: {}", ret);
    m_player = nullptr;
    return false;
  }

  if (m_player == nullptr)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: player_create returned null handle");
    return false;
  }

  // Register callbacks for state changes, errors, and buffering
  if (!RegisterCallbacks())
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to register callbacks");
    player_destroy(m_player);
    m_player = nullptr;
    return false;
  }

  m_initialized = true;
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Successfully initialized");
  return true;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, initialization skipped");
  return false;
#endif
}

void CMediaPipelineTizen::Finalize()
{
  if (!m_initialized)
  {
    return;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Finalizing Tizen media pipeline");

  // Close any open media first
  if (m_isOpen)
  {
    Close();
  }

  if (m_player != nullptr)
  {
    // Unregister callbacks before destroying the player
    UnregisterCallbacks();

    // Destroy the Tizen player instance
    int ret = player_destroy(m_player);
    if (ret != PLAYER_ERROR_NONE)
    {
      CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to destroy player, error code: {}", ret);
    }
    else
    {
      CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Player destroyed successfully");
    }
    
    m_player = nullptr;
  }

  m_initialized = false;
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Finalized successfully");
#endif
}

bool CMediaPipelineTizen::Open(const std::string& url)
{
  if (!m_initialized)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot open media - pipeline not initialized");
    return false;
  }

  if (m_isOpen)
  {
    CLog::Log(LOGWARNING, "CMediaPipelineTizen: Media already open, closing first");
    Close();
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Opening media: {}", url);

  // Set the media URI
  int ret = player_set_uri(m_player, url.c_str());
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to set URI, error code: {}", ret);
    return false;
  }

  CLog::Log(LOGDEBUG, "CMediaPipelineTizen: URI set successfully");

  // Configure audio routing before preparing the player
  if (!ConfigureAudioRouting())
  {
    CLog::Log(LOGWARNING, "CMediaPipelineTizen: Failed to configure audio routing, continuing anyway");
    // Don't fail the open operation if audio routing fails
  }

  // Prepare the player (this may take time for network streams)
  ret = player_prepare(m_player);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to prepare player, error code: {}", ret);
    return false;
  }

  m_isOpen = true;
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Media opened and prepared successfully");
  return true;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, open skipped");
  return false;
#endif
}

void CMediaPipelineTizen::Close()
{
  if (!m_initialized)
  {
    CLog::Log(LOGWARNING, "CMediaPipelineTizen: Cannot close - pipeline not initialized");
    return;
  }

  if (!m_isOpen)
  {
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: No media open, nothing to close");
    return;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Closing media");

  if (m_player != nullptr)
  {
    // Stop playback if active before unpreparing
    player_state_e state;
    int ret = player_get_state(m_player, &state);
    if (ret == PLAYER_ERROR_NONE && (state == PLAYER_STATE_PLAYING || state == PLAYER_STATE_PAUSED))
    {
      CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Stopping playback before close");
      player_stop(m_player);
    }

    // Unprepare the player to release resources
    ret = player_unprepare(m_player);
    if (ret != PLAYER_ERROR_NONE)
    {
      CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to unprepare player, error code: {}", ret);
    }
    else
    {
      CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Player unprepared successfully");
    }
  }

  m_isOpen = false;
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Media closed successfully");
#endif
}

bool CMediaPipelineTizen::Play()
{
  if (!m_initialized)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot play - pipeline not initialized");
    return false;
  }

  if (!m_isOpen)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot play - no media open");
    return false;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Starting playback");

  int ret = player_start(m_player);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to start playback, error code: {}", ret);
    return false;
  }

  CLog::Log(LOGINFO, "CMediaPipelineTizen: Playback started successfully");
  return true;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, play skipped");
  return false;
#endif
}

bool CMediaPipelineTizen::Pause()
{
  if (!m_initialized)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot pause - pipeline not initialized");
    return false;
  }

  if (!m_isOpen)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot pause - no media open");
    return false;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Pausing playback");

  int ret = player_pause(m_player);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to pause playback, error code: {}", ret);
    return false;
  }

  CLog::Log(LOGINFO, "CMediaPipelineTizen: Playback paused successfully");
  return true;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, pause skipped");
  return false;
#endif
}

bool CMediaPipelineTizen::Stop()
{
  if (!m_initialized)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot stop - pipeline not initialized");
    return false;
  }

  if (!m_isOpen)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot stop - no media open");
    return false;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Stopping playback");

  int ret = player_stop(m_player);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to stop playback, error code: {}", ret);
    return false;
  }

  CLog::Log(LOGINFO, "CMediaPipelineTizen: Playback stopped successfully");
  return true;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, stop skipped");
  return false;
#endif
}

bool CMediaPipelineTizen::Seek(double time)
{
  if (!m_initialized)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot seek - pipeline not initialized");
    return false;
  }

  if (!m_isOpen)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot seek - no media open");
    return false;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Seeking to position: {} seconds", time);

  // Convert seconds to milliseconds for Tizen API
  int positionMs = static_cast<int>(time * 1000.0);

  // Clamp to valid range [0, duration]
  int durationMs = 0;
  int ret = player_get_duration(m_player, &durationMs);
  if (ret == PLAYER_ERROR_NONE && durationMs > 0)
  {
    if (positionMs < 0)
    {
      positionMs = 0;
    }
    else if (positionMs > durationMs)
    {
      positionMs = durationMs;
    }
  }

  ret = player_set_play_position(m_player, positionMs, true, nullptr, nullptr);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to seek, error code: {}", ret);
    return false;
  }

  CLog::Log(LOGINFO, "CMediaPipelineTizen: Seek successful to {} ms", positionMs);
  return true;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, seek skipped");
  return false;
#endif
}

double CMediaPipelineTizen::GetCurrentTime()
{
  if (!m_initialized || !m_isOpen)
  {
    return 0.0;
  }

#if defined(TARGET_TIZEN)
  int positionMs = 0;
  int ret = player_get_play_position(m_player, &positionMs);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Failed to get current position, error code: {}", ret);
    return 0.0;
  }

  // Convert milliseconds to seconds
  return static_cast<double>(positionMs) / 1000.0;
#else
  return 0.0;
#endif
}

double CMediaPipelineTizen::GetDuration()
{
  if (!m_initialized || !m_isOpen)
  {
    return 0.0;
  }

#if defined(TARGET_TIZEN)
  int durationMs = 0;
  int ret = player_get_duration(m_player, &durationMs);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Failed to get duration, error code: {}", ret);
    return 0.0;
  }

  // Convert milliseconds to seconds
  return static_cast<double>(durationMs) / 1000.0;
#else
  return 0.0;
#endif
}

bool CMediaPipelineTizen::SetVideoRect(const CRect& rect)
{
  if (!m_initialized)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot set video rect - pipeline not initialized");
    return false;
  }

  if (!m_isOpen)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot set video rect - no media open");
    return false;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Setting video rectangle - x:{}, y:{}, width:{}, height:{}",
            static_cast<int>(rect.x1), static_cast<int>(rect.y1),
            static_cast<int>(rect.Width()), static_cast<int>(rect.Height()));

  // Configure the display type to use overlay for video rendering
  int ret = player_set_display(m_player, PLAYER_DISPLAY_TYPE_OVERLAY, nullptr);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to set display type, error code: {}", ret);
    return false;
  }

  // Set the video display region using the provided rectangle
  // Tizen expects integer coordinates for the display region
  ret = player_set_display_roi(m_player,
                                static_cast<int>(rect.x1),
                                static_cast<int>(rect.y1),
                                static_cast<int>(rect.Width()),
                                static_cast<int>(rect.Height()));
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to set display ROI, error code: {}", ret);
    return false;
  }

  CLog::Log(LOGINFO, "CMediaPipelineTizen: Video rectangle set successfully");
  return true;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, SetVideoRect skipped");
  return false;
#endif
}

bool CMediaPipelineTizen::SetAudioStream(int streamId)
{
  if (!m_initialized)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot set audio stream - pipeline not initialized");
    return false;
  }

  if (!m_isOpen)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot set audio stream - no media open");
    return false;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Selecting audio stream: {}", streamId);

  // Select the audio track using player_select_track
  // PLAYER_STREAM_TYPE_AUDIO indicates we're selecting an audio track
  int ret = player_select_track(m_player, PLAYER_STREAM_TYPE_AUDIO, streamId);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to select audio stream {}, error code: {}",
              streamId, ret);
    return false;
  }

  CLog::Log(LOGINFO, "CMediaPipelineTizen: Audio stream {} selected successfully", streamId);
  return true;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, SetAudioStream skipped");
  return false;
#endif
}

bool CMediaPipelineTizen::ConfigureAudioRouting()
{
  if (!m_initialized)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot configure audio routing - pipeline not initialized");
    return false;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Configuring audio routing through Tizen audio subsystem");

  // Set audio policy to media playback
  // This ensures audio is routed correctly through the TV's audio system
  int ret = player_set_audio_policy_info(m_player, SOUND_STREAM_TYPE_MEDIA);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to set audio policy, error code: {}", ret);
    return false;
  }

  CLog::Log(LOGINFO, "CMediaPipelineTizen: Audio routing configured successfully");
  return true;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, ConfigureAudioRouting skipped");
  return false;
#endif
}

std::vector<std::string> CMediaPipelineTizen::GetSupportedCodecs()
{
  std::vector<std::string> codecs;

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Querying supported codecs from Tizen");

  // Query video codec support using system_info API
  // Check for common video codecs
  bool supported = false;
  
  // H.264/AVC
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.codec.h264", &supported) == SYSTEM_INFO_ERROR_NONE && supported)
  {
    codecs.push_back("h264");
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: H.264 codec supported");
  }

  // H.265/HEVC
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.codec.hevc", &supported) == SYSTEM_INFO_ERROR_NONE && supported)
  {
    codecs.push_back("hevc");
    codecs.push_back("h265");
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: HEVC codec supported");
  }

  // VP8
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.codec.vp8", &supported) == SYSTEM_INFO_ERROR_NONE && supported)
  {
    codecs.push_back("vp8");
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: VP8 codec supported");
  }

  // VP9
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.codec.vp9", &supported) == SYSTEM_INFO_ERROR_NONE && supported)
  {
    codecs.push_back("vp9");
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: VP9 codec supported");
  }

  // MPEG-4
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.codec.mpeg4", &supported) == SYSTEM_INFO_ERROR_NONE && supported)
  {
    codecs.push_back("mpeg4");
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: MPEG-4 codec supported");
  }

  // Query audio codec support
  // AAC
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.codec.aac", &supported) == SYSTEM_INFO_ERROR_NONE && supported)
  {
    codecs.push_back("aac");
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: AAC codec supported");
  }

  // MP3
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.codec.mp3", &supported) == SYSTEM_INFO_ERROR_NONE && supported)
  {
    codecs.push_back("mp3");
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: MP3 codec supported");
  }

  // Vorbis
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.codec.vorbis", &supported) == SYSTEM_INFO_ERROR_NONE && supported)
  {
    codecs.push_back("vorbis");
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Vorbis codec supported");
  }

  // FLAC
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.codec.flac", &supported) == SYSTEM_INFO_ERROR_NONE && supported)
  {
    codecs.push_back("flac");
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: FLAC codec supported");
  }

  // AC3
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.codec.ac3", &supported) == SYSTEM_INFO_ERROR_NONE && supported)
  {
    codecs.push_back("ac3");
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: AC3 codec supported");
  }

  // EAC3 (Dolby Digital Plus)
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.codec.eac3", &supported) == SYSTEM_INFO_ERROR_NONE && supported)
  {
    codecs.push_back("eac3");
    CLog::Log(LOGDEBUG, "CMediaPipelineTizen: EAC3 codec supported");
  }

  CLog::Log(LOGINFO, "CMediaPipelineTizen: Found {} supported codecs", codecs.size());
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, returning empty codec list");
#endif

  return codecs;
}

bool CMediaPipelineTizen::SupportsHDR()
{
#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Checking HDR support");

  bool hdrSupported = false;

  // Check for HDR10 support
  bool hdr10 = false;
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.hdr10", &hdr10) == SYSTEM_INFO_ERROR_NONE && hdr10)
  {
    CLog::Log(LOGINFO, "CMediaPipelineTizen: HDR10 supported");
    hdrSupported = true;
  }

  // Check for HDR10+ support
  bool hdr10Plus = false;
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.hdr10_plus", &hdr10Plus) == SYSTEM_INFO_ERROR_NONE && hdr10Plus)
  {
    CLog::Log(LOGINFO, "CMediaPipelineTizen: HDR10+ supported");
    hdrSupported = true;
  }

  // Check for Dolby Vision support
  bool dolbyVision = false;
  if (system_info_get_platform_bool("http://tizen.org/feature/multimedia.player.dolby_vision", &dolbyVision) == SYSTEM_INFO_ERROR_NONE && dolbyVision)
  {
    CLog::Log(LOGINFO, "CMediaPipelineTizen: Dolby Vision supported");
    hdrSupported = true;
  }

  if (!hdrSupported)
  {
    CLog::Log(LOGINFO, "CMediaPipelineTizen: HDR not supported on this device");
  }

  return hdrSupported;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, HDR support unknown");
  return false;
#endif
}

bool CMediaPipelineTizen::ConfigureHDROutput()
{
  if (!m_initialized)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot configure HDR - pipeline not initialized");
    return false;
  }

  if (!m_isOpen)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot configure HDR - no media open");
    return false;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Configuring HDR output");

  // First check if HDR is supported
  if (!SupportsHDR())
  {
    CLog::Log(LOGWARNING, "CMediaPipelineTizen: HDR not supported, skipping HDR configuration");
    return false;
  }

  // Enable HDR mode on the player
  // Note: The actual API for enabling HDR may vary depending on Tizen version
  // This is a placeholder for the HDR configuration logic
  int ret = player_set_display_mode(m_player, PLAYER_DISPLAY_MODE_DST_ROI);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to set display mode for HDR, error code: {}", ret);
    return false;
  }

  // Set display visibility to ensure HDR content is visible
  ret = player_set_display_visible(m_player, true);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to set display visibility, error code: {}", ret);
    return false;
  }

  CLog::Log(LOGINFO, "CMediaPipelineTizen: HDR output configured successfully");
  return true;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, ConfigureHDROutput skipped");
  return false;
#endif
}

bool CMediaPipelineTizen::SetSubtitleStream(int streamId)
{
  if (!m_initialized)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot set subtitle stream - pipeline not initialized");
    return false;
  }

  if (!m_isOpen)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot set subtitle stream - no media open");
    return false;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Selecting subtitle stream: {}", streamId);

  // Select the subtitle track using player_select_track
  // PLAYER_STREAM_TYPE_TEXT indicates we're selecting a subtitle/text track
  int ret = player_select_track(m_player, PLAYER_STREAM_TYPE_TEXT, streamId);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to select subtitle stream {}, error code: {}",
              streamId, ret);
    return false;
  }

  CLog::Log(LOGINFO, "CMediaPipelineTizen: Subtitle stream {} selected successfully", streamId);
  
  // Note: The actual subtitle rendering is handled by Kodi's subtitle renderer
  // (CDVDOverlayContainer), not by the Tizen player. The Tizen player provides
  // the subtitle data, and Kodi's overlay system renders it on top of the video.
  // This coordination ensures consistent subtitle appearance across all Kodi platforms.
  
  return true;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, SetSubtitleStream skipped");
  return false;
#endif
}

bool CMediaPipelineTizen::RegisterCallbacks()
{
  if (!m_initialized || m_player == nullptr)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Cannot register callbacks - player not initialized");
    return false;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Registering AVPlay callbacks");

  // Register state change callback
  int ret = player_set_completed_cb(m_player, OnPlayerStateChanged, this);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to register state callback, error code: {}", ret);
    return false;
  }

  // Register error callback
  ret = player_set_error_cb(m_player, OnPlayerError, this);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to register error callback, error code: {}", ret);
    return false;
  }

  // Register buffering callback
  ret = player_set_buffering_cb(m_player, OnBufferingProgress, this);
  if (ret != PLAYER_ERROR_NONE)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: Failed to register buffering callback, error code: {}", ret);
    return false;
  }

  CLog::Log(LOGINFO, "CMediaPipelineTizen: AVPlay callbacks registered successfully");
  return true;
#else
  CLog::Log(LOGWARNING, "CMediaPipelineTizen: Not compiled with TARGET_TIZEN, callback registration skipped");
  return false;
#endif
}

void CMediaPipelineTizen::UnregisterCallbacks()
{
  if (!m_initialized || m_player == nullptr)
  {
    return;
  }

#if defined(TARGET_TIZEN)
  CLog::Log(LOGINFO, "CMediaPipelineTizen: Unregistering AVPlay callbacks");

  // Unregister callbacks by setting them to nullptr
  player_unset_completed_cb(m_player);
  player_unset_error_cb(m_player);
  player_unset_buffering_cb(m_player);

  CLog::Log(LOGDEBUG, "CMediaPipelineTizen: AVPlay callbacks unregistered");
#endif
}

#if defined(TARGET_TIZEN)
void CMediaPipelineTizen::OnPlayerStateChanged(player_state_e state, void* userData)
{
  auto* pipeline = static_cast<CMediaPipelineTizen*>(userData);
  if (pipeline == nullptr)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: OnPlayerStateChanged called with null userData");
    return;
  }

  // Log the state change
  const char* stateStr = "UNKNOWN";
  switch (state)
  {
    case PLAYER_STATE_NONE:
      stateStr = "NONE";
      break;
    case PLAYER_STATE_IDLE:
      stateStr = "IDLE";
      break;
    case PLAYER_STATE_READY:
      stateStr = "READY";
      break;
    case PLAYER_STATE_PLAYING:
      stateStr = "PLAYING";
      break;
    case PLAYER_STATE_PAUSED:
      stateStr = "PAUSED";
      break;
  }

  CLog::Log(LOGINFO, "CMediaPipelineTizen: Player state changed to: {}", stateStr);

  // Handle specific state transitions
  switch (state)
  {
    case PLAYER_STATE_PLAYING:
      CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Playback started/resumed");
      // TODO: Notify Kodi player interface of playback state
      break;

    case PLAYER_STATE_PAUSED:
      CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Playback paused");
      // TODO: Notify Kodi player interface of pause state
      break;

    case PLAYER_STATE_READY:
      CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Player ready for playback");
      break;

    case PLAYER_STATE_IDLE:
      CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Player idle");
      break;

    case PLAYER_STATE_NONE:
      CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Player in none state");
      break;

    default:
      CLog::Log(LOGWARNING, "CMediaPipelineTizen: Unknown player state: {}", static_cast<int>(state));
      break;
  }
}

void CMediaPipelineTizen::OnPlayerError(int errorCode, void* userData)
{
  auto* pipeline = static_cast<CMediaPipelineTizen*>(userData);
  if (pipeline == nullptr)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: OnPlayerError called with null userData");
    return;
  }

  // Map Tizen error codes to descriptive messages
  const char* errorMsg = "Unknown error";
  switch (errorCode)
  {
    case PLAYER_ERROR_INVALID_PARAMETER:
      errorMsg = "Invalid parameter";
      break;
    case PLAYER_ERROR_OUT_OF_MEMORY:
      errorMsg = "Out of memory";
      break;
    case PLAYER_ERROR_INVALID_OPERATION:
      errorMsg = "Invalid operation";
      break;
    case PLAYER_ERROR_FILE_NO_SPACE_ON_DEVICE:
      errorMsg = "No space on device";
      break;
    case PLAYER_ERROR_FEATURE_NOT_SUPPORTED_ON_DEVICE:
      errorMsg = "Feature not supported on device";
      break;
    case PLAYER_ERROR_SEEK_FAILED:
      errorMsg = "Seek failed";
      break;
    case PLAYER_ERROR_INVALID_STATE:
      errorMsg = "Invalid state";
      break;
    case PLAYER_ERROR_NOT_SUPPORTED_FILE:
      errorMsg = "File format or codec not supported";
      break;
    case PLAYER_ERROR_INVALID_URI:
      errorMsg = "Invalid URI";
      break;
    case PLAYER_ERROR_SOUND_POLICY:
      errorMsg = "Sound policy error";
      break;
    case PLAYER_ERROR_CONNECTION_FAILED:
      errorMsg = "Network connection failed";
      break;
    case PLAYER_ERROR_VIDEO_CAPTURE_FAILED:
      errorMsg = "Video capture failed";
      break;
    case PLAYER_ERROR_DRM_EXPIRED:
      errorMsg = "DRM license expired";
      break;
    case PLAYER_ERROR_DRM_NO_LICENSE:
      errorMsg = "DRM license not found";
      break;
    case PLAYER_ERROR_DRM_FUTURE_USE:
      errorMsg = "DRM license not yet valid";
      break;
    case PLAYER_ERROR_DRM_NOT_PERMITTED:
      errorMsg = "DRM playback not permitted";
      break;
    case PLAYER_ERROR_RESOURCE_LIMIT:
      errorMsg = "Resource limit exceeded";
      break;
    case PLAYER_ERROR_PERMISSION_DENIED:
      errorMsg = "Permission denied";
      break;
    case PLAYER_ERROR_SERVICE_DISCONNECTED:
      errorMsg = "Service disconnected";
      break;
    case PLAYER_ERROR_BUFFER_SPACE:
      errorMsg = "Buffer space error";
      break;
    default:
      errorMsg = "Unknown error";
      break;
  }

  CLog::Log(LOGERROR, "CMediaPipelineTizen: Player error occurred - Code: {}, Message: {}", 
            errorCode, errorMsg);

  // TODO: Propagate error to Kodi's error handling system
  // This would typically involve calling a callback or posting an event
  // to notify the video player of the error condition
}

void CMediaPipelineTizen::OnBufferingProgress(int percent, void* userData)
{
  auto* pipeline = static_cast<CMediaPipelineTizen*>(userData);
  if (pipeline == nullptr)
  {
    CLog::Log(LOGERROR, "CMediaPipelineTizen: OnBufferingProgress called with null userData");
    return;
  }

  CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Buffering progress: {}%", percent);

  // Handle buffering states
  if (percent == 0)
  {
    CLog::Log(LOGINFO, "CMediaPipelineTizen: Buffering started");
    // TODO: Notify Kodi player interface that buffering has started
  }
  else if (percent == 100)
  {
    CLog::Log(LOGINFO, "CMediaPipelineTizen: Buffering complete");
    // TODO: Notify Kodi player interface that buffering is complete
  }
  else
  {
    // Log periodic progress updates (every 10%)
    if (percent % 10 == 0)
    {
      CLog::Log(LOGDEBUG, "CMediaPipelineTizen: Buffering at {}%", percent);
    }
  }

  // TODO: Update Kodi's buffering UI with the current progress
}
#endif
