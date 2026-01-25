/*
 *  Copyright (C) 2025 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "MediaPipelineTizen.h"

#include "utils/log.h"

#if defined(TARGET_TIZEN)
#include <player.h>
#endif

CMediaPipelineTizen::CMediaPipelineTizen()
  : m_player(nullptr), m_initialized(false)
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

  if (m_player != nullptr)
  {
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
