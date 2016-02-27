module Cheerio (getText, getHtml) where

import Prelude ((>>=), pure, ($), (==), bind)

import Data.String as S

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Exception (EXCEPTION)

import Unsafe.Coerce (unsafeCoerce)

foreign import data Cheerio :: *
foreign import data Collection :: *

foreign import load
  :: forall e.
    String -> Eff (err :: EXCEPTION | e) Cheerio

foreign import get
  :: forall e.
    String -> Collection -> Eff (err :: EXCEPTION | e) String

foreign import selectXpath
  :: forall e.
    Cheerio -> Selector -> Eff (err :: EXCEPTION | e) Collection

type Selector = String

select :: forall e. String -> Selector -> Eff (err :: EXCEPTION | e) Collection
select input sel =
  do c <- load input
     if S.take 1 sel == "/"
        then selectXpath c sel
        else pure $ (unsafeCoerce c) sel

getText :: forall e. String -> String -> Eff (err :: EXCEPTION | e) String
getText input sel = select input sel >>= get "text"

getHtml :: forall e. String -> String -> Eff (err :: EXCEPTION | e) String
getHtml input sel = select input sel >>= get "html"
