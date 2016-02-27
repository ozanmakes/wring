module Input (readInput, readPhantomjsInput, scriptToTemp, withTimeout) where

import Prelude (bind, (<$>), ($), pure, show, (++), (<<<), (==), (/))

import Data.Maybe (Maybe(Nothing, Just))
import Data.Either (Either(Right, Left))
import Data.String as S

import Control.Alt ((<|>))
import Control.Plus (empty)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console as C
import Control.Monad.Eff.Exception (Error, error)
import Control.Monad.Eff.Ref (newRef, modifyRef, readRef)
import Control.Monad.Eff.Ref.Unsafe (unsafeRunRef)
import Control.Monad.Aff (Aff, launchAff, liftEff', attempt, later')
import Control.Monad.Aff.AVar (AVAR, takeVar, putVar, makeVar)
import Control.Monad.Aff.Par (Par(Par), runPar)
import Control.MonadPlus (guard)

import Network.HTTP.Affjax (AJAX, get)
import Node.Encoding (Encoding(UTF8))
import Node.FS (FS)
import Node.FS.Aff as FSA
import Node.Stream (onDataString, onEnd)
import Node.Process as P
import Unsafe.Coerce (unsafeCoerce)

import Uri (fileUri, isValidUrl)
import Temp (saveToTemp)

foreign import isFileSync :: forall e. String -> Eff (fs :: FS | e) Boolean

-- | DWIM API for basic features which given an input string
-- | - If input is "-" reads stdin
-- | - Else If input is a file path returns file contents
-- | - Else If input is a URL retrieves it
-- | - Else If input looks like a HTML snippet returns it as is
readInput
  :: forall e.
     String
  -> Aff (console :: C.CONSOLE
         ,avar :: AVAR
         ,fs :: FS
         ,ajax :: AJAX | e) (Either Error String)
readInput x =
  readStdin x <|> readFile x <|> readUrl x <|> readHtml x <|>
  pure (Left $ error errorMsg)

-- | DWIM API for PhantomJS related features which given an input string
-- | - If input is "-" reads stdin into a temporary file
-- | - Else If input is a URL returns it as is
-- | - Else If input is a file path returns a file URI pointing to the file
-- | - Else If input looks like a HTML snippet saves it to a temporary file
readPhantomjsInput
  :: forall e.
     String
  -> Aff (console :: C.CONSOLE
         ,avar :: AVAR
         ,fs :: FS | e) (Either Error String)
readPhantomjsInput i =
  stdinToTemp i <|> getUrl i <|> getFileUri i <|> htmlToTemp i <|>
  pure (Left $ error errorMsg)

errorMsg :: String
errorMsg =
  "Unable to process the input as an URL, a file path or an HTML string. " ++
  "Use `wring --help` for more information."

-- | Read page source from stdin
readStdin
  :: forall e.
     String
  -> Aff (console :: C.CONSOLE , avar :: AVAR | e) (Either Error String)
readStdin x =
  do guard $ x == "-"
     outVar <- makeVar
     (Right contentRef) <- liftEff' <<< unsafeRunRef $ newRef ""
     liftEff' $
       onDataString P.stdin
                    UTF8
                    (\s -> unsafeRunRef $ modifyRef contentRef (++ s))
     liftEff' $
       onEnd P.stdin
             (do html <- unsafeRunRef $ readRef contentRef
                 launchAff $ putVar outVar (Right html))
     takeVar outVar

-- | Read page source from a file
readFile :: forall e. String -> Aff (fs :: FS | e) (Either Error String)
readFile x =
  do e <- attempt $ FSA.readTextFile UTF8 path
     case e of
       Left err ->
         case (unsafeCoerce err).code of
           "ENOENT" -> empty
           "ENAMETOOLONG" -> empty
           other -> pure (Left err)
       Right doc -> pure (Right doc)
  where path =
          case S.stripPrefix "file://" x of
            (Just s) -> s
            Nothing -> x

-- | Fetch page source from a URL
readUrl :: forall e. String -> Aff (avar :: AVAR, ajax :: AJAX | e) (Either Error String)
readUrl url =
  do guard $ isValidUrl url
     e <- withTimeout 30000 (attempt $ get url)
     case e of
       (Left err) -> pure (Left err)
       (Right res) -> pure (Right res.response)

-- | Attempt to treat a string as an HTML document
readHtml :: forall e. String -> Aff e (Either Error String)
readHtml doc =
  do guard $ S.contains "<" doc
     guard $ S.contains ">" doc
     pure (Right doc)

-- | Save a JS FilePath/URL/Expression to a temporary file
scriptToTemp x =
  do (Right src) <- readFile x <|> readUrl x <|> pure (Right x)
     liftEff $ saveToTemp "js" src

getUrl :: forall e. String -> Aff e (Either Error String)
getUrl url =
  do guard $ isValidUrl url
     pure (Right url)

-- | If a file exists at given path return a file URI pointing to the file
getFileUri :: forall e f. String -> Aff (fs :: FS | e) (Either f String)
getFileUri path =
  do (Right isfile) <- liftEff' $ isFileSync path
     guard isfile
     pure $ Right (fileUri path)

-- | If input looks like a HTML snippet save it to a temporary file
htmlToTemp :: forall e. String -> Aff (fs :: FS | e) (Either Error String)
htmlToTemp input =
  do (Right doc) <- readHtml input
     liftEff' $ fileUri <$> saveToTemp "html" doc

-- | Read page source from stdin into a temporary file
stdinToTemp
  :: forall e.
     String
  -> Aff (console :: C.CONSOLE
         ,avar :: AVAR
         ,fs :: FS | e) (Either Error String)
stdinToTemp input =
  do (Right html) <- readStdin input
     htmlToTemp html

withTimeout
  :: forall e a.
     Int
  -> Aff (avar :: AVAR | a) (Either Error e)
  -> Aff (avar :: AVAR | a) (Either Error e)
withTimeout timeout aff =
  runPar $
  (Par aff) <|>
  (Par $
   later' timeout
          (pure <<< Left <<< error $
           "Timed out after " ++ show (timeout / 1000) ++ " seconds"))
