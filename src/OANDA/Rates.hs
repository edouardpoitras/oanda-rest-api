{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Defines the endpoints listed in the
-- <http://developer.oanda.com/rest-live/rates/ Rates> section of the API.

module OANDA.Rates
       ( InstrumentsArgs (..)
       , instrumentsArgs
       , Instrument (..)
       , instruments
       ) where

import           Control.Lens
import           Data.Aeson
import qualified Data.Map as Map
import           Data.Text (Text, pack)
import qualified Data.Vector as V
import           GHC.Generics (Generic)
import           Network.Wreq

import           OANDA.Util
import           OANDA.Types


data InstrumentsArgs = InstrumentsArgs
  { instrumentsFields      :: [Text]
  , instrumentsInstruments :: [Text]
  } deriving (Show)

instrumentsArgs :: InstrumentsArgs
instrumentsArgs = InstrumentsArgs ["displayName", "pip", "maxTradeUnits"] []

data Instrument = Instrument
  { instrumentInstrument    :: String
  , instrumentPip           :: Maybe String
  , instrumentMaxTradeUnits :: Maybe Double
  , instrumentDisplayName   :: Maybe String
  } deriving (Show, Generic)

instance FromJSON Instrument where
  parseJSON = genericParseJSON $ jsonOpts "instrument"

type InstrumentResponse = IO (Response (Map.Map String (V.Vector Instrument)))

-- | Retrieve a list of instruments from OANDA
instruments :: APIType -> AccountID -> AccessToken -> InstrumentsArgs -> IO (V.Vector Instrument)
instruments apit (AccountID aid) t (InstrumentsArgs fs is) = do
  let url = apiEndpoint apit ++ "/v1/instruments"
      opts = constructOpts t [ ("accountId", [pack $ show aid])
                             , ("instruments", is)
                             , ("fields", fs)
                             ]

  r <- asJSON =<< getWith opts url :: InstrumentResponse
  let body = r ^. responseBody
      is' = body Map.! "instruments"
  return is'
