module Test.Main where

import Prelude

import Test.Spec.Runner (run)
import Test.Spec.Reporter.Console (consoleReporter)

import Test.Spec.CheerioSpec (cheerioSpec)
import Test.Spec.IntegrationSpec (basicSpec, phantomjsSpec, failureSpec)

main = run [consoleReporter]
  do cheerioSpec
     basicSpec
     phantomjsSpec
     failureSpec
