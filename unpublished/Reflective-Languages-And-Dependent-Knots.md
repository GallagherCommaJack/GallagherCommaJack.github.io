---
title: Reflective Languages and Dependent Knots: Progress and Problems
---

Preface
-------
This post is a little denser and less polished than most of my content.
It's more of a brain dump that hopefully will help some people understand what I've been up to lately.


I've been spending a lot of time lately thinking about provability logic, and in particular how to go about working with it in dependent type theory.
It seems like there ought to be a lot to gain going down this route - type theoretic formalization tends to highlight previously unknown computational meanings of proofs, in addition to making truly fully formal proofs much easier.

Attempting to recreate provability logic has led me down several different sorts of rabbit holes, most of which I've ended up cataloging in [this Github repo](https://github.com/GallagherCommaJack/tt-provability).
One of the tricks I've gotten a lot of mileage out of lately has been defining a logic at the same time as its interpretation function.
This approach has been heavily inspired by what I consider to be [Conor McBride's most interesting paper](https://personal.cis.strath.ac.uk/conor.mcbride/pub/DepRep/DepRep.pdf).

While the implementation isn't quite there yet, I suspect it's sufficiently novel to be worth investigating further.

Before I delve too far into the structures I'm playing with, I ought to give some background.

Induction {Induction ; Recursion}: Mutuality and More
-----------------------------------------------------
Suppose you wanted to define a closed (Tarski) universe within one of the universe of dependent type theory.
You'd probably want to do something like this:

``agda
data U : Set₁ where
    ⊤ ⊥ : U
    π : (A : Set) ((a : A) → U) → U

U↓ : U → Set
U↓ ⊤ = ⊤
U↓ ⊥ = ⊥
U↓ (π A B) = (a : A) → U↓ (B a)
``

You might have noticed that this universe is not actually closed.
In particular, ``U`` lives in Set₁, and thus cannot supply its own elements to ``π``.
So it's not closed after all!
In fact, it can't even use its own types.

We can get around this by defining ``U`` at the same time as its denotation function:

``agda
data U : Set where
    ⊤ ⊥ : U
    π : (A : U) ((a : U↓) → U) → U

U↓ ⊤ = ⊤
U↓ ⊥ = ⊥
U↓ (π A B) = (a : U↓ A) → U↓ (B a)
``

If this seems extremely powerful, that's because it is.
At OPLSS this year, Peter Dybjer used this style to define [Mahlo universes in Set₀](http://www.cse.chalmers.se/~peterd/agda/IR/HigherInfinite.agda).

Another useful extension (which would be strictly more powerful if it weren't for predicativity) is induction induction.
Most of the examples I've seen of induction induction are fairly relevant to what I've been doing, so I'll just jump right into defining dependently typed syntax.

``agda
data Con : Set
    ε : Con
    _,_ : ∀ Γ → Ty Γ → Con

data Ty : Con → Set where
    π : ∀ {Γ} → (A : Ty Γ) → Ty (Γ , A) → Ty Γ
    _‘’_ : ∀ {Γ A} → Ty (Γ , A) → Tm Γ A → Ty Γ -- substitution
    W₀ : ∀ {Γ A} → Ty Γ → Ty (Γ , A) -- weakening
    ⋆ : ∀ {Γ} → Ty Γ

data Tm : ∀ Γ → Ty Γ → Set
    λ_→_ : ∀ {Γ} (A : Ty Γ) {B : Ty (Γ , A)} → Tm (Γ , A) B → Tm Γ (π A B)
    _⊛_ : ∀ {Γ A B} → Tm Γ (π A B) → (a : Tm Γ A) → Tm Γ (B ‘’ a)
    v₀ : ∀ {Γ A} → Tm (Γ , A) (W₀ A)
    w₀ : ∀ {Γ A B} → Tm Γ A → Tm (Γ , B) (W₀ A)
``

Notice that ``Con``'s are defined effectively as nested sigmas of ``Ty``'s, which are indexed over contexts and can depend on ``Tm``'s, which are indexed over both ``Con``'s and ``Ty``'s.
This definition turns out to be insufficient for lots of things (try applying a weakened function).

I've been making fairly heavy use of both of these constructs.
In general, when you want to only write well (dependently) typed terms, you'll need one or both.

Trees and Synthetic Approaches
------------------------------
Do we really need all this inductive-inductive-recursive machinery?
It certainly feels like a rather heavy toolset to pick up for what ought to be fairly simple structural operations.
In this section, I hope to show why such an approach is necessary for a satisfying solution.

First, let's define an untyped syntax.
I'll adopt the convention of only using ascii characters for untyped terms.

``agda
data Ptm : Set where
  typ : ℕ → Ptm -- typ n is Setₙ
  bot : Ptm
  exf : Ptm → Ptm
  top : Ptm
  unt : Ptm
  pi  : Ptm → Ptm → Ptm
  lam : Ptm → Ptm → Ptm
  _$_ : Ptm → Ptm → Ptm
  sig : Ptm → Ptm → Ptm
  smk : Ptm → Ptm → Ptm
  pi1 : Ptm → Ptm
  pi2 : Ptm → Ptm
  tree : Ptm -- tree
  leaf : Ptm -- leaf
  _<+>_ : Ptm → Ptm → Ptm -- branch
  ind : (P lc bc : Ptm) → Ptm
  *_  : ℕ → Ptm -- var
``
We can then define lifting and substitution at arbitrary depths, but rather than doing it here I'll simply point you to a file where [I did just that](https://github.com/GallagherCommaJack/tt-provability/blob/master/Syntax/Untyped/Def.agda).
And of course, [a typing relation](https://github.com/GallagherCommaJack/tt-provability/blob/master/Syntax/Untyped/Typing.agda) tends to be useful to have.
It seems like it ought to be possible to define the syntax for this system inside itself via predicates on trees, but in my mind this isn't importantly better than Gödel numbering.
It's still a step up (the "is this a term" predicate is a bit simpler), but I think we can do better.

Instead, we could try defining a well typed syntax that has some built in quotation function.
Doing this in the right way can be somewhat tricky. An attempt at a simply typed reflective syntax (copied from [here](https://github.com/GallagherCommaJack/tt-provability/blob/master/Syntax/Typed/Reflective.agda)) follows below.

``agda
data Con : Set
data Ty : Set
data _∋_ : Con → Ty → Set
data _⊢_ (Γ : Con) : Ty → Set
⟦_⟧c : Con → Set
⟦_⟧t : Ty → Set
Tm↓ : ∀ {Γ T} → Γ ⊢ T → ⟦ Γ ⟧c → ⟦ T ⟧t

data Con where
  ε : Con
  _,_ : Con → Ty → Con

data Ty where
  ⋆ : Ty
  _⟶_ : Ty → Ty → Ty
  con ty : Ty
  tm : ∀ {Γ} → Γ ⊢ con → Γ ⊢ ty → Ty

⟦ ε ⟧c = ⊤
⟦ Γ , x ⟧c = ⟦ Γ ⟧c × ⟦ x ⟧t
⟦ ⋆ ⟧t = ⊤
⟦ T₁ ⟶ T₂ ⟧t = ⟦ T₁ ⟧t → ⟦ T₂ ⟧t
⟦ con ⟧t = Con
⟦ ty ⟧t = Ty
⟦ tm {Γ} Δ T ⟧t = (Γ↓ : ⟦ Γ ⟧c) → Tm↓ Δ Γ↓ ⊢ Tm↓ T Γ↓

data _∋_ where
  vz : ∀ {Γ A} → (Γ , A) ∋ A
  vs : ∀ {Γ A B} → Γ ∋ A → (Γ , B) ∋ A

data _⊢_ Γ where
  var : ∀ {A} → Γ ∋ A → Γ ⊢ A
  _↦_ : ∀ A {B} → (Γ , A) ⊢ B → Γ ⊢ (A ⟶ B) -- lam
  _⊛_ : ∀ {A B} → Γ ⊢ (A ⟶ B) → Γ ⊢ A → Γ ⊢ B
  q-con : Con → Γ ⊢ con
  q-ty : Ty → Γ ⊢ ty
  q-tm : ∀ {Δ T} → ⟦ tm {Γ} Δ T ⟧t → Γ ⊢ tm Δ T

Tm↓ (var vz) (Γ↓ , a) = a
Tm↓ (var (vs x)) (Γ↓ , a) = Tm↓ (var x) Γ↓
Tm↓ (A ↦ b) Γ↓ = λ a → Tm↓ b (Γ↓ , a)
Tm↓ (f ⊛ x) Γ↓ = Tm↓ f Γ↓ (Tm↓ x Γ↓)
Tm↓ (q-con x) Γ↓ = x
Tm↓ (q-ty x) Γ↓ = x
Tm↓ (q-tm x) Γ↓ = x
``

This definition, sadly, runs afoul of the positivity checker. I'm not really sure how to get around this.
Interestingly enough, a dependent analog to this syntax wouldn't break positivity, but I don't yet know how to give it any content *other* than qouted terms.
