module Language.Hawk.Syntax.ExpressionDeclaration where

import Data.Binary
import Data.Data
import Data.Typeable
import Text.PrettyPrint.ANSI.Leijen ((<+>), (<>))

import qualified Data.Text.Lazy                   as Text
import qualified Text.PrettyPrint.ANSI.Leijen     as PP

import qualified Language.Hawk.Parse.Lexer        as Lex
import qualified Language.Hawk.Syntax.Name        as N
import qualified Language.Hawk.Syntax.OpInfo      as OI
import qualified Language.Hawk.Syntax.Type        as T


type Source
  = ExprDecl N.Source T.Source

type Valid
  = ExprDecl N.Valid T.Valid

type Typed
  = ExprDecl N.Typed T.Typed


data ExprDecl n t
  = ExprDecl 
    { expr_name  :: n
    , expr_op    :: OI.OpInfo
    , expr_type  :: t
    }
  deriving (Eq, Show, Ord, Data, Typeable)

      

instance (PP.Pretty n, PP.Pretty t) => PP.Pretty (ExprDecl n t) where
  pretty (ExprDecl name opinf tipe) =
    PP.text "Expression Declaration:"
    PP.<$>
    PP.indent 2
      ( PP.text "name:" <+> PP.pretty name
        PP.<$>
        PP.text "op info:" <+> PP.pretty opinf
        PP.<$>
        PP.text "type:" <+> PP.pretty tipe
      )
  
  
instance (Binary n, Binary t) => Binary (ExprDecl n t) where
  get =
      ExprDecl <$> get <*> get <*> get
      
  put (ExprDecl oi n t) =
      put n >> put oi >> put t