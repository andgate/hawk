{-# LANGUAGE  GeneralizedNewtypeDeriving
            , TemplateHaskell
            , OverloadedStrings
            , LambdaCase
  #-}
module Language.CPS.Target.LLVM.Codegen where

import Control.Lens
import Data.ByteString.Short (ShortByteString)
import Data.Text (Text)
import Language.CPS.Syntax
import Language.CPS.Target.LLVM.Instruction
import Language.CPS.Target.LLVM.IR
import Language.CPS.Target.LLVM.Module
import LLVM.Pretty

import LLVM.AST hiding (function)
import LLVM.AST.Type as AST

import qualified Data.ByteString.Short  as BS
import qualified LLVM.AST.Float         as F
import qualified LLVM.AST.Constant      as C
import qualified Data.Text.Encoding     as T


codegen :: Program -> Module
codegen p =
  buildModule "example" [] $
    mapM cgLambda (p^.cpsLambdas)


cgLambda
  :: (MonadModuleBuilder m)
  => Lambda -> m Operand
cgLambda (Lambda n e) =
  codegenTerm e



codegenTerm :: Term -> m Operand
codegenTerm = \case
  Let n b e -> undefined
  If p a b -> undefined
  Free xs a -> undefined
  Jump a b -> undefined
  Halt a -> undefined
  

codegenValue :: Value -> m Operand
codegenValue = \case
  Lit l -> undefined
  Var n -> undefined
  Use n -> undefined
  Dup n -> undefined
  Lam n e -> undefined