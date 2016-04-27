module Language.Hawk.Parse.Utils where

import Data.Monoid

import Language.Hawk.Syntax.AST
import Language.Hawk.Data.Node

-----------------------------------------------------------------------------
-- Various Syntactic Checks

checkContext :: [HkTypeNode] -> HkTypeContextNode
checkContext = map checkAssertion

checkAssertion :: HkTypeNode -> HkClassAsstNode
checkAssertion = checkAssertion' []
  where
    checkAssertion' ts (HkTyCon c a) = HkClassAsst c ts (nodeInfo a <> nodesInfo ts)
    checkAssertion' ts (HkTyApp ap t _) = checkAssertion' (t:ts) ap
    checkAssertion' _ t = error $ showNode t ++ ": Illegal class assertion." 