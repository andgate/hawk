module Language.Hawk.Compile.Package where

import Data.Aeson
import Data.Binary
import qualified Data.Char as Char
import Data.Function (on)
import qualified Data.List as List
import qualified Data.Text as T
import System.FilePath ((</>))


-- | The package type
type Package = (Name, Version)

-- | Package name
data Name
  = Name
    { user    :: String
    , project :: String
    }
    deriving (Eq, Ord, Show)


dummyName :: Name
dummyName =
  Name "user" "project"
  
core :: Name
core =
  Name "hawk-lang" "core"
 
toString :: Name -> String
toString name =
  user name ++ "/" ++ project name
  
toFilePath :: Name -> FilePath
toFilePath name =
  user name </> project name
  

fromString :: String -> Either String Name
fromString string =
  case break (== '/') string of
    (user, '/' : project) ->
      if null user then
        Left "You did not provide a user name (user/project)"
        
      else if null project then
        Left "You did not provide a project name (user/project)"
        
      else if all (/= '/') project then
        Name user <$> validateProjectName project
        
      else
        Left "Expecting only one slash seperating the user and project name (user/project)"
    
    _ ->
      Left "There should be a slash seperating the user and project name (user/project)"
      


validateProjectName :: String -> Either String String
validateProjectName str =
  if elem ('-', '-') (zip str (tail str)) then
    Left "There is a double dash in your package name. It must be a single dash."
    
  else if elem '_' str then
    Left "Underscores are not allowed in package names."
    
  else if any Char.isUpper str then
    Left "Upper case characters are not allowed in package names."
    
  else if not (Char.isLetter (head str)) then
    Left "Package names must start with a letter."
    
  else
    Right str
    

instance Binary Name where
  get = Name <$> get <*> get
  put (Name user project) =
    do  put user
        put project
    

instance FromJSON Name where
  parseJSON (String text) =
    let 
      string = T.unpack text 
    in 
      case fromString string of
        Left msg ->
          fail ("Ran into an invalid package name: " ++ string ++ "\n\n" ++ msg)
        
        Right name ->
          return name
          
  parseJSON _ =
    fail "Project name must be a string."
    
    
instance ToJSON Name where
  toJSON name =   
    toJSON (toString name)
    
    
-- | Package Version
data Version
  = Version
    { _major :: Int
    , _minor :: Int
    , _patch :: Int
    }
    deriving (Eq, Ord)
    

initialVersion :: Version
initialVersion =
  Version 1 0 0
  

dummyVersion :: Version
dummyVersion =
  Version 0 0 0

  
bumpPatch :: Version -> Version
bumpPatch (Version major minor patch) =
  Version major minor (patch + 1)
  
bumpMinor :: Version -> Version
bumpMinor (Version major minor _) =
  Version major (minor + 1) 0
  
bumpMajor :: Version -> Version
bumpMajor (Version major _ _) =
  Version (major + 1) 0 0
  

filterLast :: (Ord a) => (Version -> a) -> [Version] -> [Version]
filterLast characteristic versions =
  map last $
    List.groupBy ((==) `on` characteristic ) (List.sort versions)
    
majorAndMinor :: Version -> (Int, Int)
majorAndMinor (Version major minor _) =
  (major, minor)
  
  
versionToString :: Version -> String
versionToString (Version major minor patch) =
  show major ++ "." ++ show minor ++ "." ++ show patch
  
versionFromString :: String -> Either String Version
versionFromString string =
  case splitNumbers string of
    Just [major, minor, patch] ->
      Right (Version major minor patch)
    _ ->
      Left "Must have format MAJOR.MINOR.PATCH (e.g. 1.0.2)"
  where
    splitNumbers :: String -> Maybe [Int]
    splitNumbers ns =
      case span Char.isDigit ns of
        ("", _) ->
          Nothing
        
        (numbers, []) ->
          Just [read numbers]
          
        _ ->
          Nothing


instance Binary Version where
  get = Version <$> get <*> get <*> get
  put (Version major minor patch) =
    do  put major
        put minor
        put patch
        
        
instance FromJSON Version where
  parseJSON (String text) =
    let string = T.unpack text in
    case versionFromString string of
      Right v ->
        return v
        
      Left problem ->
        fail $ unlines
          [ "Ran into an invalid version number: " ++ string
          , problem
          ]
          
  parseJSON _ =
    fail "version must be stored as a string."
    

instance ToJSON Version where
  toJSON version =
    toJSON (versionToString version)