/*
 *  Copyright (C) 2024 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "addons/AddonManager.h"
#include "addons/Skin.h"
#include "filesystem/Directory.h"
#include "filesystem/File.h"
#include "utils/URIUtils.h"
#include "utils/XBMCTinyXML2.h"

#include <gtest/gtest.h>

#ifdef TARGET_TIZEN

/**
 * Test suite for verifying Kodi skin format compatibility on Tizen platform.
 * 
 * These tests ensure that:
 * - Skin XML files can be parsed correctly
 * - Skin resources (images, fonts) can be loaded
 * - Skin format is compatible with Tizen's file system and rendering
 * 
 * Requirements: 13.3
 */
class TestTizenSkinCompatibility : public ::testing::Test
{
protected:
  void SetUp() override
  {
    // Test data paths
    m_skinPath = "addons/skin.estuary";
    m_homeXmlPath = URIUtils::AddFileToFolder(m_skinPath, "xml/Home.xml");
    m_includesPath = URIUtils::AddFileToFolder(m_skinPath, "xml/Includes.xml");
    m_fontsXmlPath = URIUtils::AddFileToFolder(m_skinPath, "xml/Font.xml");
  }

  std::string m_skinPath;
  std::string m_homeXmlPath;
  std::string m_includesPath;
  std::string m_fontsXmlPath;
};

/**
 * Test that the default skin (skin.estuary) exists and has required structure
 */
TEST_F(TestTizenSkinCompatibility, DefaultSkinExists)
{
  // Verify skin directory exists
  EXPECT_TRUE(XFILE::CDirectory::Exists(m_skinPath))
      << "Default skin directory not found: " << m_skinPath;

  // Verify addon.xml exists
  std::string addonXmlPath = URIUtils::AddFileToFolder(m_skinPath, "addon.xml");
  EXPECT_TRUE(XFILE::CFile::Exists(addonXmlPath))
      << "Skin addon.xml not found: " << addonXmlPath;

  // Verify Home.xml exists (required for all skins)
  EXPECT_TRUE(XFILE::CFile::Exists(m_homeXmlPath))
      << "Home.xml not found: " << m_homeXmlPath;
}

/**
 * Test that skin XML files can be parsed correctly on Tizen
 */
TEST_F(TestTizenSkinCompatibility, SkinXmlParsing)
{
  // Test parsing Home.xml
  CXBMCTinyXML2 homeXml;
  EXPECT_TRUE(homeXml.LoadFile(m_homeXmlPath))
      << "Failed to parse Home.xml: " << m_homeXmlPath;

  // Verify it has a window element
  auto* root = homeXml.RootElement();
  ASSERT_NE(root, nullptr) << "Home.xml has no root element";
  EXPECT_STREQ(root->Value(), "window") << "Home.xml root element is not 'window'";

  // Test parsing Includes.xml if it exists
  if (XFILE::CFile::Exists(m_includesPath))
  {
    CXBMCTinyXML2 includesXml;
    EXPECT_TRUE(includesXml.LoadFile(m_includesPath))
        << "Failed to parse Includes.xml: " << m_includesPath;

    auto* includesRoot = includesXml.RootElement();
    ASSERT_NE(includesRoot, nullptr) << "Includes.xml has no root element";
    EXPECT_STREQ(includesRoot->Value(), "includes")
        << "Includes.xml root element is not 'includes'";
  }
}

/**
 * Test that skin resource directories exist and are accessible
 */
TEST_F(TestTizenSkinCompatibility, SkinResourceDirectories)
{
  // Check for media directory (contains images)
  std::string mediaPath = URIUtils::AddFileToFolder(m_skinPath, "media");
  EXPECT_TRUE(XFILE::CDirectory::Exists(mediaPath))
      << "Skin media directory not found: " << mediaPath;

  // Check for fonts directory
  std::string fontsPath = URIUtils::AddFileToFolder(m_skinPath, "fonts");
  EXPECT_TRUE(XFILE::CDirectory::Exists(fontsPath))
      << "Skin fonts directory not found: " << fontsPath;

  // Check for xml directory
  std::string xmlPath = URIUtils::AddFileToFolder(m_skinPath, "xml");
  EXPECT_TRUE(XFILE::CDirectory::Exists(xmlPath))
      << "Skin xml directory not found: " << xmlPath;
}

/**
 * Test that skin font definitions can be parsed
 */
TEST_F(TestTizenSkinCompatibility, SkinFontDefinitions)
{
  if (!XFILE::CFile::Exists(m_fontsXmlPath))
  {
    GTEST_SKIP() << "Font.xml not found, skipping font definition test";
  }

  CXBMCTinyXML2 fontXml;
  EXPECT_TRUE(fontXml.LoadFile(m_fontsXmlPath))
      << "Failed to parse Font.xml: " << m_fontsXmlPath;

  auto* root = fontXml.RootElement();
  ASSERT_NE(root, nullptr) << "Font.xml has no root element";

  // Check for fontset elements
  auto* fontset = root->FirstChildElement("fontset");
  EXPECT_NE(fontset, nullptr) << "Font.xml has no fontset element";

  if (fontset)
  {
    // Check for font elements within fontset
    auto* font = fontset->FirstChildElement("font");
    EXPECT_NE(font, nullptr) << "Fontset has no font elements";
  }
}

/**
 * Test that skin image resources exist
 */
TEST_F(TestTizenSkinCompatibility, SkinImageResources)
{
  std::string mediaPath = URIUtils::AddFileToFolder(m_skinPath, "media");
  
  if (!XFILE::CDirectory::Exists(mediaPath))
  {
    GTEST_SKIP() << "Media directory not found, skipping image resource test";
  }

  // List files in media directory
  XFILE::CFileItemList items;
  EXPECT_TRUE(XFILE::CDirectory::GetDirectory(mediaPath, items, "", XFILE::DIR_FLAG_DEFAULTS))
      << "Failed to list media directory contents";

  // Should have at least some image files or .xbt texture files
  EXPECT_GT(items.Size(), 0) << "Media directory is empty";

  // Check for common image formats or .xbt files
  bool hasImageResources = false;
  for (int i = 0; i < items.Size(); ++i)
  {
    const auto& item = items[i];
    std::string ext = URIUtils::GetExtension(item->GetPath());
    if (ext == ".png" || ext == ".jpg" || ext == ".xbt")
    {
      hasImageResources = true;
      break;
    }
  }

  EXPECT_TRUE(hasImageResources)
      << "No image resources (.png, .jpg, .xbt) found in media directory";
}

/**
 * Test that skin addon.xml is valid and contains required metadata
 */
TEST_F(TestTizenSkinCompatibility, SkinAddonMetadata)
{
  std::string addonXmlPath = URIUtils::AddFileToFolder(m_skinPath, "addon.xml");
  
  CXBMCTinyXML2 addonXml;
  ASSERT_TRUE(addonXml.LoadFile(addonXmlPath))
      << "Failed to parse addon.xml: " << addonXmlPath;

  auto* root = addonXml.RootElement();
  ASSERT_NE(root, nullptr) << "addon.xml has no root element";
  EXPECT_STREQ(root->Value(), "addon") << "addon.xml root element is not 'addon'";

  // Check for required attributes
  const char* id = root->Attribute("id");
  EXPECT_NE(id, nullptr) << "addon.xml missing 'id' attribute";
  EXPECT_STREQ(id, "skin.estuary") << "Unexpected skin ID";

  const char* version = root->Attribute("version");
  EXPECT_NE(version, nullptr) << "addon.xml missing 'version' attribute";

  // Check for extension point
  auto* extension = root->FirstChildElement("extension");
  EXPECT_NE(extension, nullptr) << "addon.xml has no extension element";

  if (extension)
  {
    const char* point = extension->Attribute("point");
    EXPECT_NE(point, nullptr) << "extension missing 'point' attribute";
    EXPECT_STREQ(point, "xbmc.gui.skin") << "extension point is not 'xbmc.gui.skin'";
  }
}

#endif // TARGET_TIZEN
