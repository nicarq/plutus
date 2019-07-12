{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE DerivingStrategies         #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# OPTIONS_GHC -Wno-orphans            #-}

module LedgerBytes
  ( LedgerBytes(..)
  , fromHex
  , bytes
  , fromBytes
  ) where

import           Codec.Serialise
import           Data.Aeson                 (FromJSON (..), ToJSON (..))
import qualified Data.Aeson                 as JSON
import qualified Data.Aeson.Extras          as JSON
import           Data.Bifunctor             (bimap)
import qualified Data.ByteString.Lazy       as BSL
import           Data.Proxy                 (Proxy (Proxy))
import           Data.String                (IsString (..))
import qualified Data.Text                  as Text
import           Data.Word                  (Word8)
import           GHC.Generics               (Generic)
import qualified Language.PlutusTx.Builtins as Builtins
import           Language.PlutusTx.Lift
import qualified Language.PlutusTx.Prelude  as P
import           Schema                     (ToSchema (toSchema))
import           Schema.IOTS                (HasReps (typeReps))
import           Web.HttpApiData            (FromHttpApiData (..), ToHttpApiData (..))

fromHex :: BSL.ByteString -> LedgerBytes
fromHex = LedgerBytes . asBSLiteral
  where
    handleChar :: Word8 -> Word8
    handleChar x
      | x >= 48 && x <= 57 = x - 48 -- hexits 0-9
      | x >= 97 && x <= 102 = x - 87 -- hexits a-f
      | x >= 65 && x <= 70 = x - 55 -- hexits A-F
      | otherwise = error "not a hexit"
    -- turns a pair of bytes such as "a6" into a single Word8
    handlePair :: Word8 -> Word8 -> Word8
    handlePair c c' = 16 * handleChar c + handleChar c'
    asBytes :: [Word8] -> [Word8]
    asBytes []        = mempty
    asBytes (c:c':cs) = handlePair c c' : asBytes cs
    asBytes _         = error "unpaired digit"
    -- parses a bytestring such as @a6b4@ into an actual bytestring
    asBSLiteral :: BSL.ByteString -> BSL.ByteString
    asBSLiteral = withBytes asBytes
      where
        withBytes f = BSL.pack . f . BSL.unpack

-- | 'Bultins.SizedByteString 32' with various useful JSON and
--   servant instances for the Playground, and a convenient bridge
--   type for PureScript.
newtype LedgerBytes =
  LedgerBytes
    { getLedgerBytes :: Builtins.ByteString
    } -- TODO: use strict bytestring
  deriving (Eq, Ord, Serialise, Generic)
  deriving newtype (P.Eq, P.Ord)

bytes :: LedgerBytes -> BSL.ByteString
bytes = getLedgerBytes

fromBytes :: BSL.ByteString -> LedgerBytes
fromBytes = LedgerBytes

instance IsString LedgerBytes where
  fromString = fromHex . fromString

instance Show LedgerBytes where
  show = Text.unpack . JSON.encodeByteString . BSL.toStrict . bytes

instance ToSchema LedgerBytes where
  toSchema _ = toSchema (Proxy :: Proxy String)

instance HasReps LedgerBytes where
  typeReps = typeReps @String

instance ToJSON LedgerBytes where
  toJSON = JSON.String . JSON.encodeByteString . BSL.toStrict . bytes

instance FromJSON LedgerBytes where
  parseJSON v = fromBytes . BSL.fromStrict <$> JSON.decodeByteString v

instance ToHttpApiData LedgerBytes where
  toUrlPiece = JSON.encodeByteString . BSL.toStrict . bytes

instance FromHttpApiData LedgerBytes where
  parseUrlPiece = bimap Text.pack (fromBytes . BSL.fromStrict) . JSON.tryDecode

instance JSON.ToJSONKey LedgerBytes

instance JSON.FromJSONKey LedgerBytes

makeLift ''LedgerBytes
