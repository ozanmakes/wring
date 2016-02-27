module Phantomjs.Types where

import Prelude (pure, ($), bind)

import Data.Argonaut ((~>), (:=), (.?), jsonEmptyObject)
import Data.Argonaut.Encode (class EncodeJson)
import Data.Argonaut.Decode (class DecodeJson, decodeJson)
import Data.Maybe (Maybe)

import Node.Path (FilePath)

import Uri (FileUri)

newtype PhantomjsOpts =
  PhantomjsOpts {cmd :: Maybe String
                ,input :: Maybe FileUri
                ,sel :: Maybe String
                ,scripts :: Maybe (Array String)
                ,output :: Maybe FilePath}

instance decodeJsonPhantomjsOpts :: DecodeJson PhantomjsOpts where
  decodeJson json = do
    obj <- decodeJson json
    cmd <- obj .? "cmd"
    input <- obj .? "input"
    sel <- obj .? "sel"
    scripts <- obj .? "scripts"
    output <- obj .? "output"
    pure $ PhantomjsOpts {cmd,input,sel,scripts,output}

instance encodeJsonPhantomjsOpts :: EncodeJson PhantomjsOpts where
  encodeJson (PhantomjsOpts o)
    =  "cmd" := o.cmd
    ~> "input" := o.input
    ~> "sel" := o.sel
    ~> "scripts" := o.scripts
    ~> "output" := o.output
    ~> jsonEmptyObject
