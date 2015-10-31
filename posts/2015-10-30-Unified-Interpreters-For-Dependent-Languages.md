---
title: Unified Interpreters For Dependent Languages
---

I've spent the past couple months playing around with [all sorts of ways](https://github.com/GallagherCommaJack/tt-provability) to represent type theory in type theory.
Doing so has led me down a lot of rabbit holes, and in this post I hope to explain some of the more fun ones.

# Induction Recursion
Induction recursion has become one of the most powerful tools in my type theoretic utility belt.
One classic example of induction recursion is defining [a universe of types](http://ncatlab.org/homotopytypetheory/show/universe) within another universe inductively (which we can then eliminate over).
The construction is simple enough - we just define an inductive family of codes at the same time as the decoding function.

```Agda
data U : Set
⟦_⟧ᵤ : U → Set

data U where
  π  σ    : (A : U) → (⟦ A ⟧ᵤ → U) → U -- Π, Σ
  n₀ n₁ n₂ : U -- ⊥,⊤

⟦ π a b ⟧ᵤ = (a↓ : ⟦ a ⟧ᵤ) → ⟦ b a↓ ⟧ᵤ
⟦ σ a b ⟧ᵤ = Σ ⟦ a ⟧ᵤ (λ a↓ → ⟦ b a↓ ⟧ᵤ)
⟦ n₀ ⟧ᵤ = ⊥
⟦ n₁ ⟧ᵤ = ⊤
⟦ n₂ ⟧ᵤ = Bool
```

We can actually go a little farther, and define next universes for every universe in type theory.

```Agda
data NextU (U' : Set) (⟦_⟧ᵤ' : U' → Set) : Set
⟦_⟧ₙ : ∀ {U' ⟦_⟧ᵤ'} → NextU U' ⟦_⟧ᵤ' → Set

data NextU U' ⟦_⟧ᵤ' where
  uu : NextU U' ⟦_⟧ᵤ'
  up : U' → NextU U' ⟦_⟧ᵤ'
  πu σu : (A : NextU U' ⟦_⟧ᵤ') → (⟦ A ⟧ₙ → NextU U' ⟦_⟧ᵤ') → nextU U' ⟦_⟧ᵤ' -- Π, Σ

⟦_⟧ₙ {U'} uu = U'
⟦_⟧ₙ {U'} {⟦_⟧ᵤ'} (up u) = ⟦ u ⟧ᵤ'
⟦ πu a b ⟧ₙ = (a↓ : ⟦ a ⟧ₙ) → ⟦ b a↓ ⟧ₙ
⟦ σu a b ⟧ₙ = Σ ⟦ a ⟧ₙ (λ a↓ → ⟦ b a↓ ⟧ₙ)
```

You can even define Mahlo universes in ``Set`` this way, but I haven't actually found much use for that.

# Representing languages

Using induction induction, it's fairly easy to define a dependently typed language.
We'll use a typed variant on DeBrujin indices to represent variable binding.

```Agda
data Con : Set
data Ty : Con → Set
data _∋_ : ∀ Γ → Ty Γ → Set
data _⊢_ (Γ : Con) : Ty Γ → Set

data Con where
  ε : Con
  _,_ : ∀ Γ → Ty Γ → Con

data Ty where
  π : ∀ {Γ} (A : Ty Γ) → Ty (Γ , A) → Ty Γ
  ‘⊤’ ‘⊥’ : ∀ {Γ} → Ty Γ
  W : ∀ {Γ A} → Ty Γ → Ty (Γ , A) -- weakening
  _⍟_ : ∀ {Γ A} (B : Ty (Γ , A)) → Γ ⊢ A → Ty Γ -- application at type level

data _∋_ where
  top : ∀ {Γ A} → (Γ , A) ∋ W A
  pop : ∀ {Γ A B} → Γ ∋ A → (Γ , B) ∋ W A

data _⊢_ where
  var : ∀ {Γ A} → Γ ∋ A → Γ ⊢ A
  lam : ∀ {Γ} A (B : Ty (Γ , A)) → (Γ , A) ⊢ B → Γ ⊢ π A B
  _⊛_ : A B} → Γ ⊢ π A B → (a : Γ ⊢ A) → Γ ⊢ B ⍟ a
  tt : ∀ {Γ} → Γ ⊢ ‘⊤’ -- ‘⊤’ is terminal
  exf : ∀ {Γ A} → Γ ⊢ ‘⊥’ → Γ ⊢ A -- ‘⊥’ is initial
```

We could then define an interpreter for this langauge in three parts - one function to interpret contexts, one for types, and one for terms.

```Agda
Con↓ : Con → Set -- Denotation of a context should be a list of typed holes to fill in an expression - think of this as the map we'll look up variables in
Ty↓ : ∀ {Γ} → Ty Γ → Con↓ Γ → Set -- Denotation of a type should be, well, a type, but should only be accessible if we can fill in all the holes
Tm↓ : ∀ {Γ T} → Γ ⊢ T → (Γ↓ : Con↓ Γ) → Ty↓ T Γ↓ -- Denotation of a term should be an inhabitant of its type, but again can only be created if we can give the variable lookup

Con↓ ε = ⊤ -- empty context is trivial
Con↓ (Γ , T) = Σ[ Γ↓ ∈ Con↓ Γ ] Ty↓ T Γ↓

Ty↓ (π A B) Γ↓ = (a↓ : Ty↓ A Γ↓) → Ty↓ B (Γ↓ , A)
Ty↓ ‘⊤’ Γ↓ = ⊤
Ty↓ ‘⊥’ Γ↓ = ⊥
Ty↓ (W X) (Γ↓ , T) = Ty↓ X Γ↓
Ty↓ (B ⍟ a) Γ↓ = Ty↓ B (Γ↓ , Tm↓ a Γ↓)

Tm↓ (lam A b) Γ↓ = λ (a : Ty↓ A Γ↓) → Tm↓ b (Γ↓ , a)
Tm↓ (f ⊛ x) Γ↓ = Tm↓ f Γ↓ (Tm↓ x Γ↓)
Tm↓ tt = tt
Tm↓ (exf contra) Γ↓ = ⊥-rec (Tm↓ contra Γ↓)
Tm↓ (var v) Γ↓ = var↓ v Γ↓ -- variable lookup will be defined as an auxiliary function
  where var↓ : ∀ {Γ T} → Γ ∋ T → (Γ↓ : Con↓ Γ) → Ty↓ T Γ↓
        var↓ top (Γ↓ , a) = a
        var↓ (pop v) (Γ↓ , b) = var↓ v Γ↓
```

This language is far from ideal for lots of reasons, but it serves to illustrate the basic concept.
We can define a well typed syntax for dependent type theory fairly easily using induction induction, and the interpreter is a natural outgrowth of the language structure.

But I've been playing around lately with languages that have access to their own interpreter, and three different interpretation functions across three different type families sounds like an awful lot of stuff.
Luckily, like every other time I have a problem, Conor McBride's figured out a trick using induction recursion that gets me at least part of the way there.

First, the language representation:

```Agda
data Label : Set where
  con ty tm : Label

I : Label → Set
data D : (ℓ : Label) → I ℓ → Set

I con = ⊤
I ty = D con _
I tm = Σ[ Γ ∈ D con _ ] D ty Γ

Con : Set
Con = D con _
Ty : Con → Set
Ty = D ty
_⊢_ : ∀ Γ → Ty Γ → Set
Γ ⊢ T = D tm (Γ , T)

data D where
  -- Contexts
  ε : Con -- D con _
  _,_ : ∀ Γ → Ty Γ → Con -- (Γ : D con _) → D ty Γ → D con _
  -- Types
  π : ∀ {Γ} (A : Ty Γ) → Ty (Γ , A) → Ty Γ
  ‘⊤’ ‘⊥’ : ∀ {Γ} → Ty Γ
  W : ∀ {Γ A} → Ty Γ → Ty (Γ , A) -- weakening
  _⍟_ : ∀ {Γ A} (B : Ty (Γ , A)) → Γ ⊢ A → Ty Γ -- application at type level
  -- Terms
  top : ∀ {Γ A} → (Γ , A) ⊢ W A
  pop : ∀ {Γ A B} → Γ ⊢ A → (Γ , B) ⊢ W A
  lam : ∀ {Γ} A (B : Ty (Γ , A)) → (Γ , A) ⊢ B → Γ ⊢ π A B
  _⊛_ : A B} → Γ ⊢ π A B → (a : Γ ⊢ A) → Γ ⊢ B ⍟ a
  tt : ∀ {Γ} → Γ ⊢ ‘⊤’ -- ‘⊤’ is terminal
  exf : ∀ {Γ A} → Γ ⊢ ‘⊥’ → Γ ⊢ A -- ‘⊥’ is initial
```

The interpreter itself will look an awful lot like the one we defined above, but with an added auxiliary function to specify the output type.

```Agda
U₁ : Set
U₁ = NextU U ⟦_⟧ᵤ

⟦_⟧₁ : U₁ → Set
⟦_⟧₁ = ⟦_⟧ₙ

I↓ : ∀ ℓ → I ℓ → U₁
⟦_⟧ : ∀ {ℓ i} → D ℓ i → ⟦ I↓ ℓ i ⟧₁

I↓ con _ = uu
I↓ ty Γ = πu (up ⟦ Γ ⟧) (λ Γ↓ → uu)
I↓ tm (Γ , T) = up (π ⟦ Γ ⟧ ⟦ T ⟧)

⟦ ε ⟧ = ⊤
⟦ Γ , T ⟧ = Σ ⟦ Γ ⟧ ⟦ T ⟧
⟦ ... ⟧ = ... -- the rest of the function proceeds exactly as before
```

So, to review, using induction recursion we managed to specify an entire language, including contexts, types, and terms, as one giant inductive-recursive family, and write an interpreter for all three at once.
I managed to use this alongside the trick for encoding very dependent types in Agda to write a language that parametrizes over its own interpreters, but didn't actually find much use for it.
Right now I'm looking at porting this trick to the Outrageous Coincidences representation to see if I can get around some of the issues I had that way, but I'm not particularly optimistic.
My main enemy right now is the positivity restriction, which keeps me from doing quite as much with quotation as I'd like, as well as the standard issues about well typed dependent syntaxes.

Next post will either be another exploratory piece like this one or (if I manage to finish it) the post about introductions to type theory I promised last time.
