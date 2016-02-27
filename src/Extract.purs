module Extract where

import Data.Function
import Unsafe.Coerce
import Control.Monad.Eff
import Data.Foreign
import Data.Nullable

type Result =
  { output :: String
  , rect :: Foreign
  , error :: Nullable String
  }

foreign import extractImpl :: String -> String -> Result
