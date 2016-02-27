module Temp where

import Prelude (pure, bind)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Exception (EXCEPTION)

import Node.FS (FS, ByteCount, FileDescriptor)
import Node.Path (FilePath)

type TempFile =
  { path :: FilePath
  , fd :: FileDescriptor
  }

foreign import openTempSync
  :: forall eff.
     String -> Eff (err :: EXCEPTION, fs :: FS | eff) TempFile

foreign import writeSync
  :: forall eff.
     FileDescriptor -> String -> Eff (err :: EXCEPTION, fs :: FS | eff) ByteCount

foreign import tempPath
  :: forall eff.
     String -> Eff (err :: EXCEPTION, fs :: FS | eff) FilePath

saveToTemp
  :: forall eff.
     String -> String -> Eff (err :: EXCEPTION, fs :: FS | eff) FilePath
saveToTemp extension contents =
  do file <- openTempSync extension
     writeSync file.fd contents
     pure file.path
