{-# LANGUAGE  FlexibleContexts
            , LambdaCase
  #-}
module Language.CPS.ClosureConv where


import Control.Lens
import Control.Monad.Gen
import Data.Text (Text)
import Language.Hawk.CPS.Syntax
import Language.Hawk.Syntax.TypeS



-- To implement this, I need to generate variables for
-- closure environments with fairly private names, and also
-- I need to produce a new set of data types
closureconv :: (MonadGen Int m)
    => Text -> Term -> m ([TypeS], Term)
closureconv def_n = \case
  Let n b e' -> undefined
  If p a b -> undefined
  Jump a b -> undefined
  Halt a -> undefined