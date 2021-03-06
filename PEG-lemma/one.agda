-- related to http://stackoverflow.com/questions/29260874/problems-on-data-type-indices-that-uses-list-concatenation

open import Data.List
open import Data.Fin hiding (_+_)
open import Data.Nat renaming (ℕ to Nat)
open import Data.Product as P
open import Data.Vec using (Vec ; lookup)
open import Data.Empty
open import Relation.Nullary
open import Relation.Binary.PropositionalEquality renaming (_≡_ to _==_ ; sym to symm)
open import Data.Maybe
open import Function

postulate A : Set

data Foo : Nat -> Set where
  emp : forall {n} -> Foo n
  sym : forall {n} -> A -> Foo n
  var : forall {n} -> Fin (suc n) -> Foo n
  _o_ : forall {n} -> Foo n -> Foo n -> Foo n
 
Con : Nat -> Set
Con n = Vec (Foo n) (suc n)
 
infix 1 _::_=>_

data _::_=>_ {n} (G : Con n) : Foo n × List A -> Nat × Maybe (List A) -> Set where
  empty       : ∀ {x}     -> G :: emp   ,  x      => 1 , just []
  sym-success : ∀ {a x}   -> G :: sym a , (a ∷ x) => 1 , just (a ∷ [])
  sym-failure : ∀ {a b x} -> ¬ (a == b) -> G :: sym a , b ∷ x => 1 , nothing
  var         : ∀ {x m o} {v : Fin (suc n)}
              -> G :: lookup v G , x => m , o -> G :: var v , x => suc m , o
  o-success : ∀ {e e' x x' y n n'}
            -> G :: e      , x ++ x' ++ y => n            , just x
            -> G :: e'     ,      x' ++ y => n'           , just x'
            -> G :: e o e' , x ++ x' ++ y => suc (n + n') , just (x ++ x')
  o-fail1   : ∀ {e e' x x' y n}
            -> G :: e      , x ++ x' ++ y => n     , nothing
            -> G :: e o e' , x ++ x' ++ y => suc n , nothing
  o-fail2   : ∀ {e e' x x' y n n'}
            -> G :: e      , x ++ x' ++ y => n            , just x
            -> G :: e'     ,      x' ++ y => n'           , nothing
            -> G :: e o e' , x ++ x' ++ y => suc (n + n') , nothing

postulate
  cut : ∀ {α} {A : Set α} -> ∀ xs {ys zs : List A} -> xs ++ ys == xs ++ zs -> ys == zs

mutual
  aux : ∀ {n} {G : Con n} {e e' z x x' y n n' m' p'}
      -> z == x ++ x' ++ y
      -> G :: e      , z       => n  , just x
      -> G :: e'     , x' ++ y => n' , just x'
      -> G :: e o e' , z       => m' , p'
      -> suc (n + n') == m' × just (x ++ x') == p'
  aux {x = x} {x'} {n = n} {n'} r pr1 pr2 (o-success {x = x''} pr3 pr4) with x | n | lemma pr1 pr3
  ... | ._ | ._ | refl , refl rewrite cut x'' r with x' | n' | lemma pr2 pr4
  ... | ._ | ._ | refl , refl = refl , refl
  aux         r pr1 pr2 (o-fail1           pr3)     = case proj₂ (lemma pr1 pr3) of λ()
  aux {x = x} r pr1 pr2 (o-fail2 {x = x''} pr3 pr4) with x | lemma pr1 pr3
  ... | ._ | _ , refl rewrite cut x'' r = case proj₂ (lemma pr2 pr4) of λ()

  lemma : ∀ {n m m'} {G : Con n} {f x p p'}
        -> G :: f , x => m , p -> G :: f , x => m' , p' -> m == m' × p == p'
  lemma  empty               empty          = refl , refl
  lemma  sym-success         sym-success    = refl , refl
  lemma  sym-success        (sym-failure p) = ⊥-elim (p refl)
  lemma (sym-failure p)      sym-success    = ⊥-elim (p refl)
  lemma (sym-failure _)     (sym-failure _) = refl , refl
  lemma (var pr1)           (var pr2)       = P.map (cong suc) id (lemma pr1 pr2)
  lemma (o-success pr1 pr2)  pr3            = aux refl pr1 pr2 pr3
  lemma (o-fail1   pr1)      pr2            = {!!}
  lemma (o-fail2   pr1 pr2)  pr3            = {!!}
