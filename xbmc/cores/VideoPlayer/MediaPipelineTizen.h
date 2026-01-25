/*
 *  Copyright (C) 2025 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

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
};
