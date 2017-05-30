{-# LANGUAGE DeriveDataTypeable #-}
module Language.Hawk.Syntax.ExpressionDefinition where

import Data.Binary
import Data.Data
import Data.Typeable
import Text.PrettyPrint.ANSI.Leijen ((<+>), (<>))

import qualified Data.Text                        as Text
import qualified Text.PrettyPrint.ANSI.Leijen     as PP

import qualified Language.Hawk.Syntax.Expression  as E
import qualified Language.Hawk.Syntax.ExpressionDeclaration  as ED
import qualified Language.Hawk.Syntax.Name        as N
import qualified Language.Hawk.Syntax.OpInfo      as OI
import qualified Language.Hawk.Syntax.Type        as T


type Source
  = ExprDef N.Source E.Source T.Source

type Valid
  = ExprDef N.Valid E.Source T.Valid

type Typed
  = ExprDef N.Typed E.Source T.Typed


data ExprDef n e t
  = ExprDef 
    { exprDecl  :: ED.ExprDecl n t
    , exprName  :: e
    }
  deriving (Eq, Show, Ord, Data, Typeable)

      
      
instance (PP.Pretty n, PP.Pretty e, PP.Pretty t) => PP.Pretty (ExprDef n e t) where
  pretty (ExprDef ed e) =
    PP.text "Expression Declaration:"
    PP.<$>
    PP.indent 2
      ( PP.text "decl:" <+> PP.pretty ed
        PP.<$>
        PP.text "expression:" <+> PP.pretty e
      )
  
  
instance (Binary n, Binary e, Binary t) => Binary (ExprDef n e t) where
  get =
      ExprDef <$> get <*> get
      
  put (ExprDef ed e) =
      put ed >> put e