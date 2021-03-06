-- Stealing the idea from András Kovács:
-- https://github.com/AndrasKovacs/misc-stuff/blob/master/agda/Fin-neq-Nat.agda

open import Relation.Binary.PropositionalEquality
open import Relation.Nullary
open import Data.Empty
open import Data.Nat.Base
open import Data.Nat.Properties
open import Data.Fin       hiding (_≤_; _<_)
open import Data.Product   renaming (map to pmap)
open import Data.List.Base renaming (map to lmap)

infix 4 _∈_ _∉_

data _∈_ {α} {A : Set α} (x : A) : List A -> Set where
  here  : ∀ {xs}   -> x ∈ x ∷ xs
  there : ∀ {y xs} -> x ∈ xs -> x ∈ y ∷ xs

_∉_ : ∀ {α} {A : Set α} -> A -> List A -> Set
x ∉ xs = x ∈ xs -> ⊥

Finite : ∀ {α} -> Set α -> Set α
Finite A = ∃ λ xs -> (x : A) -> x ∈ xs

∈-map : ∀ {α β} {A : Set α} {B : Set β} {f : A -> B} {x xs} -> x ∈ xs -> f x ∈ lmap f xs
∈-map  here     = here
∈-map (there p) = there (∈-map p)

finiteFin : ∀ n -> Finite (Fin n)
finiteFin  0      = [] , λ()
finiteFin (suc n) with finiteFin n
... | xs , k = zero ∷ lmap suc xs , λ{ zero -> here ; (suc i) -> there (∈-map (k i)) }

maximum : List ℕ -> ℕ
maximum = foldr _⊔_ 0

⊔-≤ : ∀ {m p} n -> n ⊔ m ≤ p -> n ≤ p × m ≤ p
⊔-≤          0       q      = z≤n , q
⊔-≤ {0}     (suc n)  q      = q , z≤n
⊔-≤ {suc m} (suc n) (s≤s q) = pmap s≤s s≤s (⊔-≤ n q)

<-max-∉ : ∀ {m} {ns : List ℕ} -> maximum ns < m -> m ∉ ns
<-max-∉ {ns = n ∷ ns} p  here     = 1+n≰n (proj₁ (⊔-≤ {m = suc (maximum ns)} (suc n) p))
<-max-∉ {ns = n ∷ ns} p (there q) = <-max-∉ (proj₂ (⊔-≤ (suc n) p)) q

notFiniteℕ : ¬ Finite ℕ
notFiniteℕ (ns , k) = <-max-∉ (n≤1+n _) (k _)

Fin≢ℕ : ∀ n -> Fin n ≢ ℕ
Fin≢ℕ n p = notFiniteℕ (subst Finite p (finiteFin n))
