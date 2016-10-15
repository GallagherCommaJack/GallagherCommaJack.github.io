--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Foldable
import           Data.List
import qualified Data.Set as S
import           Text.Pandoc.Options
import           Hakyll


--------------------------------------------------------------------------------
dashSlashSlashDelete :: (Show a, Show b, Show c) => a -> b -> c -> Routes
dashSlashSlashDelete a b c = let sa = show a
                                 sb = if length (show b) < 2 then '0':show b else show b
                                 sc = if length (show c) < 2 then '0':show c else show c
                             in gsubRoute (fold $ intersperse "-" [sa, sb, sc, ""])
                                          (const $ fold $ intersperse "/" [sa, sb, ""])  -- gsubRoute apparently succeeds even when it should fail
                                `composeRoutes` matchRoute (fromGlob "*/*/*") idRoute -- this oughta fix that


dashSlashList :: (Show a, Show b, Show c) => [a] -> [b] -> [c] -> [Routes]
dashSlashList as bs cs = [dashSlashSlashDelete a b c | a <- as, b <- bs, c <- cs]

dashSlashFoldList :: (Show a, Show b, Show c) => [a] -> [b] -> [c] -> Routes
dashSlashFoldList as bs cs = fold $ dashSlashList as bs cs

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    -- match "redirected.md" $ do
    --   route $ setExtension "html"
    --   compile $ pandocCompiler
    --         >>= loadAndApplyTemplate "templates/default.html" defaultContext
    --         >>= relativizeUrls

    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "about.org" $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html" `composeRoutes` gsubRoute "posts/" (const "") `composeRoutes` dashSlashFoldList [2010..2020] [1..12] [1..31]
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "files/*" $ do
      route idRoute
      compile copyFileCompiler

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let posts' = take 3 posts
            let indexCtx =
                    listField "posts" postCtx (return posts') `mappend`
                    constField "title" "Home"                  `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler
    -- match "redirects.txt" $ do
    --   route $ constRoute ".htaccess"
    --   compile $ makeItem "" >>=
    --     loadAndApplyTemplate "templates/htaccess" (metadataField `mappend` defaultContext)

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext
