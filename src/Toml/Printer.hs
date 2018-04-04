{-# LANGUAGE TypeFamilies #-}

{- | Contains functions for pretty printing @toml@ types. -}

module Toml.Printer
       ( prettyToml
       , prettyTomlInd
       ) where

import Data.HashMap.Strict (HashMap)
import Data.Monoid ((<>))
import Data.Text (Text)

import Toml.Type (AnyValue (..), DateTime (..), Key (..), TOML (..), Value (..))

import qualified Data.HashMap.Strict as HashMap
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Text as Text

-- Tab is equal to 2 spaces now.
tab :: Int -> Text
tab n = Text.cons '\n' (Text.replicate (2*n) " ")

{- | Converts 'TOML' type into 'Text'.

For example, this

@
TOML
    { tomlPairs  = HashMap.fromList [(Key "title", String "TOML example")]
    , tomlTables = HashMap.fromList
          [( TableId (NonEmpty.fromList ["example", "owner"])
           , TOML
                 { tomlPairs  = HashMap.fromList [(Key "name", String "Kowainik")]
                 , tomlTables = mempty
                 , tomlTableArrays = mempty
                 }
           )]
    , tomlTableArrays = mempty
    }
@

will be translated to this

@
title = "TOML Example"

[example.owner]
  name = "Kowainik"

@
-}
prettyToml :: TOML -> Text
prettyToml = prettyTomlInd 0

-- | Converts 'TOML' into 'Text' with the given indent.
prettyTomlInd :: Int -> TOML -> Text
prettyTomlInd i TOML{..} = prettyKeyValue i tomlPairs  <> "\n"
                        <> prettyTables   i tomlTables

prettyKeyValue :: Int -> HashMap Key AnyValue -> Text
prettyKeyValue i = Text.concat . map kvText . HashMap.toList
  where
    kvText :: (Key, AnyValue) -> Text
    kvText (k, AnyValue v) = tab i <> prettyKey k <> " = " <> valText v

    valText :: Value t -> Text
    valText (Bool b)   = Text.toLower $ showText b
    valText (Int n)    = showText n
    valText (Float d)  = showText d
    valText (String s) = showText s
    valText (Date d)   = timeText d
    valText (Array a)  = "[" <> Text.intercalate ", " (map valText a) <> "]"

    timeText :: DateTime -> Text
    timeText (Zoned z) = showText z
    timeText (Local l) = showText l
    timeText (Day d)   = showText d
    timeText (Hours h) = showText h

    showText :: Show a => a -> Text
    showText = Text.pack . show

prettyTables :: Int -> HashMap Key TOML -> Text
prettyTables i = Text.concat . map prettyTable . HashMap.toList
  where
    prettyTable :: (Key, TOML) -> Text
    prettyTable (tn, toml) = tab i <> prettyTableName tn
                                   <> prettyTomlInd (succ i) toml

    prettyTableName :: Key -> Text
    prettyTableName k = "[" <> prettyKey k <> "]"

prettyKey :: Key -> Text
prettyKey (Key k) = Text.intercalate "." (NonEmpty.toList k)
