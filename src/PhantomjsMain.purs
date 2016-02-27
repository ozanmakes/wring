module PhantomjsMain where

import Prelude (Unit, bind, ($), (++))
import Control.Apply ((*>))
import Control.Monad.Aff (launchAff, attempt)
import Control.Monad.Aff.AVar (AVAR)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console as C
import Control.Monad.Eff.Exception (EXCEPTION, message)
import Data.Array (index)
import Data.Maybe (Maybe(Nothing, Just))
import Data.Either (Either(Right, Left))
import Data.Traversable (traverse)
import Data.Nullable (toMaybe)
import Unsafe.Coerce (unsafeCoerce)

import Test.Phantomjs (PHANTOMJS)
import Test.Phantomjs.Object (exit)
import Test.Phantomjs.System (args)
import Test.Phantomjs.Webpage as P

import Data.Argonaut.Decode (decodeJson)
import Data.Argonaut.Parser (jsonParser)

import Phantomjs.Types (PhantomjsOpts(PhantomjsOpts))
import Extract (Result, extractImpl)
import Input (withTimeout)

foreign import setBgColor :: P.BrowserProc Unit

foreign import setCallback
  :: forall e.
     P.Page -> Eff (phantomjs :: PHANTOMJS | e) Unit

foreign import error
  :: forall e.
     String -> Eff (console :: C.CONSOLE | e) Unit

extract
  :: forall e.
     P.Page
  -> String
  -> String
  -> Eff (phantomjs :: PHANTOMJS | e) Result
extract page cmd selector =
  P.evaluate2 page (unsafeCoerce extractImpl) cmd selector

printMatches
  :: forall e.
     P.Page
  -> String
  -> String
  -> Eff (phantomjs :: PHANTOMJS , console :: C.CONSOLE | e) Unit
printMatches page cmd selector =
  do result <- extract page cmd selector
     case toMaybe result.error of
       Just e -> error e *> exit 1
       Nothing -> C.log result.output *> exit 0

capture
  :: forall e.
     P.Page
  -> String
  -> String
  -> Eff (phantomjs :: PHANTOMJS , console :: C.CONSOLE | e) Unit
capture page selector imgPath =
  do P.evaluate0 page setBgColor
     result <- extract page "rect" selector
     case toMaybe result.error of
       Just e -> error e *> exit 1
       Nothing ->
         do P.setClipRect page
                          (unsafeCoerce result . rect)
            successful <- render page imgPath
            if successful
               then error ("Saved to " ++ imgPath) *> exit 0
               else error ("Saving to file " ++ imgPath ++ " failed") *> exit 1
  where render
          :: forall eff.
             P.Page -> String -> Eff (phantomjs :: PHANTOMJS | eff) Boolean
        render = unsafeCoerce P.render  -- Original function has the wrong type

run
  :: forall e.
     P.Page
  -> PhantomjsOpts
  -> Eff (phantomjs :: PHANTOMJS , console :: C.CONSOLE | e) Unit
run page (PhantomjsOpts opts) =
  do setCallback page
     P.injectJs page "./resources/jquery.js"
     P.setViewportSize page (P.ViewportSize {width: 1366, height: 768})
     case opts of
       {cmd: Just "text"
       ,input: Just _
       ,sel: Just sel
       ,scripts: Nothing
       ,output: Nothing
       } -> printMatches page "text" sel

       {cmd: Just "html"
       ,input: Just _
       ,sel: Just sel
       ,scripts: Nothing
       ,output: Nothing
       } -> printMatches page "html" sel

       {cmd: Just "shot"
       ,input: Just _
       ,sel: Just sel
       ,scripts: Nothing
       ,output: (Just imgPath)
       } -> capture page sel imgPath

       {cmd: Just "eval"
       ,input: Just _
       ,sel: Nothing
       ,scripts: Just scripts
       ,output: Nothing
       } -> traverse (P.injectJs page) scripts *> exit 0

       _ -> error "Invalid options" *> exit 1
run _ _ = liftEff $ error "Invalid options" *> exit 1

main
  :: forall e.
     Eff (avar :: AVAR
         ,phantomjs :: PHANTOMJS
         ,console :: C.CONSOLE
         ,err :: EXCEPTION | e) Unit
main =
  do args <- args
     case (index args 1) of
       Just x ->
         case jsonParser x of
           Left err -> error err *> exit 1
           Right json ->
             case decodeJson json of
               Left err -> error err *> exit 1
               Right o@(PhantomjsOpts opts) ->
                 case opts.input of
                   Just uri ->
                     do page <- P.create
                        launchAff $
                          do e <- withTimeout 30000 (attempt $ P.open page uri)
                             case e of
                               Left err ->
                                 liftEff $ error (message err) *> exit 1
                               Right _ -> liftEff $ run page o
                   Nothing -> error "No input given" *> exit 1
