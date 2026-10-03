{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

import Hakyll
import Prelude
import Text.Pandoc.Extensions (Extension (Ext_smart), disableExtension)
import Text.Pandoc.Options (ReaderOptions (readerExtensions))

main :: IO ()
main =
  hakyll do
    mapM_ copyAssets ["theme/**", "media/**", "plugins/**", "images/**", "CNAME"]

    match "pages/**" do
      route $ gsubRoute "pages/" (const "") `composeRoutes` setExtension "html"
      compile do
        body <- pandocCompilerWith readerOptions defaultHakyllWriterOptions
        template <- getTemplate
        (maybe pure (`loadAndApplyTemplate` defaultContext) template body)
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    match "content/*" $ compile templateBodyCompiler

    match "robots.txt" do
      route idRoute
      compile copyFileCompiler

    create ["sitemap.xml"] do
      route idRoute
      compile $ do
        pages <- loadAll "pages/**"
        makeItem $ sitemap pages

    match "templates/*" $ compile templateBodyCompiler
  where
    getTemplate = do
      identifier <- getUnderlying
      fmap (fromFilePath . ("templates/" <>)) <$> getMetadataField identifier "template"

    copyAssets pattern' =
      match pattern' do
        route idRoute
        compile copyFileCompiler

    readerOptions =
      defaultHakyllReaderOptions
        { readerExtensions =
            disableExtension Ext_smart $ readerExtensions defaultHakyllReaderOptions
        }
