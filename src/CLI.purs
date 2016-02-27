module CLI where

import Prelude ((++), (<>), ($), (<<<))

import Data.Function (runFn2)
import Data.String as S

import Ansi.Codes
       (Color(Grey, Yellow, Magenta, Cyan, Green),
        EscapeCode(Graphics),
        GraphicsParam(Reset, PMode, PForeground),
        RenderingMode(Italic, Bold),
        escapeCodeToString)

import Node.Process as P
import Node.Yargs.Setup
       (YargsSetup, example, showHelpOnFail, strict, demandCount, alias,
        version, help, usage)

import Unsafe.Coerce (unsafeCoerce)

setup :: YargsSetup
setup =
  usage ("Usage: wring " ++ (bold <<< italic) "<command>") <>
  help "h" "Show this help message" <>
  alias "h" "help" <>
  version "v" "Show version number" "0.0.1" <>
  alias "v" "version" <>
  exampleText <>
  command "text"
          (color Cyan "input" ++ " " ++ color Magenta "selector")
          "Extract text matching CSS Selector or XPath" <>
  command "html"
          (color Cyan "input" ++ " " ++ color Magenta "selector")
          "Extract HTML matching CSS Selector or XPath" <>
  command "eval"
          (color Cyan "input" ++ " " ++ color Green "script...")
          "Evaluate JavaScript in page context" <>
  command "shot"
          (color Cyan "input" ++
           " " ++ color Magenta "selector" ++ " " ++ color Yellow "file.png")
          ("Capture screenshot using a selector") <>
  command "phantomjs"
          (italic $ bold "<command>")
          ("Use PhantomJS (implicit for " ++
           bold "eval" ++ " and " ++ bold "shot" ++ ")") <>
  demandCount 2 "" <>
  strict <>
  showHelpOnFail true ""

exampleText :: YargsSetup
exampleText =
  ex "text" "https://example.com" "'.foo'" "" "URL, CSS selector, text output" <>
  ex "html" "path/to/file.html" "'//title'" "" "Local file, XPath, HTML output" <>
  ex "t   " "'<div id=\"#a\"></div>'" "'#a'" "" "Read from string" <>
  ex "h   " "-" "'li:nth-child(even)'" "" "Read from stdin" <>
  ex "shot" "'http://...'" "'form'" "file.png" "Save screenshot of first form" <>
  ex "eval" "-" "'wring(document.title)'" "" "Evaluate JS in page context" <>
  ex "p t " "'<b>x</b>'" "'b:contains('x')'" "" "Extract text using PhantomJS"
  where ex cmd input sel output desc =
          example ("wring " ++
                   (bold cmd) ++ " " ++
                   (color Cyan input) ++ " " ++
                   (color Magenta sel) ++ " " ++
                   (color Yellow output))
                  (color Grey $ "# " ++ desc)

command :: String -> String -> String -> YargsSetup
command name args desc =
  (defCommand display desc) <>
  (defCommand short hidden) <>
  (defCommand name hidden)
  where short = (S.take 1 name)
        display = (bold name) ++ " " ++ args
        hidden = unsafeCoerce false
        defCommand name desc =
          unsafeCoerce \y -> runFn2 y.command name desc

color :: Color -> String -> String
color c text = withGraphics (PForeground c) text

bold :: String -> String
bold text = withGraphics (PMode Bold) text

italic :: String -> String
italic text = withGraphics (PMode Italic) text

withGraphics :: GraphicsParam -> String -> String
withGraphics param text
  | P.stderrIsTTY =
    escapeCodeToString (Graphics [param]) ++
    text ++
    escapeCodeToString (Graphics [Reset])
withGraphics _ text = text
