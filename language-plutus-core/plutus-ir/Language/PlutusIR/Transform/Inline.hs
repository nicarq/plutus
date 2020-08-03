{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs            #-}
{-# LANGUAGE LambdaCase       #-}
{-# LANGUAGE TypeFamilies     #-}
{-# LANGUAGE TypeOperators    #-}
{-|
A simple inlining pass.

The point of this pass is mainly to tidy up the code, not to particularly optimize performance.
In particular, we want to get rid of "trivial" let bindings which the Plutus Tx compiler sometimes creates.
-}
module Language.PlutusIR.Transform.Inline where

import           Language.PlutusIR
import           Language.PlutusIR.Transform.Substitute

import           Language.PlutusCore.Name

import           Control.Lens                           hiding (Strict)

{- Note [Repeated inlining]
Consider the following program:

let x = 1 in let y = x in y

If we naively inlined both bindings, we might end up with

let x = 1 in let y = 1 in x

What happened? The substitution y->x itself mentions a variable we want to
inline!

There are various ways to fix this, but ultimately they all involve doing
substitutions multiple times (and hence multiple tree traversals). We'd ideally
like to minimize this.

The approach we take is to:
- Collect all the substitutions we want to do in the whole program (needs
global uniqueness).
- Apply all the substitutions bottom up, at each point applying the substitution
to the substituted term until we can't do any more.

This is not terribly efficient, since we keep trying to re-apply our substitutions,
and as we go up the tree we will keep doing this. So we could probably do this better
but we don't try at the moment.
-}

{- Note [Inlining criteria]
What gets inlined? We don't really care about performance here, so we're really just
angling to simplify the code without making things worse.

The obvious candidates are tiny things like builtins, variables, or constants.
We could also consider inlining variables with arbitrary RHSs that are used only
once, but we don't do that currently.
-}

{- Note [Inlining bindings]
We can inline term and type bindings, we can't do anything with datatype bindings.

We don't actually inline type bindings at the moment, mostly because I think it
won't get us much as they aren't created very often..
-}

type Inlinings tyname name uni a = UniqueMap TermUnique (Term tyname name uni a)

-- | Inline simple bindings. Relies on global uniqueness, and preserves it.
inline
    :: (HasUnique name TermUnique)
    => Term tyname name uni a
    -> Term tyname name uni a
inline t =
    let inlinings = collectInlinings t
    -- Do the substitutions, iterating until we can't do any more.
    -- See Note [Repeated inlining]
    in termSubstNamesRepeat (\x -> lookupName x inlinings) t

-- | Is this a an utterly trivial term which might as well be inlined?
trivialTerm :: Term tyname name uni a -> Bool
trivialTerm = \case
    Builtin{} -> True
    Var{} -> True
    -- TODO: Should this depend on the size of the constant?
    Constant{} -> True
    _ -> False

collectBindingInlinings
    :: (HasUnique name TermUnique)
    => Recursivity
    -> Binding tyname name uni a
    -> Inlinings tyname name uni a
collectBindingInlinings Rec = const  mempty
collectBindingInlinings NonRec = \case
    -- See Note [Inlining criteria]
    -- See Note [Inlining bindings]
    TermBind _ Strict (VarDecl _ n _) rhs | trivialTerm rhs -> insertByName n rhs mempty
    _ -> mempty

collectInlinings
    :: (HasUnique name TermUnique)
    => Term tyname name uni a
    -> Inlinings tyname name uni a
collectInlinings x =
    let subtermInlinings = foldMapOf termSubterms collectInlinings x
        bindingInlinings = case x of
            -- Can't quite just compose the termBindings traversal, since
            -- we need to know the recursivity
            Let _ r bs _ -> foldMap (collectBindingInlinings r) bs
            _            -> mempty
    in subtermInlinings <> bindingInlinings
