module Language.Hawk.Syntax.TypeDeclaration where

import Data.Binary
import Data.Data
import Data.Typeable

import Text.PrettyPrint.ANSI.Leijen ((<+>), (<>))
import qualified Text.PrettyPrint.ANSI.Leijen as PP

import qualified Language.Hawk.Syntax.Name as N
import qualified Language.Hawk.Syntax.QType as QT
import qualified Language.Hawk.Syntax.Type as T


data TypeDecl n t
  = TypeDecl
    { tydef_context :: QT.Context t
    , tydef_name :: n
    , tydef_tyvars :: [t]
    }
  deriving (Eq, Show, Ord, Data, Typeable)
  
  
instance (PP.Pretty n, PP.Pretty t) => PP.Pretty (TypeDecl n t) where
    pretty (TypeDecl c n vs) =
      PP.text "Type Declaration:"
      PP.<$>
      PP.indent 2
        ( PP.text "Name:" <+> PP.pretty n
          PP.<$>
          PP.text "Context:" <+> PP.pretty c
          PP.<$>
          PP.text "Vars:" <+> PP.pretty vs
        )
        
  
instance (Binary n, Binary t) => Binary (TypeDecl n t) where
  get =
    TypeDecl <$> get <*> get <*> get

  put (TypeDecl c n v) =
    put c >> put n >> put v