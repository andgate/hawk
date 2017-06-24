{-# LANGUAGE RankNTypes
           , OverloadedStrings
           , FlexibleContexts
           , AllowAmbiguousTypes
  #-}
module Language.Hawk.Compile where

import Control.Lens
import Control.Monad.Chronicle
import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Log
import Control.Monad.Reader
import Control.Monad.State

import Language.Hawk.Load
import Language.Hawk.Parse

import Language.Hawk.Compile.Config
import Language.Hawk.Compile.Error
import Language.Hawk.Compile.Message
import Language.Hawk.Compile.Monad
import Language.Hawk.Compile.State
import Language.Hawk.Compile.Options


import qualified Data.Text                        as T
import qualified Data.Vector                      as V
import qualified Language.Hawk.Parse              as P


hkc :: Hkc ()
hkc = compile

compile
  :: ( MonadReader c m , HasHkcConfig c
     , MonadState s m
     , HasHkcState s, HasNameCheckState s, HasTypeCheckState s
     , MonadLog (WithSeverity msg) m, AsLoadMsg msg
     , MonadChronicle [e] m
     , AsHkcErr e, AsLoadErr e, AsParseErr e, AsNameCheckError e, AsTypeCheckError e
     , MonadIO m
     )
  => m ()
compile = do
  load
  --parseFiles
  --namecheck
  --typecheck
  --optimize
  --codegen
  return ()
