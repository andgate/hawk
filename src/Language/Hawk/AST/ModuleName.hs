module Language.Hawk.AST.ModuleName where

import Data.Binary
import qualified Data.List as List

import qualified Language.Hawk.Compile.Package as Package

type Raw = [String]
  
data Name
  = Name
    { _package  :: Package.Name
    , _module   :: Raw
    }
    deriving (Eq, Ord, Show)
    
    
inCore :: [String] -> Name
inCore raw =
  Name Package.core raw
  

toString :: Name -> String
toString (Name _ name) =
  List.intercalate "." name
      
      
instance Binary Name where
  put (Name pkg name) =
    put pkg >> put name
    
  get =
    Name <$> get <*> get