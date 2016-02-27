module Main where

import Prelude (Unit, ($), bind, (<$>), (>=), (&&), (==), (++), unit, pure)

import Data.Maybe (Maybe(Nothing, Just))
import Data.Array ((!!), drop, length, take, head)
import Data.Either (Either(Right, Left))
import Data.Foldable (elem)
import Data.Traversable (traverse)
import Data.Argonaut (printJson)
import Data.Argonaut.Encode (encodeJson)

import Node.Yargs (runYargs)

import Unsafe.Coerce (unsafeCoerce)

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console as C
import Control.Monad.Eff.Exception (Error, error, message)
import Control.Monad.Aff (Aff, launchAff, liftEff')
import Control.Monad.Aff.AVar (AVAR)
import Control.Monad.Aff.Par (Par(Par), runPar)

import Network.HTTP.Affjax (AJAX)
import Node.ChildProcess as CP
import Node.FS (FS)
import Node.Process as P
import Node.Path as Path
import Node.Globals (__dirname)

import CLI as CLI
import Cheerio as Cheerio
import Phantomjs.Types (PhantomjsOpts(PhantomjsOpts))
import Input (scriptToTemp, readPhantomjsInput, readInput)

handle :: forall e. String -> String -> String -> Aff e (Either Error String)
handle "text" doc sel = liftEff' $ Cheerio.getText doc sel
handle "html" doc sel = liftEff' $ Cheerio.getHtml doc sel
handle _ _ _ = pure $ Left (error "Invalid command")

handleSimple :: String -> String -> String -> Aff _ Unit
handleSimple method input sel =
  do e <- readInput input
     case e of
       Left err ->
         liftEff $
         do C.error ("wring: " ++ message err)
            P.exit 1
       Right doc ->
         do e <- handle method doc sel
            case e of
              Left err ->
                liftEff $
                do C.error ("wring: " ++ message err)
                   P.exit 1
              Right output ->
                liftEff $
                do C.log output
                   P.exit 0

foreign import phantomjsPath :: forall eff. Eff eff String

runPhantomjs opts@{input: Just input} =
  do i <- readPhantomjsInput input
     case i of
       Left err -> liftEff $ C.error ("wring: " ++ message err)
       Right x ->
         liftEff
         do phantomjs <- phantomjsPath
            let opts' = PhantomjsOpts opts {input = Just x}
            process <-
              CP.spawn phantomjs
                       ["--ignore-ssl-errors=true"
                       ,"--local-to-remote-url-access=true"
                       ,"--ssl-protocol=any"
                       ,scriptPath
                       ,printJson (encodeJson opts')]
                       CP.defaultSpawnOptions {stdio = CP.inherit}
            CP.onError process
              \err ->
                do case err.code of
                     "ENOENT" ->
                       C.error "wring: Error: `phantomjs` executable not found."
                     _ -> C.error $ "wring: " ++ (unsafeCoerce err)
                   P.exit 1
            CP.onExit process
              \e ->
                case e of
                  CP.Normally 0 -> P.exit 0
                  _ -> P.exit 1
  where scriptPath =
          if Path.basename __dirname == "Node.Globals"
             then "phantomjs-main.js"
             else Path.concat [__dirname,"phantomjs-main.js"]
app
  :: forall e.
     Array String
  -> Aff (console :: C.CONSOLE
         ,avar :: AVAR
         ,fs :: FS
         ,ajax :: AJAX
         ,process :: P.PROCESS
         ,cp :: CP.CHILD_PROCESS | e) Unit

---------------------
-- Command aliases --
---------------------
app ["t",input,sel] = app ["text",input,sel]

app ["h",input,sel] = app ["html",input,sel]

app args
  | head args `elem` [Just "p",Just "phantom"] =
    app (["phantomjs"] ++ drop 1 args)
  | take 2 args == ["phantomjs","t"] =
    app (["phantomjs","text"] ++ (drop 2 args))
  | take 2 args == ["phantomjs","h"] =
    app (["phantomjs","html"] ++ (drop 2 args))
  | take 2 args == ["phantomjs","s"] =
    app (["phantomjs","shot"] ++ (drop 2 args))
  | take 2 args == ["phantomjs","e"] =
    app (["phantomjs","eval"] ++ (drop 2 args))
  | head args `elem` [Just "e",Just "eval",Just "s",Just "shot"] =
    app (["phantomjs"] ++ args)

--------------
-- Commands --
--------------
app ["text",input,sel] = handleSimple "text" input sel

app ["html",input,sel] = handleSimple "html" input sel

app ["phantomjs","text",input,sel] =
  runPhantomjs
  {cmd: Just "text"
  ,input: Just input
  ,sel: Just sel
  ,scripts: Nothing
  ,output: Nothing}

app ["phantomjs","html",input,sel] =
  runPhantomjs
  {cmd: Just "html"
  ,input: Just input
  ,sel: Just sel
  ,scripts: Nothing
  ,output: Nothing}

app ["phantomjs","shot",input,sel,file] =
  runPhantomjs
  {cmd: Just "shot"
  ,input: Just input
  ,sel: Just sel
  ,scripts: Nothing
  ,output: Just file}

app args
  | take 2 args == ["phantomjs","eval"] && length args >= 4 =
    do scripts <- runPar $ traverse (Par <$> scriptToTemp) (drop 3 args)
       runPhantomjs
         {cmd: Just "eval"
         ,input: args !! 2
         ,sel: Nothing
         ,scripts: Just scripts
         ,output: Nothing}

app args =
  liftEff $
  do C.error ("wring: Invalid arguments. " ++
              "Use `wring --help` for more information.")
     P.exit 1

main =
  do args <- runYargs CLI.setup
     launchAff $ app (unsafeCoerce args)."_"
