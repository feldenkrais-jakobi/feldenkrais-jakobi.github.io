{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

import Data.Functor ((<&>))
import Data.List (isSuffixOf)
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
      pages <- getMatches "pages/**"
      let urls = pageUrl <$> pages
      route idRoute
      compile . makeItem $ sitemap urls

    match "templates/*" $ compile templateBodyCompiler
  where
    sitemap urls =
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        <> "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
        <> mconcat (urls <&> \u -> "  <url><loc>" <> siteUrl <> u <> "</loc></url>\n")
        <> "</urlset>\n"

    siteUrl :: String
    siteUrl = "https://feldenkrais-jakobi.de"

    pageUrl identifier
      | toFilePath identifier == "pages/index.markdown" = "/"
      | otherwise = "/" <> toHtml (drop 6 $ toFilePath identifier)

    toHtml path = stripSuffix' ".markdown" path <> ".html"

    stripSuffix' :: (Eq a) => [a] -> [a] -> [a]
    stripSuffix' suffix str
      | suffix `isSuffixOf` str = take (length str - length suffix) str
      | otherwise = str

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
