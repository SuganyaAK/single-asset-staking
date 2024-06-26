{-# OPTIONS_GHC -Wno-missing-export-lists #-}
{-# OPTIONS_GHC -Wno-unused-do-bind #-}

module Types.Constants where

import Plutarch
import Plutarch.Api.V1 (PTokenName (..))
import Plutarch.Monadic qualified as P
import Plutarch.Prelude
import PlutusLedgerApi.V1 (TokenName)
import Utils (passert, pisPrefixOf)

rewardTokenHolderTN :: Term s PTokenName
rewardTokenHolderTN =
  let tn :: TokenName
      tn = "RTHolder"
   in pconstant tn

commitFoldTN :: Term s PTokenName
commitFoldTN =
  let tn :: TokenName
      tn = "CFold"
   in pconstant tn

rewardFoldTN :: Term s PTokenName
rewardFoldTN =
  let tn :: TokenName
      tn = "RFold"
   in pconstant tn

poriginNodeTN :: Term s PTokenName
poriginNodeTN =
  let tn :: TokenName
      tn = "FSN"
   in pconstant tn

psetNodePrefix :: ClosedTerm PByteString
psetNodePrefix = pconstant "FSN"

pnodeKeyTN :: ClosedTerm (PByteString :--> PTokenName)
pnodeKeyTN = phoistAcyclic $
  plam $
    \nodeKey -> pcon $ PTokenName $ psetNodePrefix <> nodeKey

pparseNodeKey :: ClosedTerm (PTokenName :--> PMaybe PByteString)
pparseNodeKey = phoistAcyclic $
  plam $ \(pto -> tn) -> P.do
    let prefixLength = 3
        tnLength = plengthBS # tn
        key = psliceBS # prefixLength # (tnLength - prefixLength) # tn
    passert "incorrect node prefix" $ pisPrefixOf # psetNodePrefix # tn
    pif (prefixLength #< tnLength) (pcon $ PJust key) (pcon PNothing)

foldingFee :: Term s PInteger
foldingFee = pconstant 1_000_000

minAda :: Term s PInteger
minAda = pconstant 2_000_000

nodeAda :: Term s PInteger
nodeAda = pconstant 3_000_000
