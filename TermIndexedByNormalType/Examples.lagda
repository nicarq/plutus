\begin{code}
module TermIndexedByNormalType.Examples where
\end{code}

## Imports

\begin{code}
open import Type
open import Type.BetaNormal
open import Type.BetaNBE.RenamingSubstitution
import Type.RenamingSubstitution as ⋆
open import TermIndexedByNormalType.Term
open import TermIndexedByNormalType.Term.RenamingSubstitution
open import TermIndexedByNormalType.Evaluation

open import Relation.Binary.PropositionalEquality renaming (subst to substEq)
\end{code}

## Examples

### Scott Numerals

From http://lucacardelli.name/Papers/Notes/scott2.pdf

M = μ X . G X
G X = ∀ R. R → (X → R) → R)
μ X . G X = ∀ X . (G X → X) → X -- what is the status of this?
N = G M
in  : N → M
out : M → N

0    = Λ R . λ x : R . λ y : M → R . x
     : N
succ = λ n : N . Λ R . λ x : R . λ y : M → R . y (in n)
     : N → N
case = λ n : N . Λ R . λ a : R . λ f : N → N . n [R] a (f ∘ out)
     : N → ∀ R . R → (N → R) → R


--

\begin{code}
module Scott where
  open import Type.BetaNBE
  open import Type.BetaNBE.Stability

  _·Nf_ : ∀{Γ}{K J}
    → Γ ⊢Nf⋆ K ⇒ J
    → Γ ⊢Nf⋆ K
    → Γ ⊢Nf⋆ J
  f ·Nf a = nf (embNf f · embNf a)

  μ0 : ∀{Γ} → Γ ⊢Nf⋆ (* ⇒ *) ⇒ *
  μ0 = ƛ (ne (μ1 · ƛ (ƛ (ne (` Z · ne (` (S Z) · ne (` Z))))) · ne (` Z)))

  wrap0 : ∀{Γ}
    → (pat : ∥ Γ ∥ ⊢Nf⋆ * ⇒ *)
    → Γ ⊢ pat ·Nf (μ0 ·Nf pat)
    → Γ ⊢ μ0 ·Nf pat
  wrap0 pat X rewrite stability pat = wrap1 _ pat X

  unwrap0 : ∀{Γ}
    → (pat : ∥ Γ ∥ ⊢Nf⋆ * ⇒ *)
    → Γ ⊢ μ0 ·Nf pat
    → Γ ⊢ pat ·Nf (μ0 ·Nf pat)
  unwrap0 pat X rewrite stability pat = unwrap1 X
  
  G : ∀{Γ} → Γ ,⋆  * ⊢Nf⋆ *
  G = Π (ne (` Z) ⇒ (ne (` (S Z)) ⇒ ne (` Z)) ⇒ ne (` Z))
  
  M : ∀{Γ} → Γ ⊢Nf⋆ *
  M = μ0 ·Nf ƛ G

  N : ∀{Γ} → Γ ⊢Nf⋆ *
  N  =  G [ M ]Nf

  Zero : ∀{Γ} → Γ ⊢ N
  Zero = Λ (ƛ (ƛ (` (S (Z )))))


  Succ : ∀{Γ} → Γ ⊢ N ⇒ N
  Succ = ƛ (Λ (ƛ (ƛ (` Z · wrap0 (ƛ G) (` (S (S (T Z))))))))

  One : ∀{Γ} → Γ ⊢ N
  One = Succ · Zero
  
  Two : ∀{Γ} → Γ ⊢ N
  Two = Succ · One

  Three : ∅ ⊢ N
  Three = Succ · Two

  Four : ∅ ⊢ N
  Four = Succ · Three

  case : ∀{Γ} → Γ ⊢ N ⇒ (Π (ne (` Z) ⇒ (N ⇒ ne (` Z)) ⇒ ne (` Z)))
  case = ƛ (Λ (ƛ (ƛ ((` (S (S (T Z)))) ·⋆ ne (` Z) · (` (S Z)) · (ƛ (` (S Z) ·  unwrap0 (ƛ G) (` Z) ))))))

{-
  Y-comb : ∀{Γ} → Γ ⊢ Π ((ne (` Z) ⇒ ne (` Z)) ⇒ ne (` Z))
  Y-comb = Λ (ƛ ((ƛ (` (S Z) · (unwrap • refl (` Z) · (` Z)))) · wrap (ne (` Z) ⇒ ne (` (S Z))) • (ƛ (` (S Z) · (unwrap • refl (` Z) · (` Z)))) refl ))
-}
  Z-comb : ∀{Γ} →
    Γ ⊢ Π {- a -} (Π {- b -} (((ne (` (S Z)) ⇒ ne (` Z)) ⇒ ne (` (S Z)) ⇒ ne (` Z)) ⇒ ne (` (S Z)) ⇒ ne (` Z)))
  Z-comb = Λ {- a -} (Λ {- b -} (ƛ {- f -} (ƛ {- r -} (` (S Z) · ƛ {- x -} (unwrap0  (ƛ (ne (` Z) ⇒ ne (` (S (S Z))) ⇒ ne (` (S Z))))  (` (S Z)) · ` (S Z) · ` Z)) · wrap0 (ƛ (ne (` Z) ⇒ ne (` (S (S Z))) ⇒ ne (` (S Z)))) (ƛ {- r -} (` (S Z) · ƛ {- x -} (unwrap0 (ƛ (ne (` Z) ⇒ ne (` (S (S Z))) ⇒ ne (` (S Z)))) (` (S Z)) · ` (S Z) · ` Z))))))

  OnePlus : ∀{Γ} → Γ ⊢ (N ⇒ N) ⇒ N ⇒ N
  OnePlus = ƛ (ƛ ((((case · (` Z)) ·⋆ N) · One) · (ƛ (Succ · (` (S (S Z)) · (` Z))))))

  OnePlusOne : ∅ ⊢ N
  OnePlusOne = (Z-comb ·⋆ N) ·⋆ N · OnePlus · One

 -- Roman's more efficient version
  Plus : ∀ {Γ} → Γ ⊢ N ⇒ N ⇒ N
  Plus = ƛ (ƛ ((Z-comb ·⋆ N) ·⋆ N · (ƛ (ƛ ((((case · ` Z) ·⋆ N) · ` (S (S (S Z)))) · (ƛ (Succ · (` (S (S Z)) · ` Z)))))) · ` (S Z)))

  TwoPlusTwo : ∅ ⊢ N
  TwoPlusTwo = (Plus · Two) · Two
\end{code}

eval (gas 10000000) Scott.Four

(done
 (Λ
  (ƛ
   (ƛ
    ((` Z) ·
     wrap (Π (` Z) ⇒ ((` (S Z)) ⇒ (` Z)) ⇒ (` Z))
     (Λ
      (ƛ
       (ƛ
        ((` Z) ·
         wrap (Π (` Z) ⇒ ((` (S Z)) ⇒ (` Z)) ⇒ (` Z))
         (Λ
          (ƛ
           (ƛ
            ((` Z) ·
             wrap (Π (` Z) ⇒ ((` (S Z)) ⇒ (` Z)) ⇒ (` Z))
             (Λ
              (ƛ
               (ƛ
                ((` Z) ·
                 wrap (Π (` Z) ⇒ ((` (S Z)) ⇒ (` Z)) ⇒ (` Z))
                 (Λ (ƛ (ƛ (` (S Z)))))))))))))))))))))
 .Term.Reduction.Value.V-Λ_)

eval (gas 10000000) Scott.Two
(done
 (Λ
  (ƛ
   (ƛ
    ((` Z) ·
     wrap (Π (` Z) ⇒ ((` (S Z)) ⇒ (` Z)) ⇒ (` Z))
     (Λ
      (ƛ
       (ƛ
        ((` Z) ·
         wrap (Π (` Z) ⇒ ((` (S Z)) ⇒ (` Z)) ⇒ (` Z))
         (Λ (ƛ (ƛ (` (S Z)))))))))))))
 .Term.Reduction.Value.V-Λ_)

### Church Numerals

\begin{code}
module Church where

  N : ∀{Γ} → Γ ⊢Nf⋆ *
  N = Π ((ne (` Z)) ⇒ (ne (` Z) ⇒ ne (` Z)) ⇒ (ne (` Z)))

  Zero : ∅ ⊢ N
  Zero = Λ (ƛ (ƛ (` (S Z))))

  Succ : ∅ ⊢ N ⇒ N
  Succ = ƛ (Λ (ƛ (ƛ (` Z · ((` (S (S (T Z)))) ·⋆ (ne (` Z)) · (` (S Z)) · (` Z))))))
  
  Iter : ∅ ⊢ Π (ne (` Z) ⇒ (ne (` Z) ⇒ ne (` Z)) ⇒ N ⇒ ne (` Z))
  Iter = Λ (ƛ (ƛ (ƛ ((` Z) ·⋆ ne (` Z) · (` (S (S Z))) · (` (S Z))))))

  -- two plus two
  One : ∅ ⊢ N
  One = Succ · Zero

  Two : ∅ ⊢ N
  Two = Succ · One

  Three : ∅ ⊢ N
  Three = Succ · Two

  Four : ∅ ⊢ N
  Four = Succ · Three

  Plus : ∅ ⊢ N → ∅ ⊢ N → ∅ ⊢ N
  Plus x y = Iter ·⋆ N · x · Succ · y -- by induction on the second y

  TwoPlusTwo = Plus Two Two

  TwoPlusTwo' : ∅ ⊢ N
  TwoPlusTwo' = Two ·⋆ N · Two · Succ

open Church public
\end{code}

-- Church "4"
eval (gas 100000000) Four
(done
 (Λ
  (ƛ
   (ƛ
    (` Z) ·
    (((Λ
       (ƛ
        (ƛ
         (` Z) ·
         (((Λ
            (ƛ
             (ƛ
              (` Z) ·
              (((Λ
                 (ƛ
                  (ƛ
                   (` Z) · (((Λ (ƛ (ƛ (` (S Z))))) ·⋆ (` Z)) · (` (S Z)) · (` Z)))))
                ·⋆ (` Z))
               · (` (S Z))
               · (` Z)))))
           ·⋆ (` Z))
          · (` (S Z))
          · (` Z)))))
      ·⋆ (` Z))
     · (` (S Z))
     · (` Z)))))
 V-Λ_)

-- Church "2 + 2" using iterator
eval (gas 100000000) (Plus Two Two)

(done
 (Λ
  (ƛ
   (ƛ
    (` Z) ·
    (((Λ
       (ƛ
        (ƛ
         (` Z) ·
         (((Λ
            (ƛ
             (ƛ
              (` Z) ·
              (((Λ
                 (ƛ
                  (ƛ
                   (` Z) · (((Λ (ƛ (ƛ (` (S Z))))) ·⋆ (` Z)) · (` (S Z)) · (` Z)))))
                ·⋆ (` Z))
               · (` (S Z))
               · (` Z)))))
           ·⋆ (` Z))
          · (` (S Z))
          · (` Z)))))
      ·⋆ (` Z))
     · (` (S Z))
     · (` Z)))))
 V-Λ_)

-- Church "2 + 2" using the numerals directly
eval (gas 10000000) (Two ·⋆ N · Two · Succ)

(done
 (Λ
  (ƛ
   (ƛ
    ((` Z) ·
     ((((Λ
         (ƛ
          (ƛ
           ((` Z) ·
            ((((Λ
                (ƛ
                 (ƛ
                  ((` Z) ·
                   ((((Λ
                       (ƛ
                        (ƛ
                         ((` Z) ·
                          ((((Λ (ƛ (ƛ (` (S Z))))) ·⋆ (` Z)) · (` (S Z))) · (` Z))))))
                      ·⋆ (` Z))
                     · (` (S Z)))
                    · (` Z))))))
               ·⋆ (` Z))
              · (` (S Z)))
             · (` Z))))))
        ·⋆ (` Z))
       · (` (S Z)))
      · (` Z))))))
 V-Λ_)
