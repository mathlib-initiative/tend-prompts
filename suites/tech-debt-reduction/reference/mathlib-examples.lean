/-
  Mathlib-only companion to "Reviewing & Managing Technical Debt — A Portable Playbook".

  Every Lean mechanism the playbook cites is reproduced here against **Mathlib only** —
  no CFT_clean / project dependency — so any reader can run it. If this file compiles
  (exit 0), every POSITIVE claim below holds on the compiler. Each NEGATIVE contrast
  ("… fails") is shown in a comment with the *exact* error observed, so a reader can
  paste it back in and watch it fail.

  Verified on: leanprover/lean4:v4.35.0-rc3, Mathlib commit 8de4fb72 (2026-09-26).
  Compile:     lake env lean PlaybookExamples.lean
               (run from any project whose LEAN_PATH includes a built Mathlib)

  These are minimal mechanism demonstrations. The playbook's *measurements* and
  *incidents* (e.g. "56 of 121 removable", the 7,300-line comment cascade, 101→97)
  are source-project campaign evidence and are NOT reproducible from Mathlib by
  construction — they are labelled as such in the playbook and do not appear here.
-/
import Mathlib.Tactic
import Mathlib.CategoryTheory.EqToHom
import Mathlib.Tactic.CategoryTheory.Reassoc

open CategoryTheory

/-! ## §6.3 — a "tidy" collapse is semantic: sequential `rw` vs idempotent `simp only`

With `h : f a = a`, the goal `f (f a) = a` has exactly ONE literal occurrence of the
pattern `f a` (the inner application). So one rewrite is not enough for `rw`, but
`simp only` rewrites to a fixpoint and one copy of `h` already suffices. -/
namespace Playbook.DedupeCollapse

-- `rw [h, h]` is load-bearing: the duplicate is a SECOND rewrite, not noise.
example {α : Type*} (f : α → α) (a : α) (h : f a = a) : f (f a) = a := by
  rw [h, h]

-- Collapsing it to `rw [h]` BREAKS the proof:
--   example ... := by rw [h]
--   ⊢ unsolved goals  ⊢ f a = a       (one rewrite happened; a second was needed)

-- `simp only` is idempotent (rewrites to a fixpoint): one copy already closes it,
-- and the duplicate is inert — collapsing `[h, h] → [h]` is SAFE.
example {α : Type*} (f : α → α) (a : α) (h : f a = a) : f (f a) = a := by
  simp only [h]

-- Lean's own `linter.unusedSimpArgs` agrees: on `simp only [h, h]` it flags the
-- duplicate as unused and literally suggests `simp only [h]` — the toolchain
-- endorsing the exact collapse that is safe for the set but breaks the sequence.
-- (We silence the linter here only to keep this file's output clean.)
set_option linter.unusedSimpArgs false in
example {α : Type*} (f : α → α) (a : α) (h : f a = a) : f (f a) = a := by
  simp only [h, h]

end Playbook.DedupeCollapse

/-! ## §1.6 / §5.5 — `erw` succeeds where `rw` fails, and is not freely demotable

`rw` matches a pattern's arguments at REDUCIBLE transparency; `erw` at DEFAULT.
When the head matches but an argument differs by an ordinary (semireducible) `def`
unfolding, `rw` cannot find the pattern and `erw` can. That extra unfolding is the
debt `erw` silences — and it is load-bearing: you cannot demote to a bare `rw`. -/
namespace Playbook.ErwVsRw

def myId (n : Nat) : Nat := n

-- `erw` unfolds `myId a → a` at default transparency, finds `f a`, closes the goal.
example (a : Nat) (f : Nat → Nat) (h : f a = 0) : f (myId a) = 0 := by
  erw [h]

-- Plain `rw` FAILS on the identical goal:
--   example ... := by rw [h]
--   error: Tactic `rewrite` failed: Did not find an occurrence of the pattern
--     f a
--   in the target expression
--     f (myId a) = 0

-- Demotion to `rw` is possible only by making the unfolding EXPLICIT — i.e. adding
-- a step, which is precisely "the debt moved", not "the debt was free":
example (a : Nat) (f : Nat → Nat) (h : f a = 0) : f (myId a) = 0 := by
  unfold myId; rw [h]

end Playbook.ErwVsRw

/-! ## §5.5 — the strict `erw`-vs-`rw` discriminator (keep the debt when it fires)

The absorber test for a demoted rewrite: run strict `erw` and strict `rw` on the
same goal. If `erw` passes and `rw` FAILS, the extra unfolding is load-bearing —
keep the `erw`. `rw` fails hard at the pattern-match step, so there is no rfl
fallback to confound the test. -/
namespace Playbook.ErwDiscriminator

def g (n : Nat) : Nat := n

-- strict `erw` passes …
example (P : Nat → Nat) (a c : Nat) (key : P (g a) = c) : P a = c := by
  erw [key]

-- … while strict `rw` FAILS on the same goal ⇒ unfolding is load-bearing, keep it:
--   example ... := by rw [key]
--   error: Tactic `rewrite` failed: Did not find an occurrence of the pattern
--     P (g a)  in the target expression  P a = c

end Playbook.ErwDiscriminator

/-! ## §1.7 / §5.5 — the ABSORBER TEST: a green build after deletion ≠ removal

The central principle. A workaround that still compiles after you delete it is not
necessarily removed — its work may be absorbed by a later step. Here the genuine
defeq gap is a semireducible `def F n := n`: `F a` is defeq to `a` at DEFAULT
transparency but NOT at REDUCIBLE. -/
namespace Playbook.Absorber

def F (n : Nat) : Nat := n

-- VERSION A — the "workaround" present: an explicit bridge (`change` unfolds F).
example (a : Nat) : F a = a := by
  change a = a
  rfl

-- VERSION B — delete the bridge: STILL COMPILES GREEN. A naive "does it still
-- build?" test would call the bridge removable debt. It is not: `rfl` unifies at
-- default transparency and silently absorbs the very unfolding the bridge did.
example (a : Nat) : F a = a := by
  rfl

-- WITNESS that the work is real and merely MOVED. A reducible-only closer exposes
-- the gap: with the bridge, it still closes (the bridge did the unfolding) …
example (a : Nat) : F a = a := by
  change a = a
  with_reducible rfl

-- … but WITHOUT the bridge, the reducible-only closer FAILS — proving the unfolding
-- was load-bearing and VERSION B only passed because `rfl` absorbed it:
--   example (a : Nat) : F a = a := by with_reducible rfl
--   error: Tactic `rfl` failed: The left-hand side
--     F a
--   is not definitionally equal to the right-hand side
--     a

-- Option availability for a Mathlib-only reader: both of these are recognised
-- (a bad option name in the same namespace errors with "Unknown option …"), so
-- the playbook's `set_option` workarounds are reproducible here.
set_option backward.isDefEq.respectTransparency false in
theorem opt_respectTransparency : 1 + 1 = 2 := by rfl

set_option maxHeartbeats 400000 in
theorem opt_maxHeartbeats : 2 + 2 = 4 := by rfl

-- HONEST SCOPE NOTE: `backward.isDefEq.respectTransparency false` is NOT itself an
-- "ignore transparency" knob — on `F a = a` with it set false, `with_reducible rfl`
-- STILL fails. It governs a narrower backward-compat defeq behaviour. The absorber
-- demo above is driven by `with_reducible` vs default transparency, not by this flag.

end Playbook.Absorber

/-! ## §7.2 — a generated companion lemma has a DERIVED statement (so it can drift)

`@[reassoc]` on `foo : f ≫ g = h` auto-generates `foo_assoc`, whose statement is
RE-ELABORATED and simp-normalised for associativity — a computed transform of the
parent, not a stored copy. So it can change even when the parent's source bytes do
not: a "compiles + parent unchanged" check misses it; you must hash the generated
declaration's elaborated type. -/
namespace Playbook.Reassoc

variable {C : Type*} [Category C]

@[reassoc]
lemma foo {X Y Z : C} (f : X ⟶ Y) (g : Y ⟶ Z) (h : X ⟶ Z) (w : f ≫ g = h) :
    f ≫ g = h := w

-- Auto-generated — we never wrote this. Its statement adds a fresh object and
-- morphism and reassociates:  f ≫ g ≫ h_1 = h ≫ h_1
#check @foo_assoc

-- Proof the companion is DERIVED, not copied: give a parent whose LHS is left-
-- associated `(f ≫ g) ≫ q`. The generated `bar_assoc` comes back fully
-- RIGHT-associated `f ≫ g ≫ q ≫ h` — the attribute re-ran associativity.
@[reassoc]
lemma bar {W X Y Z : C} (f : W ⟶ X) (g : X ⟶ Y) (p : W ⟶ Y) (q : Y ⟶ Z)
    (w : f ≫ g = p) : (f ≫ g) ≫ q = p ≫ q := by rw [w]

#check @bar_assoc

end Playbook.Reassoc

/-! ## §9 — `eqToHom` needs its object-equality target PINNED with `show`

`eqToHom` turns an object equality into a morphism. When elaboration cannot infer
which equality to prove (the playbook's case: an `@[expose]` elaboration-order
change), the target becomes a stuck metavariable and the proof fails. Pinning it
with `show X = Y` fixes it. The minimal Mathlib-only trigger below is a missing
expected-type anchor rather than `@[expose]`, but it is the same stuck-target
mechanism and the same one-token fix. -/
namespace Playbook.EqToHomPin

-- Target pinned with `show` — elaborates cleanly:
example {C : Type*} [Category C] (X Y : C) (h : X = Y) : X ⟶ Y :=
  eqToHom (show X = Y by rw [h])

-- Leaving the target implicit with no anchor to infer it from FAILS — the objects
-- stay as metavariables, so the rewrite goal is `?m = ?m`:
--   #check fun {C : Type*} [Category C] (X Y : C) (h : X = Y) => eqToHom (by rw [h])
--   error: Tactic `rewrite` failed: motive is not type correct …
--   ⊢ ?m.9 X Y h = ?m.10 X Y h
-- The fix is literally adding `show X = Y` — nothing else changes.

end Playbook.EqToHomPin
