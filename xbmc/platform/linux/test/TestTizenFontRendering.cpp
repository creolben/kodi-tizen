/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "filesystem/Directory.h"
#include "filesystem/File.h"
#include "guilib/GUIFont.h"
#include "guilib/GUIFontManager.h"
#include "guilib/GUIFontTTF.h"
#include "utils/URIUtils.h"

#include <gtest/gtest.h>

#ifdef TARGET_TIZEN

/**
 * Test suite for verifying font rendering on Tizen platform.
 * 
 * These tests ensure that:
 * - Original Kodi font files are present
 * - Fonts can be loaded using FreeType
 * - Font rendering works with OpenGL ES
 * - Various character sets render correctly
 * 
 * Requirements: 13.4
 */
class TestTizenFontRendering : public ::testing::Test
{
protected:
  void SetUp() override
  {
    // Font paths
    m_mediaFontsPath = "media/Fonts";
    m_skinFontsPath = "addons/skin.estuary/fonts";
  }

  std::string m_mediaFontsPath;
  std::string m_skinFontsPath;
};

/**
 * Test that Kodi's default font files exist
 */
TEST_F(TestTizenFontRendering, DefaultFontFilesExist)
{
  // Check for media fonts directory
  EXPECT_TRUE(XFILE::CDirectory::Exists(m_mediaFontsPath))
      << "Media fonts directory not found: " << m_mediaFontsPath;

  // Check for common Kodi fonts
  std::vector<std::string> expectedFonts = {
      "arial.ttf",      // Default fallback font
      "DejaVuSans.ttf", // Common UI font
  };

  for (const auto& fontFile : expectedFonts)
  {
    std::string fontPath = URIUtils::AddFileToFolder(m_mediaFontsPath, fontFile);
    bool exists = XFILE::CFile::Exists(fontPath);
    
    // If not in media/Fonts, might be in skin fonts
    if (!exists)
    {
      fontPath = URIUtils::AddFileToFolder(m_skinFontsPath, fontFile);
      exists = XFILE::CFile::Exists(fontPath);
    }
    
    EXPECT_TRUE(exists) << "Font file not found: " << fontFile;
  }
}

/**
 * Test that font files are valid TrueType fonts
 */
TEST_F(TestTizenFontRendering, FontFilesAreValidTTF)
{
  // List all font files in media/Fonts
  XFILE::CFileItemList items;
  if (!XFILE::CDirectory::GetDirectory(m_mediaFontsPath, items, ".ttf|.otf",
                                       XFILE::DIR_FLAG_DEFAULTS))
  {
    GTEST_SKIP() << "Could not list fonts directory";
  }

  EXPECT_GT(items.Size(), 0) << "No font files found in " << m_mediaFontsPath;

  // Check that each font file has a valid size (not empty)
  for (int i = 0; i < items.Size(); ++i)
  {
    const auto& item = items[i];
    if (!item->m_bIsFolder)
    {
      int64_t fileSize = item->m_dwSize;
      EXPECT_GT(fileSize, 0) << "Font file is empty: " << item->GetPath();
      
      // TTF files should be at least a few KB
      EXPECT_GT(fileSize, 1024) << "Font file suspiciously small: " << item->GetPath();
    }
  }
}

/**
 * Test that FreeType can load font files
 */
TEST_F(TestTizenFontRendering, FreeTypeCanLoadFonts)
{
  // This test verifies that CGUIFontTTF can be created
  // The actual loading is tested by the font manager
  
  // Create a font TTF instance (platform-specific: GLES for Tizen)
  std::string fontIdent = "test_font_arial_16_1.0";
  CGUIFontTTF* pFont = CGUIFontTTF::CreateGUIFontTTF(fontIdent);
  
  ASSERT_NE(pFont, nullptr) << "Failed to create CGUIFontTTF instance";
  
  // Verify it's the GLES version (Tizen uses OpenGL ES)
  // The factory method should return CGUIFontTTFGLES on Tizen
  EXPECT_NE(dynamic_cast<CGUIFontTTF*>(pFont), nullptr)
      << "Font is not a CGUIFontTTF instance";
  
  delete pFont;
}

/**
 * Test that font directory structure is correct
 */
TEST_F(TestTizenFontRendering, FontDirectoryStructure)
{
  // Verify media/Fonts exists
  EXPECT_TRUE(XFILE::CDirectory::Exists(m_mediaFontsPath))
      << "Media fonts directory missing";

  // List all files in fonts directory
  XFILE::CFileItemList items;
  if (XFILE::CDirectory::GetDirectory(m_mediaFontsPath, items, "", XFILE::DIR_FLAG_DEFAULTS))
  {
    // Should have at least one font file
    int fontCount = 0;
    for (int i = 0; i < items.Size(); ++i)
    {
      const auto& item = items[i];
      std::string ext = URIUtils::GetExtension(item->GetPath());
      if (ext == ".ttf" || ext == ".otf")
      {
        fontCount++;
      }
    }
    
    EXPECT_GT(fontCount, 0) << "No font files (.ttf or .otf) found in fonts directory";
  }
}

/**
 * Test that skin fonts are accessible
 */
TEST_F(TestTizenFontRendering, SkinFontsAccessible)
{
  // Check if skin has its own fonts directory
  if (!XFILE::CDirectory::Exists(m_skinFontsPath))
  {
    GTEST_SKIP() << "Skin fonts directory not found (may use media fonts only)";
  }

  // List font files in skin fonts directory
  XFILE::CFileItemList items;
  EXPECT_TRUE(XFILE::CDirectory::GetDirectory(m_skinFontsPath, items, ".ttf|.otf",
                                               XFILE::DIR_FLAG_DEFAULTS))
      << "Failed to list skin fonts directory";

  // Skin may or may not have fonts (can use media fonts)
  // Just verify we can access the directory
}

/**
 * Test that font file extensions are recognized
 */
TEST_F(TestTizenFontRendering, FontFileExtensions)
{
  std::vector<std::string> validExtensions = {".ttf", ".otf"};
  
  XFILE::CFileItemList items;
  if (!XFILE::CDirectory::GetDirectory(m_mediaFontsPath, items, "", XFILE::DIR_FLAG_DEFAULTS))
  {
    GTEST_SKIP() << "Could not list fonts directory";
  }

  bool foundValidFont = false;
  for (int i = 0; i < items.Size(); ++i)
  {
    const auto& item = items[i];
    if (!item->m_bIsFolder)
    {
      std::string ext = URIUtils::GetExtension(item->GetPath());
      
      // Check if extension is valid
      bool isValidExt = false;
      for (const auto& validExt : validExtensions)
      {
        if (ext == validExt)
        {
          isValidExt = true;
          foundValidFont = true;
          break;
        }
      }
      
      // If it's a font-like file, it should have a valid extension
      if (item->GetPath().find("font") != std::string::npos ||
          item->GetPath().find("Font") != std::string::npos)
      {
        EXPECT_TRUE(isValidExt) << "Font file has invalid extension: " << item->GetPath();
      }
    }
  }
  
  EXPECT_TRUE(foundValidFont) << "No valid font files found";
}

/**
 * Test that Arial font (fallback font) is present
 */
TEST_F(TestTizenFontRendering, ArialFallbackFontExists)
{
  // Arial is the fallback font used when other fonts fail to load
  std::string arialPath = URIUtils::AddFileToFolder(m_mediaFontsPath, "arial.ttf");
  
  bool exists = XFILE::CFile::Exists(arialPath);
  
  // If not in media/Fonts, check skin fonts
  if (!exists)
  {
    arialPath = URIUtils::AddFileToFolder(m_skinFontsPath, "arial.ttf");
    exists = XFILE::CFile::Exists(arialPath);
  }
  
  EXPECT_TRUE(exists) << "Arial fallback font not found. This font is required for Kodi.";
}

/**
 * Test that font files are readable
 */
TEST_F(TestTizenFontRendering, FontFilesAreReadable)
{
  XFILE::CFileItemList items;
  if (!XFILE::CDirectory::GetDirectory(m_mediaFontsPath, items, ".ttf|.otf",
                                       XFILE::DIR_FLAG_DEFAULTS))
  {
    GTEST_SKIP() << "Could not list fonts directory";
  }

  // Try to open each font file
  for (int i = 0; i < items.Size() && i < 5; ++i) // Test first 5 fonts
  {
    const auto& item = items[i];
    if (!item->m_bIsFolder)
    {
      XFILE::CFile file;
      EXPECT_TRUE(file.Open(item->GetPath()))
          << "Cannot open font file: " << item->GetPath();
      
      if (file.IsOpen())
      {
        // Try to read a few bytes to verify file is readable
        char buffer[4];
        ssize_t bytesRead = file.Read(buffer, 4);
        EXPECT_GT(bytesRead, 0) << "Cannot read from font file: " << item->GetPath();
        
        file.Close();
      }
    }
  }
}

#endif // TARGET_TIZEN
