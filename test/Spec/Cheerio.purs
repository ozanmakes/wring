module Test.Spec.CheerioSpec (cheerioSpec) where

import Prelude

import Data.String (joinWith, trim)

import Control.Monad.Eff.Unsafe (unsafePerformEff)

import Test.Spec (describe, it, pending)
import Test.Spec.QuickCheck (quickCheck)
import Test.QuickCheck ((===), (/==))

import Node.Globals (unsafeRequire)

import Cheerio as C

cheerioSpec =
  do describe "CSS Selectors" $
       do it "gets single element text with class" $
            quickCheck $ \x -> getText (foo x) ".foo" === trim x
          it "gets multiple elements text with class" $
            quickCheck $
            \xs ->
              let doc = bar <<< joinWith "" $ map foo xs
              in getText doc ".foo" === trim <<< joinWith "\n" $ map trim xs
          it "gets single element HTML with class" $
            quickCheck $ \s -> getHtml (foo s) ".foo" === foo (encode s)
          it "gets multiple elements HTML with class" $
            quickCheck $
            \xs ->
              let doc = bar <<< joinWith "" $ map foo xs
              in getHtml doc ".foo" === joinWith "\n" $ map (foo <<< encode) xs
     describe "XPath" $
       do it "gets single element text with class" $
            quickCheck $ \x -> getText (foo x) "//*[@class=\"foo\"]" === trim x
          it "gets multiple elements text with class" $
            quickCheck $
            \xs ->
              let doc = bar <<< joinWith "" $ map foo xs
              in getText doc "//*[@class=\"foo\"]" === trim <<< joinWith "\n" $
                 map trim xs
          it "gets single element HTML with class" $
            quickCheck $
            \s -> getHtml (foo s) "//*[@class=\"foo\"]" === foo (encode s)
          it "gets multiple elements HTML with class" $
            quickCheck $
            \xs ->
              let doc = bar <<< joinWith "" $ map foo xs
              in getHtml doc "//*[@class=\"foo\"]" === joinWith "\n" $
                 map (foo <<< encode) xs
  where foo s = "<div class=\"foo\">" ++ s ++ "</div>"
        bar s = "<div class=\"bar\">" ++ s ++ "</div>"
        getText x y = unsafePerformEff $ C.getText x y
        getHtml x y = unsafePerformEff $ C.getHtml x y

encode :: String -> String
encode = (unsafeRequire "entities").encodeXML
