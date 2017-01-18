module Lib
    ( someFunc
    ) where

import Options.Applicative
import Network.HTTP
import Text.HTML.TagSoup
import Data.Maybe
data Option = Option
  { url :: String
  , explore :: Bool }

sample :: Parser Option
sample = Option
     <$> strOption
         ( long "url"
        <> short 'u'
        <> metavar "URL"
        <> help "URL from which we want to download" )
     <*> switch
         ( long "explore"
        <> short 'e'
        <> help "Whether to explore the URL and report the resources available" )

process :: Option -> IO ()
process (Option u False) = putStrLn $ "So, you want to download from " ++ u
process (Option u True) = getStatistics u

sampleUrl :: String
sampleUrl = "http://stanford.edu/~pyzhang/publication.html"

-- | count how many files of each type from a website 
getStatistics :: String -> IO ()
getStatistics url = do
  src <- getResponseBody =<< simpleHTTP (getRequest url)
  let tags = parseTags src
  let a_tags = getATags tags
  let links = map fromJust $ filter isJust $ map extractLink a_tags
  putStrLn $ "Getting statistics from " ++ url ++ "..."
  putStrLn $ "Display all links..."
  mapM_ putStrLn links

-- | get all tags <a ...>
getATags :: [Tag String] -> [Tag String]
getATags tags = filter f tags
  where f (TagOpen "a" _) = True
        f _ = False 

-- | extract link from <a ...> tag -- heavily template matching :(
extractLink :: Tag String -> Maybe String
extractLink (TagOpen "a" listparams) = go listparams
  where go lps = case lps of
          [] -> Nothing
          p : ps -> case p of
            ("href", link) -> Just link
            _ -> go ps          
extractLink _ = Nothing


            
someFunc :: IO ()
someFunc = execParser opts >>= process
  where
    opts = info (helper <*> sample)
      ( fullDesc
     <> progDesc "Download resources from a website"
     <> header "dl - Download resources from a website" )
         
