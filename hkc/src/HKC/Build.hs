module HKC.Build where

--import Data.Yaml


data Build = Build
  { srcPath :: String
  }

{-instance FromJSON Build where
  parseJSON (Object v) =
    Build <$>
      v .: "files" <*>
      v .: "maxFPS" <*>
      v .: "width" <*>
      v .: "height" <*>
      v .: "isFullscreen"
  -- A non-Object value is of the wrong type, so fail.
  parseJSON _ = empty
-}
