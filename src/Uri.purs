module Uri where

import Prelude ((++), ($), (/=))
import Global (encodeURI)

import Data.Maybe (Maybe(Just))
import Data.Nullable (toMaybe)

import Data.String as S
import Data.String.Regex as R

import Node.URL as URL
import Node.Path (FilePath, resolve)

type FileUri = String

fileUri :: FilePath -> FileUri
fileUri path = encodeURI $ "file://" ++ fullPath
  where path' = resolve [] path
        path'' =
          if S.take 1 path' /= "/"
             then "/" ++ path'
             else path'
        fullPath =
          R.replace (R.regex "\\\\" R.noFlags {global = true}) "/" path''

isValidUrl :: String -> Boolean
isValidUrl x = case [protocol,hostname] of
    [Just _,Just _] -> true
    _ -> false
  where url = URL.parse x
        protocol = toMaybe url.protocol
        hostname = toMaybe url.hostname
