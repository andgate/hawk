{-# LANGUAGE  FlexibleInstances
            , BangPatterns
            , DeriveGeneric
            , OverloadedStrings
            , TemplateHaskell
            , DeriveDataTypeable
  #-}
module Language.Hawk.Syntax.Location where

import Control.Lens
import Data.Binary
import Data.Data
import Data.Monoid
import Data.Text (pack)
import GHC.Generics (Generic)

import qualified Text.PrettyPrint.Leijen.Text as P


-- Location wrapper
data L a = L Location a
  deriving (Eq, Ord, Read, Show, Data, Typeable, Generic)


data Location
  = Loc
    { _locPath  :: !FilePath
    , _locReg   :: {-# UNPACK #-} !Region 
    }
    deriving (Eq, Ord, Read, Show, Data, Typeable, Generic)


data Region
  = R
    { _regStart :: {-# UNPACK #-} !Position
    , _regEnd   :: {-# UNPACK #-} !Position
    }
    deriving (Eq, Ord, Read, Show, Data, Typeable, Generic)


data Position
  = P
    { _posLine    :: {-# UNPACK #-} !Int
    , _posColumn  :: {-# UNPACK #-} !Int
    }
    deriving (Eq, Ord, Read, Show, Data, Typeable, Generic)

makeClassy ''Location
makeClassy ''Region
makeClassy ''Position

-- -----------------------------------------------------------------------------
-- Classy Instances  

instance HasRegion Location where
    region = locReg . region

-- Can't make a HasPosition instance for region, since it has two positions!

-- -----------------------------------------------------------------------------
-- Helpers
    
mkRegion :: HasPosition a => a -> a -> Region
mkRegion start end = R (start^.position) (end^.position)

stretch :: HasPosition a => a -> Int -> Region
stretch a n = mkRegion p1 p2
  where
    p1@(P l c) = a^.position
    p2 = P l (c + n)

-- -----------------------------------------------------------------------------
-- Helper Instances,

instance Monoid Location where
    mempty = Loc "" mempty
    mappend (Loc fp r1) (Loc _ r2)
      = Loc fp (r1 <> r2)

instance Monoid Region where
    mempty = R (P 0 0) (P 0 0)
    mappend (R start _) (R _ end)
      | (start^.posLine) < (end^.posLine) = R start end
      | (start^.posLine) > (end^.posLine) = R end start
      | (start^.posColumn) > (end^.posColumn) = R start end
      | otherwise = R end start

-- -----------------------------------------------------------------------------
-- Pretty Instances   

instance P.Pretty a => P.Pretty (L a) where
    pretty (L loc a) =
       P.pretty a
       P.<$>
       P.textStrict "located at" P.<+> P.pretty loc


instance P.Pretty Location where
    pretty loc =
       P.textStrict (pack $ loc^.locPath) P.<> P.textStrict ":" P.<> P.pretty (loc^.locReg)


instance P.Pretty Region where
  pretty (R s e)
    | s == e
      = P.pretty s
    | otherwise
      = P.pretty s P.<> P.textStrict "-" <> P.pretty e


instance P.Pretty Position where
  pretty (P l c) =
    P.pretty (l+1) P.<> P.textStrict ":" <> P.pretty (c+1)


-- -----------------------------------------------------------------------------
-- Binary Instances

instance Binary a => Binary (L a)
instance Binary Location
instance Binary Region
instance Binary Position