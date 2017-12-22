{-# LANGUAGE  DeriveFoldable
            , DeriveFunctor
            , DeriveTraversable
            , FlexibleContexts
            , TypeFamilies
            , OverloadedStrings
            , LambdaCase
            , TemplateHaskell
  #-}
module Language.Hawk.Syntax.Term.Basic where

import Bound
import Control.Monad
import Data.Default.Class
import Data.Deriving
import Data.Monoid hiding (Alt)
import Data.Set (Set)
import Data.Text (Text)
import Data.String (IsString)

import Language.Hawk.Syntax.Branch
import Language.Hawk.Syntax.GlobalBind
import Language.Hawk.Syntax.Let
import Language.Hawk.Syntax.Literal
import Language.Hawk.Syntax.Location
import Language.Hawk.Syntax.Name
import Language.Hawk.Syntax.Prim

import qualified Text.PrettyPrint.Leijen.Text as PP
import qualified Data.Set as Set


-- -----------------------------------------------------------------------------
-- | Terms


type Type = Term

-- Basic Dependent Term
data Term v
  = TVar  v
  | TGlobal Text
  | TLit  Lit
  | TCon  Text [Term v]
  | TCall (Term v) [Term v]
  | TPrimCall PrimInstr (Term v) (Term v)

  | TLet NameHint  (LetRec Term v) (Scope () Term v)
  
  | TCase (Term v) (Branches Text () Term v)
  
  | TDup  v
  | TFree [v] (Term v)

  | TAnnot (Term v) (Type v)
  deriving(Foldable, Functor, Traversable)


-- -----------------------------------------------------------------------------
-- | Default Instances

instance Default (Term v) where
  def = TCon "()"


-- -----------------------------------------------------------------------------
-- | Term Helpers

-- Remove types from a term
untype :: Term v -> Term v
untype = undefine


-- Locations
{-
locTerm :: Term v -> Loc
locTerm = \case
  TVar _ -> error "Cannot locate term without location!"
  TApp a b -> locTerm a <> locTerm b
  TLam n e -> locName' n <> locTerm e
  TLet (n, _) e -> locName' n <> locTerm e
  TLit _ -> error "Cannot locate term without location!"
  TCon _ -> error "Cannot locate term without location!"
  TPrim _ a b -> locTerm a <> locTerm b
  TDup n -> error "Cannot locate term without location!"
  TFree _ t -> locTerm t
  TAnnot t tt -> locTerm t <> locTerm ty
-}



-- Names
termNames :: Term v -> [v]
termNames = \case
  TVar n -> [n]
  _ -> undefined
  

-- -----------------------------------------------------------------------------
-- | Free Variables

class HasFreeVars a where
  fv :: a -> Set Text

  
instance HasFreeVars Text where
  fv = Set.singleton


instance HasFreeVars (Term v) where
  fv = \case
    _ -> undefined

instance HasFreeVars a => HasFreeVars [a] where
  fv = mconcat . map fv


-- -----------------------------------------------------------------------------
-- | Instances

deriveEq1 ''Term
deriveEq ''Term
deriveOrd1 ''Term
deriveOrd ''Term
deriveShow1 ''Term
deriveShow ''Term


instance GlobalBind Term where
  global = Global
  bind f g t = case t of
    Var v -> f v
    Global v -> g v
    Lit l -> Lit l
    Con c es -> Con c (bind f g <$> es)
    Call e es -> Call (bind f g e) (bind f g <$> es)
    PrimCall lang retDir e es -> PrimCall lang retDir (bind f g e) (fmap (bind f g) <$> es)
    Let h e s -> Let h (bind f g e) (bound f g s)
    Case e brs -> Case (bind f g e) (bound f g brs)
    Anno e t -> Anno (bind f g e) (bind f g t)


instance Applicative Term where
  pure = TVar
  (<*>) = ap


instance Monad Term where
  t >>= f = bind f Global t


-- -----------------------------------------------------------------------------
-- | Pretty Instances

instance (PP.Pretty v, IsString v, Eq v) => PP.Pretty (Term v) where
    pretty = \case
      TVar n      -> PP.pretty n
      TGlobal g   -> PP.pretty g
      TLit l      -> PP.pretty l

      TCon c as   -> PP.pretty c PP.<+> PP.hsep (PP.pretty <$> as)
      TCall f xs  -> PP.pretty f PP.<+> PP.hsep (PP.pretty <$> xs)
      TPrimCall i a b -> PP.pretty i PP.<+> PP.pretty a PP.<+> PP.pretty b
      
      TLet h r s -> withNameHint h $ \n ->
          PP.textStrict           "let"
            PP.<$> PP.indent 2 (PP.pretty r)
            PP.<$> PP.textStrict  "in"
            PP.<$> PP.indent 2 (PP.pretty $ instantiate1 (pure $ fromText n) s)
      
      TCase t bs ->
          PP.textStrict           "case"
            PP.<+> PP.pretty       t
            PP.<+> PP.textStrict  "of"
            PP.<$> PP.indent 2 (PP.pretty bs)

      TDup n -> PP.textStrict "dup" PP.<+> PP.pretty n
      TFree ns t ->
          PP.textStrict           "free"
            PP.<+> PP.hsep        (PP.pretty <$> ns)
            PP.<+> PP.textStrict  "in"
            PP.<+> PP.pretty       t


      TAnnot t ty ->
          PP.pretty               t
            PP.<+> PP.textStrict ":"
            PP.<+> PP.pretty      ty
