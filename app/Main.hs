module Main (main) where

import AlwaysFails (pAlwaysFails)
import Cardano.Binary qualified as CBOR
import Config (pmintConfigToken)
import Data.Aeson (KeyValue ((.=)), object)
import Data.Aeson.Encode.Pretty (encodePretty)
import Data.Bifunctor (
  first,
 )
import Data.ByteString.Base16 qualified as Base16
import Data.ByteString.Lazy qualified as LBS
import Data.Text (
  Text,
  pack,
 )
import Data.Text.Encoding qualified as Text
import Mint.Standard (mkStakingNodeMPW)
import MultiFold (pfoldValidatorW, pmintFoldPolicyW, pmintRewardFoldPolicyW, prewardFoldValidatorW)
import Plutarch (
  Config (Config),
  TracingMode (NoTracing),
  compile,
 )
import Plutarch.Evaluate (
  evalScript,
 )
import Plutarch.Prelude
import Plutarch.Script (Script, serialiseScript)
import PlutusLedgerApi.V2 (
  Data,
  ExBudget,
 )
import RewardTokenHolder (pmintRewardTokenHolder, prewardTokenHolder)
import Types.Constants (psetNodePrefix)
import Validator (pDiscoverGlobalLogicW, pStakingSetValidator)
import "liqwid-plutarch-extra" Plutarch.Extra.Script (
  applyArguments,
 )

encodeSerialiseCBOR :: Script -> Text
encodeSerialiseCBOR = Text.decodeUtf8 . Base16.encode . CBOR.serialize' . serialiseScript

evalT :: ClosedTerm a -> Either Text (Script, ExBudget, [Text])
evalT x = evalWithArgsT x []

evalWithArgsT :: ClosedTerm a -> [Data] -> Either Text (Script, ExBudget, [Text])
evalWithArgsT x args = do
  cmp <- compile (Config NoTracing) x
  let (escr, budg, trc) = evalScript $ applyArguments cmp args
  scr <- first (pack . show) escr
  pure (scr, budg, trc)

writePlutusScript :: String -> FilePath -> ClosedTerm a -> IO ()
writePlutusScript title filepath term = do
  case evalT term of
    Left e -> putStrLn (show e)
    Right (script, _, _) -> do
      let
        scriptType = "PlutusScriptV2" :: String
        plutusJson = object ["type" .= scriptType, "description" .= title, "cborHex" .= encodeSerialiseCBOR script]
        content = encodePretty plutusJson
      LBS.writeFile filepath content

main :: IO ()
main = do
  putStrLn "Exporting Single Asset Staking Scripts"
  writePlutusScript "Single Asset Staking - Config Policy" "./compiled/configPolicy.json" pmintConfigToken
  writePlutusScript "Single Asset Staking - Staking Validator" "./compiled/nodeStakeValidator.json" pDiscoverGlobalLogicW
  writePlutusScript "Single Asset Staking - Spending Validator" "./compiled/nodeValidator.json" $ pStakingSetValidator $ plift psetNodePrefix
  writePlutusScript "Single Asset Staking - Minting Validator" "./compiled/nodePolicy.json" $ mkStakingNodeMPW
  writePlutusScript "Commit Fold Validator" "./compiled/foldValidator.json" pfoldValidatorW
  writePlutusScript "Commit Fold Mint" "./compiled/foldPolicy.json" pmintFoldPolicyW
  writePlutusScript "Reward Fold Validator" "./compiled/rewardFoldValidator.json" prewardFoldValidatorW
  writePlutusScript "Reward Fold Mint" "./compiled/rewardFoldPolicy.json" pmintRewardFoldPolicyW
  writePlutusScript "Token Holder Validator" "./compiled/tokenHolderValidator.json" prewardTokenHolder
  writePlutusScript "Token Holder Policy" "./compiled/tokenHolderPolicy.json" pmintRewardTokenHolder
  writePlutusScript "Always Fails" "./compiled/alwaysFails.json" pAlwaysFails
