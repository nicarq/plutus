{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ViewPatterns     #-}
-- | Implements naive substitution functions for replacing type and term variables.
module Language.PlutusIR.Transform.Substitute (
      substVar
    , substTyVar
    , typeSubstTyNames
    , termSubstNames
    , termSubstNamesRepeat
    , termSubstTyNames
    , bindingSubstNames
    , bindingSubstTyNames
    ) where

import           Language.PlutusIR

import           Language.PlutusCore.Subst (substTyVar, typeSubstTyNames)

import           Control.Lens

import           Data.Maybe

-- Needs to be different from the PLC version since we have different Terms
-- | Replace a variable using the given function.
substVar :: (name -> Maybe (Term tyname name uni a)) -> Term tyname name uni a -> Maybe (Term tyname name uni a)
substVar nameF (Var _ (nameF -> Just t)) = Just t
substVar _     _                         = Nothing

-- | Naively substitute names using the given functions (i.e. do not substitute binders).
termSubstNames :: (name -> Maybe (Term tyname name uni a)) -> Term tyname name uni a -> Term tyname name uni a
termSubstNames nameF = transformOf termSubterms (\x -> fromMaybe x (substVar nameF x))

-- | Naively substitute names using the given functions (i.e. do not substitute binders). Repeatedly re-substitutes
-- until no more changes occur, so can handle substitutions where the substituted terms reference the variables
-- which are being substituted for. Consequently, do *not* pass this a recursive substitution or it won't terminate.
termSubstNamesRepeat :: (name -> Maybe (Term tyname name uni a)) -> Term tyname name uni a -> Term tyname name uni a
termSubstNamesRepeat nameF = rewriteOf termSubterms (substVar nameF)

-- | Naively substitute type names using the given functions (i.e. do not substitute binders).
termSubstTyNames :: (tyname -> Maybe (Type tyname uni a)) -> Term tyname name uni a -> Term tyname name uni a
termSubstTyNames tynameF = over termSubterms (termSubstTyNames tynameF) . over termSubtypes (typeSubstTyNames tynameF)

-- | Naively substitute names using the given functions (i.e. do not substitute binders).
bindingSubstNames :: (name -> Maybe (Term tyname name uni a)) -> Binding tyname name uni a -> Binding tyname name uni a
bindingSubstNames nameF = over bindingSubterms (termSubstNames nameF)

-- | Naively substitute type names using the given functions (i.e. do not substitute binders).
bindingSubstTyNames :: (tyname -> Maybe (Type tyname uni a)) -> Binding tyname name uni a -> Binding tyname name uni a
bindingSubstTyNames tynameF = over bindingSubterms (termSubstTyNames tynameF) . over bindingSubtypes (typeSubstTyNames tynameF)
