{- Byzantine Fault Tolerant Consensus Verification in Agda, version 0.9.

   Copyright (c) 2020 Oracle and/or its affiliates.
   Licensed under the Universal Permissive License v 1.0 as shown at https://opensource.oracle.com/licenses/upl
-}
open import LibraBFT.Prelude

open import Level using (0ℓ)

-- This module incldes various Agda lemmas that are independent of the project's domain

module LibraBFT.Lemmas where

 cong₃ : ∀{a b c d}{A : Set a}{B : Set b}{C : Set c}{D : Set d}
       → (f : A → B → C → D) → ∀{x y u v m n} → x ≡ y → u ≡ v → m ≡ n
       → f x u m ≡ f y v n
 cong₃ f refl refl refl = refl

 ≡-pi : ∀{a}{A : Set a}{x y : A}(p q : x ≡ y) → p ≡ q
 ≡-pi refl refl = refl

 Unit-pi : {u1 u2 : Unit}
         → u1 ≡ u2
 Unit-pi {unit} {unit} = refl

 ++-inj : ∀{a}{A : Set a}{m n o p : List A}
        → length m ≡ length n → m ++ o ≡ n ++ p
        → m ≡ n × o ≡ p
 ++-inj {m = []}     {x ∷ n} () hip
 ++-inj {m = x ∷ m}  {[]}    () hip
 ++-inj {m = []}     {[]}     lhip hip
   = refl , hip
 ++-inj {m = m ∷ ms} {n ∷ ns} lhip hip
   with ++-inj {m = ms} {ns} (suc-injective lhip) (proj₂ (∷-injective hip))
 ...| (mn , op) rewrite proj₁ (∷-injective hip)
    = cong (n ∷_) mn , op

 ++-abs : ∀{a}{A : Set a}{n : List A}(m : List A)
        → 1 ≤ length m → [] ≡ m ++ n → ⊥
 ++-abs [] ()
 ++-abs (x ∷ m) imp ()


 data All-vec {ℓ} {A : Set ℓ} (P : A → Set ℓ) : ∀ {n} → Vec {ℓ} A n → Set (Level.suc ℓ) where
   []  : All-vec P []
   _∷_ : ∀ {x n} {xs : Vec A n} (px : P x) (pxs : All-vec P xs) → All-vec P (x ∷ xs)

 ≤-unstep : ∀{m n} → suc m ≤ n → m ≤ n
 ≤-unstep (s≤s ss) = ≤-step ss

 ≡⇒≤ : ∀{m n} → m ≡ n → m ≤ n
 ≡⇒≤ refl = ≤-refl

 ∈-cong : ∀{a b}{A : Set a}{B : Set b}{x : A}{l : List A}
        → (f : A → B) → x ∈ l → f x ∈ List-map f l
 ∈-cong f (here px) = here (cong f px)
 ∈-cong f (there hyp) = there (∈-cong f hyp)

 All-self : ∀{a}{A : Set a}{xs : List A} → All (_∈ xs) xs
 All-self = All-tabulate (λ x → x)

 All-reduce⁺
   : ∀{a b}{A : Set a}{B : Set b}{Q : A → Set}{P : B → Set}
   → { xs : List A }
   → (f : ∀{x} → Q x → B)
   → (∀{x} → (prf : Q x) → P (f prf))
   → (all : All Q xs)
   → All P (All-reduce f all)
 All-reduce⁺ f hyp []         = []
 All-reduce⁺ f hyp (ax ∷ axs) = (hyp ax) ∷ All-reduce⁺ f hyp axs

 All-reduce⁻
   : ∀{a b}{A : Set a}{B : Set b}
     {Q : A → Set}
   → { xs : List A }
   → ∀ {vdq}
   → (f : ∀{x} → Q x → B)
   → (all : All Q xs)
   → vdq ∈ All-reduce f all
   → ∃[ v ] ∃[ v∈xs ] (vdq ≡ f {v} v∈xs)
 All-reduce⁻ {Q = Q} {(h ∷ _)} {vdq} f (px ∷ pxs) (here refl)  = h , px , refl
 All-reduce⁻ {Q = Q} {(_ ∷ t)} {vdq} f (px ∷ pxs) (there vdq∈) = All-reduce⁻ {xs = t} f pxs vdq∈

 List-index : ∀ {A : Set} → (_≟A_ : (a₁ a₂ : A) → Dec (a₁ ≡ a₂)) → A → (l : List A) → Maybe (Fin (length l))
 List-index _≟A_ x l with break (_≟A x) l
 ...| not≡ , _ with length not≡ <? length l
 ...| no  _     = nothing
 ...| yes found = just ( fromℕ< {length not≡} {length l} found)

 nats : ℕ → List ℕ
 nats 0 = []
 nats (suc n) = (nats n) ++ (n ∷ [])

 _ : nats 4 ≡ 0 ∷ 1 ∷ 2 ∷ 3 ∷ []
 _ = refl

 _ : Maybe-map toℕ (List-index _≟_ 2 (nats 4)) ≡ just 2
 _ = refl

 _ : Maybe-map toℕ (List-index _≟_ 4 (nats 4)) ≡ nothing
 _ = refl

 allDistinct : ∀ {A : Set} → List A → Set
 allDistinct l = ∀ (i j : Σ ℕ (_< length l)) →
                   proj₁ i ≡ proj₁ j
                   ⊎ List-lookup l (fromℕ< (proj₂ i)) ≢ List-lookup l (fromℕ< (proj₂ j))

 postulate -- TODO-1: currently unused; prove it, if needed
   allDistinct? : ∀ {A : Set} → {≟A : (a₁ a₂ : A) → Dec (a₁ ≡ a₂)} → (l : List A) → Dec (allDistinct l)

  -- Extends an arbitrary relation to work on the head of
  -- the supplied list, if any.
 data OnHead {A : Set}(P : A → A → Set) (x : A) : List A → Set where
    []   : OnHead P x []
    on-∷ : ∀{y ys} → P x y → OnHead P x (y ∷ ys)

  -- Establishes that a list is sorted according to the supplied
  -- relation.
 data IsSorted {A : Set}(_<_ : A → A → Set) : List A → Set where
    []  : IsSorted _<_ []
    _∷_ : ∀{x xs} → OnHead _<_ x xs → IsSorted _<_ xs → IsSorted _<_ (x ∷ xs)

 OnHead-prop : ∀{A}(P : A → A → Set)(x : A)(l : List A)
             → Irrelevant P
             → isPropositional (OnHead P x l)
 OnHead-prop P x [] hyp [] [] = refl
 OnHead-prop P x (x₁ ∷ l) hyp (on-∷ x₂) (on-∷ x₃) = cong on-∷ (hyp x₂ x₃)

 IsSorted-prop : ∀{A}(_<_ : A → A → Set)(l : List A)
               → Irrelevant _<_
               → isPropositional (IsSorted _<_ l)
 IsSorted-prop _<_ [] hyp [] []                  = refl
 IsSorted-prop _<_ (x ∷ l) hyp (x₁ ∷ a) (x₂ ∷ b)
   = cong₂ _∷_ (OnHead-prop _<_ x l hyp x₁ x₂)
               (IsSorted-prop _<_ l hyp a b)

 IsSorted-map⁻ : {A : Set}{_≤_ : A → A → Set}
               → {B : Set}(f : B → A)(l : List B)
               → IsSorted (λ x y → f x ≤ f y) l
               → IsSorted _≤_ (List-map f l)
 IsSorted-map⁻ f .[] [] = []
 IsSorted-map⁻ f .(_ ∷ []) (x ∷ []) = [] ∷ []
 IsSorted-map⁻ f .(_ ∷ _ ∷ _) (on-∷ x ∷ (x₁ ∷ is)) = (on-∷ x) ∷ IsSorted-map⁻ f _ (x₁ ∷ is)


 transOnHead : ∀ {A} {l : List A} {y x : A} {_<_ : A → A → Set}
              → Transitive _<_
              → OnHead _<_ y l
              → x < y
              → OnHead _<_ x l
 transOnHead _ [] _ = []
 transOnHead trans (on-∷ y<f) x<y = on-∷ (trans x<y y<f)

 ++-OnHead : ∀ {A} {xs ys : List A} {y : A} {_<_ : A → A → Set}
           → OnHead _<_ y xs
           → OnHead _<_ y ys
           → OnHead _<_ y (xs ++ ys)
 ++-OnHead []         y<y₁ = y<y₁
 ++-OnHead (on-∷ y<x) _    = on-∷ y<x

 h∉t : ∀ {A} {t : List A} {h : A} {_<_ : A → A → Set}
     → Irreflexive _<_ _≡_ → Transitive _<_
     → IsSorted _<_ (h ∷ t)
     → h ∉ t
 h∉t irfl trans (on-∷ h< ∷ sxs) (here refl) = ⊥-elim (irfl h< refl)
 h∉t irfl trans (on-∷ h< ∷ (x₁< ∷ sxs)) (there h∈t)
   = h∉t irfl trans ((transOnHead trans x₁< h<) ∷ sxs) h∈t

 ≤-head : ∀ {A} {l : List A} {x y : A} {_<_ : A → A → Set} {_≤_ : A → A → Set}
        → Reflexive _≤_ → Trans _<_ _≤_ _≤_
        → y ∈ (x ∷ l) → IsSorted _<_ (x ∷ l)
        → _≤_ x y
 ≤-head ref≤ trans (here refl) _ = ref≤
 ≤-head ref≤ trans (there y∈) (on-∷ x<x₁ ∷ sl) = trans x<x₁ (≤-head ref≤ trans y∈ sl)


 -- TODO-1 : Better name and/or replace with library property
 Any-sym : ∀ {a b}{A : Set a}{B : Set b}{tgt : B}{l : List A}{f : A → B}
         → Any (λ x → tgt ≡ f x) l
         → Any (λ x → f x ≡ tgt) l
 Any-sym (here x)  = here (sym x)
 Any-sym (there x) = there (Any-sym x)

 Any-lookup-correct :  ∀ {a b}{A : Set a}{B : Set b}{tgt : B}{l : List A}{f : A → B}
                    → (p : Any (λ x → f x ≡ tgt) l)
                    → Any-lookup p ∈ l
 Any-lookup-correct (here px) = here refl
 Any-lookup-correct (there p) = there (Any-lookup-correct p)

 Any-lookup-correctP :  ∀ {a}{A : Set a}{l : List A}{P : A → Set}
                     → (p : Any P l)
                     → Any-lookup p ∈ l
 Any-lookup-correctP (here px) = here refl
 Any-lookup-correctP (there p) = there (Any-lookup-correctP p)

 Any-witness : ∀ {a b} {A : Set a} {l : List A} {P : A → Set b}
             → (p : Any P l) → P (Any-lookup p)
 Any-witness (here px) = px
 Any-witness (there x) = Any-witness x

 -- TODO-1: there is probably a library property for this.
 ∈⇒Any : ∀ {A : Set}{x : A}
       → {xs : List A}
       → x ∈ xs
       → Any (_≡ x) xs
 ∈⇒Any {x = x} (here refl) = here refl
 ∈⇒Any {x = x} {h ∷ t} (there xxxx) = there (∈⇒Any {xs = t} xxxx)

 false≢true : false ≢ true
 false≢true ()

 witness : {A : Set}{P : A → Set}{x : A}{xs : List A}
         → x ∈ xs → All P xs → P x
 witness x y = All-lookup y x

 maybe-⊥ : ∀{a}{A : Set a}{x : A}{y : Maybe A}
         → y ≡ just x
         → y ≡ nothing
         → ⊥
 maybe-⊥ () refl

 Maybe-map-cool : ∀ {S S₁ : Set} {f : S → S₁} {x : Maybe S} {z}
                → Maybe-map f x ≡ just z
                → x ≢ nothing
 Maybe-map-cool {x = nothing} ()
 Maybe-map-cool {x = just y} prf = λ x → ⊥-elim (maybe-⊥ (sym x) refl)

 Maybe-map-cool-1 : ∀ {S S₁ : Set} {f : S → S₁} {x : Maybe S} {z}
                  → Maybe-map f x ≡ just z
                  → Σ S (λ x' → f x' ≡ z)
 Maybe-map-cool-1 {x = nothing} ()
 Maybe-map-cool-1 {x = just y} {z = z} refl = y , refl

 Maybe-map-cool-2 : ∀ {S S₁ : Set} {f : S → S₁} {x : S} {z}
                  → f x ≡ z
                  → Maybe-map f (just x) ≡ just z
 Maybe-map-cool-2 {S}{S₁}{f}{x}{z} prf rewrite prf = refl

 T⇒true : ∀ {a : Bool} → T a → a ≡ true
 T⇒true {true} _ = refl

 isJust : ∀ {A : Set}{aMB : Maybe A}{a : A}
        → aMB ≡ just a
        → Is-just aMB
 isJust refl = just tt

 to-witness-isJust-≡ : ∀ {A : Set}{aMB : Maybe A}{a prf}
                     → to-witness (isJust {aMB = aMB} {a} prf) ≡ a
 to-witness-isJust-≡ {aMB = just a'} {a} {prf}
    with to-witness-lemma (isJust {aMB = just a'} {a} prf) refl
 ...| xxx = just-injective (trans (sym xxx) prf)


 ∸-suc-≤ : ∀ (x w : ℕ) → suc x ∸ w ≤ suc (x ∸ w)
 ∸-suc-≤ x zero = ≤-refl
 ∸-suc-≤ zero (suc w) rewrite 0∸n≡0 w = z≤n
 ∸-suc-≤ (suc x) (suc w) = ∸-suc-≤ x w

 m∸n≤o⇒m∸o≤n : ∀ (x z w : ℕ) → x ∸ z ≤ w → x ∸ w ≤ z
 m∸n≤o⇒m∸o≤n x zero w p≤ rewrite m≤n⇒m∸n≡0 p≤ = z≤n
 m∸n≤o⇒m∸o≤n zero (suc z) w p≤ rewrite 0∸n≡0 w = z≤n
 m∸n≤o⇒m∸o≤n (suc x) (suc z) w p≤ = ≤-trans (∸-suc-≤ x w) (s≤s (m∸n≤o⇒m∸o≤n x z w p≤))


 _∈?_ : ∀ {n} (x : Fin n) → (xs : List (Fin n)) → Dec (Any (x ≡_) xs)
 x ∈? xs = Any-any (x ≟Fin_) xs


 y∉xs⇒Allxs≢y : ∀ {n} {xs : List (Fin n)} {x y}
         → y ∉ (x ∷ xs)
         → x ≢ y × y ∉ xs
 y∉xs⇒Allxs≢y {_} {xs} {x} {y} y∉
   with y ∈? xs
 ...| yes y∈xs = ⊥-elim (y∉ (there y∈xs))
 ...| no  y∉xs
   with x ≟Fin y
 ...| yes x≡y = ⊥-elim (y∉ (here (sym x≡y)))
 ...| no  x≢y = x≢y , y∉xs


 insertSort : ∀ {n} → Fin n → List (Fin n) → List (Fin n)
 insertSort x [] = x ∷ []
 insertSort x (h ∷ t)
   with x ≤?Fin h
 ...| yes x≤h = x ∷ h ∷ t
 ...| no  x>h = h ∷ insertSort x t


 sort : ∀ {n} → List (Fin n) → List (Fin n)
 sort [] = []
 sort (x ∷ xs) = insertSort x (sort xs)


 allDistinctTail : ∀ {A} {x : A} {xs : List A}
                 → allDistinct (x ∷ xs)
                 → allDistinct xs
 allDistinctTail {_} {x} {xs} allDist (i , i<l) (j , j<l)
   with allDist ((suc i) , (s≤s i<l)) ((suc j) , s≤s j<l)
 ...| inj₁ 1+i≡1+j = inj₁ (cong pred 1+i≡1+j)
 ...| inj₂ lookup≢ = inj₂ lookup≢


 onHeadInsSort : ∀ {n} {x x₁} {xs : List (Fin n)}
               → IsSorted _<Fin_ (x₁ ∷ xs)
               → x₁ <Fin x → x ∉ xs
               → OnHead _<Fin_ x₁ (insertSort x xs)
 onHeadInsSort {xs = []} (x₂< ∷ []) x₁<x x∉xs = on-∷ x₁<x
 onHeadInsSort {x = x} {xs = x₂ ∷ xs} (on-∷ x₁<x₂ ∷ sxs) x₁<x x∉xs
    with x ≤?Fin x₂
 ...| yes x≤x₂ = on-∷ x₁<x
 ...| no  x≰x₂ = on-∷ x₁<x₂


 xs-⊆List-ysʳ : ∀ {A : Set} {x} {xs ys : List A}
              → (x ∷ xs) ⊆List ys
              → xs ⊆List ys
 xs-⊆List-ysʳ xxs⊆ys x∈xs = xxs⊆ys (there x∈xs)


 ∈-Any-Index-elim :  ∀ {A : Set} {x y} {ys : List A} (x∈ys : x ∈ ys)
                  → x ≢ y → y ∈ ys
                  → y ∈ ys ─ Any-index x∈ys
 ∈-Any-Index-elim (here refl)  x≢y (here refl)  = ⊥-elim (x≢y refl)
 ∈-Any-Index-elim (here refl)  x≢y (there y∈ys) = y∈ys
 ∈-Any-Index-elim (there x∈ys) x≢y (here refl)  = here refl
 ∈-Any-Index-elim (there x∈ys) x≢y (there y∈ys) = there (∈-Any-Index-elim x∈ys x≢y y∈ys)


 ⊆List-Elim :  ∀ {n} {x} {xs ys : List (Fin n)} (x∈ys : x ∈ ys)
                    → x ∉ xs → xs ⊆List ys
                    → xs ⊆List ys ─ Any-index x∈ys
 ⊆List-Elim {_} {x} {x₁ ∷ xs} {y ∷ ys} (here refl) x∉xs xs∈ys x₂∈xs
   with xs∈ys x₂∈xs
 ... | here refl  = ⊥-elim (x∉xs x₂∈xs)
 ... | there x∈xs = x∈xs
 ⊆List-Elim {_} {x} {x₁ ∷ xs} {y ∷ ys} (there x∈ys) x∉xs xs∈ys x₂∈xxs
   with x₂∈xxs
 ... | there x₂∈xs
       = ⊆List-Elim (there x∈ys) (proj₂ (y∉xs⇒Allxs≢y x∉xs)) (xs-⊆List-ysʳ xs∈ys) x₂∈xs
 ... | here refl
   with xs∈ys x₂∈xxs
 ... | here refl = here refl
 ... | there x₂∈ys
       = there (∈-Any-Index-elim x∈ys (≢-sym (proj₁ (y∉xs⇒Allxs≢y x∉xs))) x₂∈ys)


 insSort-⊆ : ∀ {n} {x} (xs ys : List (Fin n))
           → xs ⊆List ys
           → insertSort x xs ⊆List (x ∷ ys)
 insSort-⊆ [] _ _ (here refl) = here refl
 insSort-⊆ {x = x} (x₁ ∷ xs) ys xs⊆ys x∈is
    with x ≤?Fin x₁  | x∈is
 ... | yes x≤x₂      | here refl   = here refl
 ... | yes x≤x₂      | there x∈xs  = there (xs⊆ys x∈xs)
 ... | no x≰x₂       | here refl   = there (xs⊆ys (here refl))
 ... | no x≰x₂       | there x₂∈is = insSort-⊆ xs ys (λ x∈ → xs⊆ys (there x∈)) x₂∈is


 sort-⊆ : ∀ {n} (xs : List (Fin n))
        → sort xs ⊆List xs
 sort-⊆ (x₁ ∷ xs) x = insSort-⊆ (sort xs) xs (sort-⊆ xs) x


 sumInsertSort≡ : ∀ {n} (x : Fin n) (xs : List (Fin n)) (f : Fin n → ℕ)
                → sum (List-map f (insertSort x xs)) ≡ f x + sum (List-map f xs)
 sumInsertSort≡ x [] f = refl
 sumInsertSort≡ x (x₁ ∷ xs) f
    with x ≤?Fin x₁
 ...| yes x≤x₂ = refl
 ...| no  x≰x₂ rewrite sumInsertSort≡ x xs f
                      | sym (+-assoc (f x) (f x₁) (sum (List-map f xs)))
                      | +-comm (f x) (f x₁)
                      | +-assoc (f x₁) (f x) (sum (List-map f xs)) = refl


 sumSort≡ : ∀ {n} (xs : List (Fin n)) (f : Fin n → ℕ)
          → sum (List-map f xs) ≡ sum (List-map f (sort xs))
 sumSort≡ [] f = refl
 sumSort≡ (x ∷ xs) f rewrite sumInsertSort≡ x (sort xs) f
   = cong (f x +_) (sumSort≡ xs f)


 ∉∧⊆List⇒∉ : ∀ {n} {x} {xs ys : List (Fin n)}
             → x ∉ xs → ys ⊆List xs
             → x ∉ ys
 ∉∧⊆List⇒∉ x∉xs ys∈xs x∈ys = ⊥-elim (x∉xs (ys∈xs x∈ys))


 allDistinctʳʳ : ∀ {A} {x x₁ : A} {xs : List A}
                 → allDistinct (x ∷ x₁ ∷ xs)
                 → allDistinct (x ∷ xs)
 allDistinctʳʳ allDist (zero , i<l) (zero , j<l) = inj₁ refl
 allDistinctʳʳ {_} {x} {x₁} {xs} allDist (zero , i<l) (suc j , j<l)
   with allDist (0 , s≤s z≤n) (suc (suc j) , s≤s j<l)
 ...| inj₂ x≢lookup
      = inj₂ λ x≡lkpxs → ⊥-elim (x≢lookup x≡lkpxs)
 allDistinctʳʳ {_} {x} {_} {xs} allDist (suc i , i<l) (zero , j<l)
   with allDist (suc (suc i) , s≤s i<l) (0 , s≤s z≤n)
 ...| inj₂ x≢lookup
      = inj₂ λ x≡lkpxs → ⊥-elim (x≢lookup x≡lkpxs)
 allDistinctʳʳ allDist (suc i , i<l) (suc j , j<l)
   with allDist (2 + i , (s≤s i<l)) (2 + j , s≤s j<l)
 ...| inj₁ si≡sj   = inj₁ (cong pred si≡sj)
 ...| inj₂ lookup≡ = inj₂ lookup≡


 allDistinct⇒∉ : ∀ {n} {x} {xs : List (Fin n)}
               → allDistinct (x ∷ xs)
               → x ∉ xs
 allDistinct⇒∉ allDist (here x≡x₁)
   with allDist (0 , s≤s z≤n) (1 , s≤s (s≤s z≤n))
 ... | inj₂ x≢x₁ = ⊥-elim (x≢x₁ x≡x₁)
 allDistinct⇒∉ allDist (there x∈xs)
   = allDistinct⇒∉ (allDistinctʳʳ allDist) x∈xs


 sumListMap : ∀ {A : Set} {x} {xs : List A} (f : A → ℕ) → (x∈xs : x ∈ xs)
            → sum (List-map f xs) ≡ f x + sum (List-map f (xs ─ Any-index x∈xs))
 sumListMap f (here refl)  = refl
 sumListMap {_} {x} {x₁ ∷ xs} f (there x∈xs)
   rewrite sumListMap f x∈xs
         | sym (+-assoc (f x) (f x₁) (sum (List-map f (xs ─ Any-index x∈xs))))
         | +-comm (f x) (f x₁)
         | +-assoc (f x₁) (f x) (sum (List-map f (xs ─ Any-index x∈xs))) = refl


 sum-⊆-≤ : ∀ {n} {ys} (xs : List (Fin n)) (f : (Fin n) → ℕ)
         → allDistinct xs
         → xs ⊆List ys
         → sum (List-map f xs) ≤ sum (List-map f ys)
 sum-⊆-≤ [] f dxs xs⊆ys = z≤n
 sum-⊆-≤ (x ∷ xs) f dxs xs⊆ys
    rewrite sumListMap f (xs⊆ys (here refl))
    = let x∉xs    = allDistinct⇒∉ dxs
          xs⊆ysT  = xs-⊆List-ysʳ xs⊆ys
          xs⊆ys-x = ⊆List-Elim (xs⊆ys (here refl)) x∉xs xs⊆ysT
          disTail = allDistinctTail dxs
     in +-monoʳ-≤ (f x) (sum-⊆-≤ xs f disTail xs⊆ys-x)


 lookup⇒Any : ∀ {A : Set} {xs : List A} {P : A → Set} (i : Fin (length xs))
            → P (List-lookup xs i) → Any P xs
 lookup⇒Any {xs = x₁ ∷ xs} zero px = here px
 lookup⇒Any {xs = x₁ ∷ xs} (suc i) px = there (lookup⇒Any i px)


 x∉→AllDistinct : ∀ {n} {x} {xs : List (Fin n)}
                → allDistinct xs
                → x ∉ xs
                → allDistinct (x ∷ xs)
 x∉→AllDistinct {xs = []} allDist x∉xs (0 , s≤s z≤n) (0 , s≤s z≤n) = inj₁ refl
 x∉→AllDistinct {_} {x} {x₁ ∷ xs} allDist x∉xs (zero , i<l) (zero , j<l) = inj₁ refl
 x∉→AllDistinct {_} {x} {x₁ ∷ xs} allDist x∉xs (zero , i<l) (suc j , j<l)
   = inj₂ (λ x≡lkp → x∉xs (lookup⇒Any (fromℕ< (≤-pred j<l)) x≡lkp))
 x∉→AllDistinct {_} {x} {x₁ ∷ xs} allDist x∉xs (suc i , i<l) (zero , j<l)
   = inj₂ (λ x≡lkp → x∉xs (lookup⇒Any (fromℕ< (≤-pred i<l)) (sym x≡lkp)))
 x∉→AllDistinct {_} {x} {x₁ ∷ xs} allDist x∉xs (suc i , i<l) (suc j , j<l)
   with allDist (i , (≤-pred i<l)) (j , (≤-pred j<l))
 ... | inj₁ i≡j   = inj₁ (cong suc i≡j)
 ... | inj₂ lkup≢ = inj₂ lkup≢


 inSort⇒Sort : ∀ {n} {x} {xs : List (Fin n)} → x ∉ xs
             → IsSorted _<Fin_ xs
             → IsSorted _<Fin_ (insertSort x xs)
 inSort⇒Sort {_} {_} {[]} _ _ = [] ∷ []
 inSort⇒Sort {_} {x} {x₁ ∷ xs} x∉xs (x₁< ∷ sxs)
   with x ≤?Fin x₁
 ...| yes x≤x₁
   = let nx≢nx₁ = ≢-sym (proj₁ (y∉xs⇒Allxs≢y x∉xs))
         x≢x₁   = contraposition toℕ-injective nx≢nx₁
     in on-∷ (≤∧≢⇒< x≤x₁ x≢x₁) ∷ x₁< ∷ sxs
 ...| no  x≰x₁
   = let x∉xxs = proj₂ (y∉xs⇒Allxs≢y x∉xs)
     in onHeadInsSort (x₁< ∷ sxs) (≰⇒> x≰x₁) x∉xxs ∷ (inSort⇒Sort x∉xxs sxs)


 allDistict⇒Sorted : ∀ {n} → (xs : List (Fin n)) → allDistinct xs
                    → IsSorted _<Fin_ (sort xs)
 allDistict⇒Sorted [] _ = []
 allDistict⇒Sorted (x ∷ xs) allDist
   = let distTail = allDistinctTail allDist
         sortTail = allDistict⇒Sorted xs distTail
         x∉xs     = allDistinct⇒∉ allDist
     in inSort⇒Sort (∉∧⊆List⇒∉ x∉xs (sort-⊆ xs)) sortTail


 sorted⇒AllDistinct : ∀ {n} {xs : List (Fin n)}
                    → IsSorted _<Fin_ xs
                    → allDistinct xs
 sorted⇒AllDistinct (x< ∷ sxs) (i , i<l) (j , j<l)
   = let x∉xs  = h∉t <⇒≢Fin <-trans (x< ∷ sxs)
         sTail = sorted⇒AllDistinct sxs
     in x∉→AllDistinct sTail x∉xs (i , i<l) (j , j<l)
