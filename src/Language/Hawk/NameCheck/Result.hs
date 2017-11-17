{-# LANGUAGE  DeriveGeneric, TemplateHaskell, OverloadedStrings #-}
module Language.Hawk.NameCheck.Result where

import Control.Lens
import Data.Aeson
import Data.Binary
import Data.Default.Class
import Data.Map.Strict (Map)
import Data.Monoid
import Data.Set (Set)
import Data.Text (Text)
import GHC.Generics (Generic)
import Language.Hawk.Syntax

import qualified Data.Map.Strict as Map
import qualified Data.Text as T
import qualified Data.Set as Set
import qualified Text.PrettyPrint.Leijen.Text as PP


-----------------------------------------------------------------------
-- Name Check Result
-----------------------------------------------------------------------

data NcResult
  = NcResult
    { _ncNames :: Set Text
    , _ncSigs :: Map Text Type
    , _ncDecls :: Map Text [Exp]
    } deriving (Show, Generic)


makeClassy ''NcResult

instance Binary NcResult
instance FromJSON NcResult
instance ToJSON NcResult


-----------------------------------------------------------------------
-- Helper Instances
-----------------------------------------------------------------------

instance Default NcResult where
  def = empty
        

instance Monoid NcResult where
  mempty = empty

  mappend r1 r2
    = NcResult { _ncNames = _ncNames r1 <> _ncNames r2
               , _ncSigs  = _ncSigs r1 <> _ncSigs r2
               , _ncDecls = _ncDecls r1 <<>> _ncDecls r2
               }
      where
        (<<>>) = Map.unionWith (<>)


-----------------------------------------------------------------------
-- Pretty
-----------------------------------------------------------------------

instance PP.Pretty NcResult where
  pretty r =
    PP.textStrict "Names"
      PP.<$> PP.pretty (Set.toList $ _ncNames r)
      PP.<$> PP.textStrict "Signatures"
      PP.<$> PP.pretty (Map.toList $ _ncSigs r)
      PP.<$> PP.textStrict "Declarations"
      PP.<$> PP.pretty (Map.toList $ _ncDecls r)  


-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

empty :: NcResult
empty =
  NcResult
    { _ncNames = Set.empty
    , _ncSigs = Map.empty
    , _ncDecls = Map.empty
    }


singleton :: Text -> Maybe Type -> Maybe Exp -> NcResult
singleton n may_t may_e =
  NcResult
    { _ncNames = Set.singleton n
    , _ncSigs = case may_t of
                  Just t -> Map.singleton n t
                  Nothing -> Map.empty
    , _ncDecls = case may_e of
                  Just e -> Map.singleton n [e]
                  Nothing -> Map.empty
    }


