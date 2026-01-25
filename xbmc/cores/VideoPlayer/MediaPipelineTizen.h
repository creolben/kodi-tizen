/*
 *  Copyright (C) 2025 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include <string>
#include <vector>

// Forward declarations
class CRect;

#if defined(TARGET_TIZEN)
#include <player.h>
#endif

/**
 * @class CMediaPipelineTizen
 * @brief Tizen media pipeline for audio/video playback using AVPlay API.
 * 
 * This class integrates Kodi's video player with Tizen's native multimedia
 * framework (AVPlay/player API) for hardware-accelerated playback on Samsung
 * smart TVs. It manages the lifecycle of the Tizen player instance and provides
 * the foundation for media playback operations.
 */
class CMediaPipelineTizen
{
public:
  /**
   * @brief Construct the Tizen media pipeline.
   */
  CMediaPipelineTizen();

  /**
   * @brief Destructor, cleans up player resources.
   */
  ~CMediaPipelineTizen();

  /**
   * @brief Initialize the Tizen media pipeline.
   * 
   * Creates the Tizen player instance using player_create() and prepares
   * the pipeline for media playback. This must be called before any other
   * operations on the pipeline.
   * 
   * @return True if initialization succeeded, false otherwise.
   */
  bool Initialize();

  /**
   * @brief Finalize and cleanup the Tizen media pipeline.
   * 
   * Destroys the Tizen player instance using player_destroy() and releases
   * all associated resources. After calling this method, Initialize() must
   * be called again before the pipeline can be used.
   */
  void Finalize();

  /**
   * @brief Check if the pipeline is initialized.
   * @return True if initialized, false otherwise.
   */
  bool IsInitialized() const { return m_initialized; }

  /**
   * @brief Open a media file or stream for playback.
   * 
   * Sets the media URI using player_set_uri() and prepares the player
   * using player_prepare(). The URI can be a local file path or a network
   * stream URL. This method must be called after Initialize() and before
   * any playback operations.
   * 
   * @param url The URI of the media to open (file path or stream URL).
   * @return True if the media was opened successfully, false otherwise.
   */
  bool Open(const std::string& url);

  /**
   * @brief Close the currently open media and release player resources.
   * 
   * Stops playback if active, unprepares the player using player_unprepare(),
   * and releases resources associated with the current media. After calling
   * this method, Open() must be called again to play new media.
   */
  void Close();

  /**
   * @brief Start or resume media playback.
   * 
   * Starts playback of the currently opened media using player_start().
   * If playback was previously paused, this will resume from the paused position.
   * The media must be opened with Open() before calling this method.
   * 
   * @return True if playback started successfully, false otherwise.
   */
  bool Play();

  /**
   * @brief Pause media playback.
   * 
   * Pauses the currently playing media using player_pause().
   * The playback position is preserved and can be resumed with Play().
   * 
   * @return True if playback was paused successfully, false otherwise.
   */
  bool Pause();

  /**
   * @brief Stop media playback.
   * 
   * Stops the currently playing media using player_stop().
   * This resets the playback position to the beginning.
   * 
   * @return True if playback was stopped successfully, false otherwise.
   */
  bool Stop();

  /**
   * @brief Seek to a specific position in the media.
   * 
   * Seeks to the specified time position using player_set_play_position().
   * The position is specified in seconds and will be clamped to the valid
   * range [0, duration].
   * 
   * @param time The target position in seconds.
   * @return True if seek was successful, false otherwise.
   */
  bool Seek(double time);

  /**
   * @brief Get the current playback position.
   * 
   * Retrieves the current playback position in seconds using
   * player_get_play_position(). Returns 0.0 if no media is playing
   * or if the position cannot be determined.
   * 
   * @return Current playback position in seconds.
   */
  double GetCurrentTime();

  /**
   * @brief Get the total duration of the media.
   * 
   * Retrieves the total duration of the currently opened media in seconds
   * using player_get_duration(). Returns 0.0 if no media is open or if
   * the duration cannot be determined (e.g., for live streams).
   * 
   * @return Total media duration in seconds.
   */
  double GetDuration();

  /**
   * @brief Set the video display rectangle.
   * 
   * Configures the video output rectangle using player_set_display() to
   * control where video is rendered on screen. This is used for picture-in-picture,
   * aspect ratio adjustments, and video positioning.
   * 
   * @param rect The rectangle defining video display area (x, y, width, height).
   * @return True if the video rectangle was set successfully, false otherwise.
   */
  bool SetVideoRect(const CRect& rect);

  /**
   * @brief Select an audio stream for playback.
   * 
   * Switches to a different audio track using player_select_track().
   * This is used for multi-audio content where the user can choose between
   * different languages or audio formats.
   * 
   * @param streamId The ID of the audio stream to select.
   * @return True if the audio stream was selected successfully, false otherwise.
   */
  bool SetAudioStream(int streamId);

  /**
   * @brief Set audio output routing.
   * 
   * Configures audio routing through the Tizen audio subsystem using
   * player_set_audio_policy_info(). This ensures audio is routed correctly
   * through the TV's audio system.
   * 
   * @return True if audio routing was configured successfully, false otherwise.
   */
  bool ConfigureAudioRouting();

  /**
   * @brief Get list of supported video and audio codecs.
   * 
   * Queries Tizen's media capability APIs to determine which codecs are
   * supported by the device's hardware and software decoders. This information
   * is used by Kodi to determine which media files can be played.
   * 
   * @return Vector of codec names (e.g., "h264", "hevc", "vp9", "aac", "mp3").
   */
  std::vector<std::string> GetSupportedCodecs();

  /**
   * @brief Check if the device supports HDR video playback.
   * 
   * Queries Tizen's display and media capabilities to determine if HDR
   * (High Dynamic Range) video playback is supported. This includes checking
   * for HDR10, HDR10+, and Dolby Vision support.
   * 
   * @return True if HDR is supported, false otherwise.
   */
  bool SupportsHDR();

  /**
   * @brief Configure AVPlay for HDR output.
   * 
   * Configures the Tizen player to output HDR video when HDR content is
   * detected and the display supports HDR. This should be called after
   * opening HDR media and before starting playback.
   * 
   * @return True if HDR configuration succeeded, false otherwise.
   */
  bool ConfigureHDROutput();

  /**
   * @brief Select a subtitle stream for rendering.
   * 
   * Switches to a different subtitle track using player_select_track().
   * This coordinates with Kodi's subtitle renderer to display the selected
   * subtitle stream. The subtitle rendering is handled by Kodi's overlay
   * system, not by the Tizen player directly.
   * 
   * @param streamId The ID of the subtitle stream to select.
   * @return True if the subtitle stream was selected successfully, false otherwise.
   */
  bool SetSubtitleStream(int streamId);

private:
  /**
   * @brief Register AVPlay callbacks with the Tizen player.
   * 
   * Registers callback functions for player state changes, errors, and
   * buffering progress using player_set_*_cb() functions. This should be
   * called after player creation during initialization.
   * 
   * @return True if callbacks were registered successfully, false otherwise.
   */
  bool RegisterCallbacks();

  /**
   * @brief Unregister AVPlay callbacks from the Tizen player.
   * 
   * Unregisters all callback functions by setting them to nullptr.
   * This should be called before player destruction during finalization.
   */
  void UnregisterCallbacks();

#if defined(TARGET_TIZEN)
  /**
   * @brief Callback for player state changes.
   * 
   * Called by the Tizen player when the playback state changes (e.g., from
   * playing to paused, or from buffering to playing). This callback is used
   * to synchronize the player state with Kodi's player interface.
   * 
   * @param state The new player state.
   * @param userData Pointer to the CMediaPipelineTizen instance.
   */
  static void OnPlayerStateChanged(player_state_e state, void* userData);

  /**
   * @brief Callback for player errors.
   * 
   * Called by the Tizen player when an error occurs during playback (e.g.,
   * codec not supported, network failure, file not found). This callback
   * propagates errors to Kodi's error handling system.
   * 
   * @param errorCode The Tizen player error code.
   * @param userData Pointer to the CMediaPipelineTizen instance.
   */
  static void OnPlayerError(int errorCode, void* userData);

  /**
   * @brief Callback for buffering progress.
   * 
   * Called by the Tizen player during buffering to report progress.
   * This is particularly important for network streams where buffering
   * may occur frequently.
   * 
   * @param percent The buffering progress percentage (0-100).
   * @param userData Pointer to the CMediaPipelineTizen instance.
   */
  static void OnBufferingProgress(int percent, void* userData);
#endif

private:
#if defined(TARGET_TIZEN)
  /**
   * @brief Handle to the Tizen AVPlay player instance.
   * 
   * This is the native Tizen player handle obtained from player_create().
   * It is used for all subsequent player operations (set URI, prepare, play, etc.).
   */
  player_h m_player;
#else
  void* m_player; // Placeholder for non-Tizen builds
#endif

  /**
   * @brief Initialization state flag.
   * 
   * Tracks whether the pipeline has been successfully initialized.
   * Used to prevent double initialization and ensure proper cleanup.
   */
  bool m_initialized;

  /**
   * @brief Media open state flag.
   * 
   * Tracks whether media has been successfully opened and prepared.
   * Used to ensure proper cleanup and prevent operations on closed media.
   */
  bool m_isOpen;
};
