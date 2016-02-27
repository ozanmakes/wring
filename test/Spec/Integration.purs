module Test.Spec.IntegrationSpec (basicSpec, phantomjsSpec, failureSpec) where

import Prelude

import Data.Array
import Data.String
import Data.Either

import Control.Monad.Aff
import Control.Monad.Eff
import Control.Monad.Eff.Class
import Control.Monad.Eff.Console
import Test.Spec
import Test.Spec.Assertions (shouldEqual)

import Control.Monad.Aff.AVar (takeVar, putVar, makeVar)
import Node.Path (FilePath)

import Temp (tempPath)

basicSpec =
  describe "Integration (basic)" $
  do it "text '<html>' '.single.matching'" $
       do output <- run ["text",doc,".bar"]
          output `shouldEqual` "bar"
     it "html '<html>' '.single.matching'" $
       do output <- run ["html",doc,".bar"]
          output `shouldEqual` bar
     it "t '<html>' '.multiple.matching'" $
       do output <- run ["t",doc,".foo"]
          output `shouldEqual` joinWith "\n" ["foo1","foo2"]
     it "h '<html>' '.multiple.matching'" $
       do output <- run ["h",doc,".foo"]
          output `shouldEqual` joinWith "\n" [foo1,foo2]
     it "text '<html>' '//multiple/matching'" $
       do output <- run ["text",doc,"//div[@class='foo']"]
          output `shouldEqual` joinWith "\n" ["foo1","foo2"]
     it "html '<html>' '//multiple/matching'" $
       do output <- run ["html",doc,"//div[@class='foo']"]
          output `shouldEqual` joinWith "\n" [foo1,foo2]
     it "text 'http://url' '.multiple.matching'" $
       do output <- get doc ["text",urlPlaceholder,".foo"]
          output `shouldEqual` joinWith "\n" ["foo1","foo2"]
     it "html 'http://url' '.multiple.matching'" $
       do output <- get doc ["html",urlPlaceholder,".foo"]
          output `shouldEqual` joinWith "\n" [foo1,foo2]
     it "text 'path/to/file.html' '.single.matching'" $
       do output <-
            run ["text"
                ,"resources/test/songs.html"
                ,"tr:contains('Strange Clouds') th:first-child"]
          output `shouldEqual` "\"Both of Us\""
     it "cat 'path/to/file.html' | wring text - '.single.matching'" $
       do output <-
            sh $
            "cat 'resources/test/songs.html' | " ++
            "node wring.js text - '.firstHeading'"
          output `shouldEqual` "List of songs recorded by Taylor Swift"
  where foo1 = "<div class=\"foo\">foo1</div>"
        foo2 = "<div class=\"foo\">foo2</div>"
        bar = "<div class=\"bar\">bar</div>"
        doc = joinWith "\n" [foo1,bar,foo2]

phantomjsSpec =
  describe "Integration (phantomjs)" $
  do it "phantomjs text '<html>' '.single.matching'" $
       do output <- run ["phantomjs","text",doc,".bar"]
          output `shouldEqual` "bar"
     it "phantomjs html '<html>' '.single.matching'" $
       do output <- run ["phantomjs","html",doc,".bar"]
          output `shouldEqual` bar
     it "p t '<html>' '.multiple.matching'" $
       do output <- run ["p","text",doc,".foo"]
          output `shouldEqual` joinWith "\n" ["foo1","foo2"]
     it "p h '<html>' '.multiple.matching'" $
       do output <- run ["p","html",doc,".foo"]
          output `shouldEqual` joinWith "\n" [foo1,foo2]
     it "phantomjs text '<html>' '//multiple/matching'" $
       do output <- run ["phantomjs","text",doc,"//div[@class='foo']"]
          output `shouldEqual` joinWith "\n" ["foo1","foo2"]
     it "phantomjs html '<html>' '//multiple/matching'" $
       do output <- run ["phantomjs","html",doc,"//div[@class='foo']"]
          output `shouldEqual` joinWith "\n" [foo1,foo2]
     it "phantomjs text 'http://url' '.multiple.matching'" $
       do output <- get doc ["phantomjs","text",urlPlaceholder,".foo"]
          output `shouldEqual` joinWith "\n" ["foo1","foo2"]
     it "phantomjs html 'http://url' '.multiple.matching'" $
       do output <- get doc ["phantomjs","html",urlPlaceholder,".foo"]
          output `shouldEqual` joinWith "\n" [foo1,foo2]
     it "phantomjs text 'path/to/file.html' '.single.matching'" $
       do output <-
            run ["phantomjs"
                ,"text"
                ,"resources/test/songs.html"
                ,"tr:contains('Strange Clouds') th:first-child"]
          output `shouldEqual` "\"Both of Us\""
     it "shot 'path/to/file.html' '.single.matching' 'path/to/file.png'" $
       do path <- liftEff $ tempPath "png"
          run ["shot","resources/test/songs.html",".firstHeading",path]
          (Right saved) <- liftEff' $ isPng path
          saved `shouldEqual` true
     it "eval '<html>' 'path/to/file.js' '<script>'" $
       do output <-
            run ["eval"
                ,"<title>Foo Bar</title>"
                ,"resources/test/lodash.js"
                ,"wring(_.kebabCase(document.title))"]
          output `shouldEqual` "foo-bar"
     it "phantomjs eval 'path/to/file.html' '<script>'" $
       do output <-
            run ["phantomjs"
                ,"eval"
                ,"resources/test/songs.html"
                ,"wring($('.firstHeading').text())"]
          output `shouldEqual` "List of songs recorded by Taylor Swift"
     it "p e 'input' 'http://script.js' '<script>'" $
       do output <-
            get ("$('body').append('" ++ foo2 ++ "')")
                ["p","e",foo1,urlPlaceholder,"wring(document.body.innerText)"]
          output `shouldEqual` "foo1\nfoo2"
     it "cat 'path/to/file.html' | wring phantomjs text - '.single.matching'" $
       do output <-
            sh $
            "cat 'resources/test/songs.html' | " ++
            "node wring.js phantomjs text - '.firstHeading'"
          output `shouldEqual` "List of songs recorded by Taylor Swift"
  where foo1 = "<div class=\"foo\">foo1</div>"
        foo2 = "<div class=\"foo\">foo2</div>"
        bar = "<div class=\"bar\">bar</div>"
        doc = joinWith "\n" [foo1,bar,foo2]

failureSpec =
  describe "Integration (failure)" $
  do it "shot failed match" $
       do path <- liftEff $ tempPath "png"
          code <- returnCode ["shot","<b>foo</b>",".unmatched",path]
          code `shouldEqual` 1
     it "shot failed save" $
       do code <-
            returnCode
              ["shot"
              ,"resources/test/songs.html"
              ,".firstHeading"
              ,"/root/foo.png"]
          code `shouldEqual` 1
     it "shot too many args" $
       do code <-
            returnCode
              ["shot"
              ,"resources/test/songs.html"
              ,".firstHeading"
              ,"/root/foo.png"
              ,"foo"]
          code `shouldEqual` 1
     it "shot too few args" $
       do code <-
            returnCode ["shot","resources/test/songs.html",".firstHeading"]
          code `shouldEqual` 1

foreign import runImpl
  :: forall e.
     Array String ->
     ({ output :: String, code :: Int } -> Eff e Unit) ->
     Eff e Unit

run args =
  do outVar <- makeVar
     liftEff $ runImpl args (\output -> launchAff $ putVar outVar output)
     _.output <$> takeVar outVar

returnCode args =
  do outVar <- makeVar
     liftEff $ runImpl args (\output -> launchAff $ putVar outVar output)
     _.code <$> takeVar outVar

foreign import shImpl :: forall e. String -> (String -> Eff e Unit) -> Eff e Unit

sh cmd =
  do outVar <- makeVar
     liftEff $ shImpl cmd (\output -> launchAff $ putVar outVar output)
     takeVar outVar

foreign import startServer :: forall e. String -> (String -> Eff e Unit) -> Eff e Unit

get x args =
  do outVar <- makeVar
     liftEff $ startServer x (\url -> launchAff $ putVar outVar url)
     url <- takeVar outVar
     run $ map (\x -> if x == urlPlaceholder then url else x) args

urlPlaceholder = "<url>"

foreign import isPng :: forall e. String -> Eff e Boolean
