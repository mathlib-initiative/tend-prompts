# Reviewing & Managing Technical Debt — A Portable Playbook

*Distilled from a large, battle-tested debt tracker built over months on a formal-maths
codebase (a ~1,250-file Lean 4 / Mathlib formalization maintained by an agent swarm), then
abstracted to any language and repo. The original's specifics (Lean/Mathlib, `set_option`,
`sorry`, `erw`, `@[expose]`) appear only as worked examples; every rule below is meant to
transfer. Where a lesson was paid for with a real incident, the incident is named — with its
real file names and measured numbers — so the rule keeps its teeth. The numbers are the
project's actual tracker/log figures, not illustrations.*

---

## 0. The one-paragraph version

Technical debt you cannot **count** you cannot **manage**. Stand up one deterministic tracker
that scans the source and emits priced, categorised, dependency-ordered numbers; measure debt as a
**delta from a fixed baseline**, never as an absolute; put a **hard gate** on the categories that
are not allowed to exist (holes); make the tracker and a human-readable debt log **move with every
PR**; and when you pay debt down, let the **compiler/tests adjudicate** each removal rather than a
heuristic. Above all, internalise the one counter-intuitive rule that the rest of this document
keeps returning to: **a workaround that still compiles after you delete it is not necessarily
removed** — its work may have moved to a later step or a different suppression, in which case you
have *hidden* the debt, not removed it (§1.7). And **measure, don't guess** — correct your own
numbers out loud when they turn out wrong.

---

## 1. Core principles

1. **Working first, clean second.** Get to a green, reproducible baseline *before* you clean, and
   before any big dependency bump/upgrade — because the upgrade may obsolete the cleanup, and the
   scaffolding is load-bearing until the tree is green.
   *Worked example.* The source repo's Lean `v4.31.0 → v4.34.0-rc1` bump (Mathlib tag → master
   `e0c7e5b5`, 1406 commits; errors `127 → 0` across ~80 modules) was done on a verbatim-green
   baseline and *then* cleaned. The bump itself made **6 of 7** file-level `maxHeartbeats` budgets
   obsolete and let **5** transparency flags be deleted outright — cleanup that would have been
   wasted work had it run first, because the upstream code those workarounds fought had changed.
   The converse was proven the hard way in the same bump: reviewers told "this repo exists to remove
   `set_option`s" deleted the flag from three modules *mid-bump* and **~10 suppressed errors returned
   instantly**; narrowing a file-level flag on `Induced.lean` to one declaration made
   previously-suppressed errors reappear. During a bump the workaround is masking a *real* error that
   is only temporarily hidden — deleting it then doesn't remove debt, it un-hides a failure. Unwind
   scaffolding deliberately, after green, not during.

2. **Make debt visible and priced before paying it.** An amorphous "let's improve things" stalls; a
   priced, dependency-ordered queue does not. The tracker exists precisely to turn "improve things"
   into a ranked worklist.

3. **Everything you track exists to be removed.** A debt ledger is a list of *scaffolding*, not of
   features. Anything meant to stay (a measured, justified performance budget; a deliberate,
   licensed stub) is documented **as an exception, with its reason**, so it is never confused with
   removable debt.

4. **One source of truth per fact; derive history, don't store it.** If a number can be computed
   from the tree, it lives in the generator's output and **nowhere else** — a hand-copied number is
   a second source that *will* drift.
   *Worked example.* The tracker's ancestor was a hand-maintained Markdown file. When a real scanner
   was built (the dashboard greps the source for the actual directive), the hand-typed counts table
   was carried along out of habit — a second source for one fact. **Within a day** the hand-typed
   table claimed the directive sat in **90** files while the scanner counted **87**, and nothing
   flagged the contradiction; the owner caught it only by asking why two files both looked like
   trackers. The fix was *not* to reconcile the numbers — it was to **delete the second source**:
   the human log now carries no counts at all and only links to the generator's output. Recompute
   past milestones from each historical commit rather than writing them down, so that when the
   scanner itself improves, one fix corrects the whole history at once instead of freezing old bugs
   into the record.

5. **Prefer deletion — especially by upstreaming.** The single highest-leverage cleanup is debt
   that *leaves the repo entirely*: push the fix into the upstream library/platform/shared module so
   your problem disappears **and** everyone downstream benefits. *Debt that leaves the repo can never
   come back.*
   *Worked example (upstreaming).* `Inflation.lean` had **101 errors and 808 lines**, blocked on
   Mathlib names that PR **#41144** had removed. But that PR hadn't merely renamed things — it had
   *upstreamed the whole machinery*. So the debt truly left: the file collapsed to a **~250-line
   adapter** supplying only the coefficient morphisms, and the maintenance burden moved upstream
   permanently. The cost of *not* reading the diff first: `Inflation.lean` was recorded **twice** as
   "blocked, needs a design decision" when it actually needed deletion — a misdiagnosis that cost ~a
   day.
   *Worked example (thin aliases).* A sweep retired **22 declarations across 9 modules** by
   repointing every user at the upstream spelling, and deleted one file outright because it held
   nothing but four aliases (~1,000 call sites across 40 files; `fixedRep → Rep.quotientToInvariants`
   alone was **433** sites). But "it looks like a rename" is not "it's deletable": the same sweep
   found **3 apparent aliases** (43 users) that were real `Finite → Fintype` adapters with content,
   rescued from the deletion queue by verification. Delete the declaration first, then rename call
   sites — renaming first briefly produces a self-referential alias. Rank candidates by *leverage for
   you × general appeal × review cost*, and prefer removing a **class** of problems over one-off fixes.

6. **Measure, don't guess — and correct your own numbers.** Never give a receding, optimistic
   estimate; measure against the whole-tree counter and restate loudly when a published number turns
   out wrong.
   *Worked example.* A migration's debt impact looked at first like a single **+1** `erw` site. Re-measuring
   over all **1268** touched files (HEAD vs the pre-migration tree `6dbe28c60`) with the whole-tree
   per-rewrite counter found a *second* file where two branches each gained an extra rewrite: the
   honest figure was **+3**, not +1 (whole-tree count `232 → 235`). The debt is real, and the
   correction mattered — an eyeball count of one obvious site understated a measurement by two. State
   the correction out loud; do not quietly fix it.
   ```lean
   -- HomologyRestrictionShapiroDesc.lean — the site the eyeball count missed
   -- before: one rewrite sufficed
   erw [LinearMap.map_zero]
   -- after @[expose]: the goal no longer folds the two nested map_zeros, so it must fire twice
   erw [LinearMap.map_zero, LinearMap.map_zero]
   ```

7. **Removal ≠ deletion: a debt only leaves if nothing absorbs its work.** This is the rule the
   whole playbook orbits, and the one most people get wrong. A workaround that still compiles after
   you delete it is **not necessarily removed** — its work may have moved to a later tactic/cast/
   default, to a different suppression, or into a scoped flag that was quietly doing the unification.
   That *hides* the debt; it does not remove it. **A removal counts only if nothing new had to be
   added to compensate** (no cast, helper, type ascription, alternate suppression, or raised budget).
   The test for "did anything absorb it" is §5.5; this principle is *why* you run it.
   *Worked example.* An attribution sweep found **121** debt items in 21 files that compiled *without*
   their debt regardless of the bump — under a naive "does it still build?" test, all 121 look
   removable. Under the absorber test, only **56** genuinely were; the other **65**, though all green,
   were rejected because deleting them required something else to compensate. The split by kind and by
   reason:

   | Workaround kind | candidates | truly removed | …kept: hidden defeq | …closer needs default | …flag absorbs / entangled | …other |
   |---|---|---|---|---|---|---|
   | scoped flag | 17 | 17 | | | | |
   | `change` / `show` | 59 | 29 | 15 | 9 | 5 | 1 |
   | `erw → rw` | 38 | 4 | | 8 | 25 | 1 |
   | other | 7 | 6 | 1 | | | |
   | **total** | **121** | **56** | **16** | **17** | **30** | **2** |

   A whole-environment hash of all **3854** declarations showed **0** changes, confirming the 56
   removals moved no content — and that the 65 kept items each still need a *seam* (a restated lemma,
   an upstream-spelling restatement), not a deletion. The before/after of one rejected item makes the
   trap concrete:
   ```lean
   -- BEFORE: the flag documents a reliance on default-transparency unification
   set_option backward.isDefEq.respectTransparency false in
   lemma foo … := by
     simp only [a, b, c, d, e, f, g, h]   -- 8 lemmas
     exact h₁.trans h₂
   -- AFTER deleting the flag + the 8 now-orphaned simp lemmas: it BUILDS GREEN.
   lemma foo … := by
     exact h₁.trans h₂   -- but `exact` now unifies at DEFAULT and absorbs the gap:
                         -- the debt moved into the closer, undocumented. NOT removed.
   ```

---

## 2. Classify debt by severity — a portable taxonomy

Not all debt is equal. Separate it into tiers with **different gates**:

| Tier | What it is | Gate |
|---|---|---|
| **Holes** | Code that *lies about being done*: `TODO`/`FIXME` on a code path, stubbed/placeholder returns, `throw new NotImplementedError`, skipped/`xit`/`@Disabled` tests, commented-out assertions, `any`/`unsafe` casts that defeat the type system, swallowed exceptions | **Hard zero** (or explicitly licensed + tracked). Blocks merge. |
| **Suppressed-signal debt** | Workarounds that silence a tool the rest of the codebase trusts: `eslint-disable`, `# type: ignore`, `@ts-ignore`, `#[allow(...)]`, `#pragma warning disable`, `@SuppressWarnings`, blanket `catch`, arbitrary `sleep`/retry/timeout bumps | Counted, capped, trending down. Each occurrence annotated with *why*. |
| **Soft / structural debt** | Duplication, god objects, a construction maintained in two places, a feature flag never cleaned up, dead code kept "just in case" | Counted as "soft"; paid down by root-cause, not one-by-one. |
| **Stylistic debt** | Formatting, long lines, naming drift, missing docstrings | Lowest priority; mostly auto-fixable; never let it mask a real-signal tier. |

**Define the exact marker set for *your* repo and encode it in the scanner.** The taxonomy is only
useful if "a hole" has a precise, greppable definition the whole team agrees on. (The source repo's
hole set was `sorry`, `admit`, `stop`, `sorryAx`, `axiom`; its suppressed-signal set was
`set_option` overrides, `erw`, `change`, and `maxHeartbeats` bumps.)

A hole is a **task, never a hole.** If something genuinely cannot be finished now, it is written as
a tracked, licensed stub that names its follow-up task (e.g. `TODO(JIRA-1234): …` with the ticket
actually filed) — not left as a bare gap the census can't distinguish from an oversight.

---

## 3. Build the quantified tracker (the single source of truth)

A tracker is **code**, and it must behave like code:

1. **Deterministic: a pure function of its inputs.** Run it twice, get byte-identical output — or
   every regeneration produces a spurious diff and reviewers stop reading it. Sort every collection
   with a **total key** (add a unique tiebreaker like the name); never let set/hash/dict iteration
   order reach the output. *Prove it*: run twice under different hash seeds (`PYTHONHASHSEED`, etc.)
   and diff.
   *Worked example.* The generator derives each module's `upstream_debt` from a Python **set**, whose
   iteration order follows string hashing. Without a total sort key it would emit a different file on
   every run with no source change at all. The fix — and the in-code comment that names exactly this
   failure:
   ```python
   # WRONG: iterates a set -> hash-ordered, nondeterministic output, spurious git diffs
   upstream_debt = [d for d in closure.get(m, set()) if d in debt_files]
   # RIGHT: total key, module name `d` as the final tiebreaker so ties never fall back to hash order
   upstream_debt = sorted(
       (d for d in closure.get(m, set()) if d in debt_files and d != m),
       key=lambda d: (level.get(d, 0), -blast.get(d, 0), d))
   ```
   The same discipline runs everywhere a collection reaches output: duplicate keys get a `::{n}`
   suffix so even colliding keys are totally ordered, and cross-type sort keys are type-tagged
   (`(0, int, "")` vs `(1, 0, str)`) so a mixed column can't raise mid-run.

2. **Never drop a row in silence.** When the generator *cannot* compute something (a file it failed
   to parse, a missing historical commit), it must say so **in the output**. A silently shortened
   table is indistinguishable from a genuinely shorter one.
   *Worked example.* `milestone_counts()` re-scans each milestone commit by extracting its tree; if
   the commit isn't in the clone (shallow/rebase/squash) or won't extract, it does **not** drop the
   row — it sets `row['unavailable'] = 'commit not in this clone'`, prints a WARNING to stderr, and
   renders the row *with its reason*. The JSON-input reader does the same: malformed inputs are tallied
   in a `bad_files` counter (never fatal — the rest still renders) and the summary prints
   `"{n} input file(s) could not be read and are not counted."` A shortened history can never be
   mistaken for a shorter one.

3. **Count as a delta from a fixed baseline**, not as an absolute. "235 workarounds" means nothing;
   "+3 vs the pre-migration baseline" is a reviewable fact. Pin a baseline ref and diff against it.
   *Worked example.* The generator hard-codes `BASELINE = "bc6ec4e"` (the pre-bump merge) and records
   `baselineTotal: 231`; every per-item origin is computed from `git diff bc6ec4e HEAD -U0 -- CFT`, so
   each row shows *bump vs port* provenance. But note the discipline in the next rule: the headline
   "open suppressions" tile is **deliberately not rendered as a delta** against 231, because the
   counting unit changed under it — it reports the comparable shape metric "0 file-level" instead.
   Pin the baseline for the per-row diff; suppress the aggregate delta the unit change would corrupt.

4. **Count at the right granularity — and document the unit.** Decide whether you count per *call*
   or per *occurrence* and write it down. **When the unit changes, recompute every historical row
   under the new rule and never quote a delta across the change** — otherwise a pure re-definition
   reads as a regression.
   *Worked example.* `erw [l1, l2]` is two defeq bridges, and one may demote to plain `rw` while the
   other can't — so the scanner was changed to emit **one debt item per rewrite, not per tactic
   call**. The recount turned **169 tactic calls into 352 rewrites**; crucially the *history* was
   recomputed under the same rule (each old commit re-scanned with today's scanner), so the pre-bump
   baseline was re-stated as **367** rewrites and the trend column stayed comparable.
   ```python
   # per-call (old unit):  erw [lemmaA, lemmaB]  -> 1
   # per-rewrite (new unit, documented in the code): one row per lemma -> 2
   for k, lem in enumerate(call["lemmas"], 1):
       erws.append({..., "k": k})   # "# one debt item PER REWRITE, not per tactic call"
   ```
   The cautionary twin is the cost of *not* doing this: a separate file-level→scoped conversion moved
   the directive *line* count `231 → 590` while actual debt **fell**, and the naïve "+359 vs baseline"
   read as a 2.5× regression that never happened.

5. **Curated annotations are the human layer — match them robustly.** The scanner produces raw
   counts; a separate, human-curated annotations file records *why each item exists* and *what would
   remove it*. **Match annotations to code by something stable** (declaration/symbol name + basename),
   not by full file path, so they survive file moves and renames. Include a **"resolved" detector**:
   annotations that no longer match any code are surfaced so stale curation gets pruned.
   *Worked example.* The annotations file had two layers. The **1029** top-level keys were matched by
   decl/basename, which a big module rename did not touch — **zero** remapping needed. The lower
   `occurrences` layer was keyed `module::option=value::decl`, embedding the path, so the reshape broke
   all **225** of them: a straight regeneration would have reported all 225 as falsely "resolved" (the
   debt was still there, just moved). A remap script rewrote those 225 keys onto the new paths, after
   which the tracker reported the honest **33** resolved (0 new). That is the exact, one-time price of
   keying the durable layer by path instead of symbol.
   ```python
   # fragile: module path in the key -> breaks on every rename, spikes false "resolved"
   key = f"{module}::{option}={value}::{decl or 'file'}"
   # durable: match the human layer by decl/basename (1029 of these survived the rename untouched)
   ```

6. **Emit two artifacts from one run:** a machine-readable summary (counts, trends) and a
   human-readable index. Both regenerated by the same command; neither hand-edited.

---

## 4. Gates — make debt impossible to accumulate silently

1. **Hard gate on holes, enforced three ways:**
   - **Per-merge:** CI fails if the whole-tree hole census is non-zero (or exceeds the licensed set).
     A holed change *compiles and may even pass local tests*, so run the census **first and fast**,
     before the expensive build.
     *Worked example.* The hole census is a **pure source scan — it never invokes the build**,
     precisely because *"a module containing `sorry` builds, so the cheapest way to make a module
     green is to hole the proof out; nothing else in the toolchain counts holes."* It reads each
     file's raw bytes, masks comments/strings with a lexer-faithful masker (an earlier scratch regex
     was bypassed by a `def «shim/-» := 0` guillemet identifier that hid the rest of the file from the
     scanner), token-matches the hole markers, and keys its baseline by `(module, tag)` not line so a
     repair that moves lines doesn't false-positive. That makes it cheap enough to run *ahead of*
     `lake build` in the gate, and it catches `admit`/`stop`/`sorryAx`/`axiom` holes the compiler
     does not separately report.
   - **Final whole-tree audit:** on a clean checkout, from scratch, re-run the census — not the
     incremental one, which can mask.
   - **Transitive / honesty sweep** for any external "it's complete" claim: a hole can hide behind a
     dependency. Run whatever deep check your ecosystem offers (dependency-closure scan, coverage
     over the real entry points, `#print axioms`-style introspection) before you tell a stakeholder
     "done."

2. **Debt moves with every PR.** The tracker output *and* the human debt log are updated **in the
   same PR** that changes the debt. Debt counts appear in **every** status report (per-unit rows +
   deltas, not just an aggregate). Never land a change that moves debt without moving its record.

3. **Account for every warning *absolutely*, against a documented target — and record deferrals the
   same day.** "Same as last time" is not a check when last time was already wrong.
   *Worked example.* The README said the cold build had **2** warnings (two deliberate holes). It
   actually had **71**: the other **69** were a header-linter class that a Mathlib bump had started
   flagging across 69 files, entering silently with a bump whose note said "counts flat" (true for
   debt, silent about warnings). Three separate cold builds afterward all reported "identical to the
   baseline (71)" — and all were *right*, because **the baseline already contained the regression**;
   a baseline-relative check cannot see a defect baked into the baseline. The fix moved each docstring
   under the imports (`71 → 2`, all 3854 declaration hashes unchanged). The deeper failure: the 69
   *were* named in the PR body under "Follow-up," but no open item/annotation/target note recorded the
   deferral — so "account against a documented target" is the real rule, not just "count absolutely."
   (A per-file compile cannot even see this linter; only the full build reports it — cf. §7.1.)

---

## 5. The campaign loop — how to actually pay debt down

Run every cleanup round the same way:

1. **Census first, and distrust it.** Mask comments/strings/docstrings **before** counting — a naïve
   `grep` both invents phantoms (a substring that matches an unrelated field) and misses real ones
   (a marker buried in prose, a directive on a line with a trailing comment). Match file paths
   **exactly** and symbols by **qualified name** — a suffix match on `Foo` also catches `BarFoo`.
   Cross-check your regex scanner against a semantic one (an AST/LSP-based count) periodically; they
   should agree at the position level.

2. **Pick the target by dependency level, then by blast radius.** Fix **bottom-up**: the pathology
   usually originates in an upstream definition and downstream code merely re-suffers it. Fixing the
   root is what makes the downstream workarounds *droppable*. Within a level, **high blast radius
   first** — those removals cascade. Measure blast radius per *declaration/symbol*, not per file (a
   crude import-graph fan-out correlated only ~0.3 with the real dependent count). Zero-dependent
   leaf debt is its own easy queue: removing it can't break anything.

3. **Bundle removals by root cause, not by file.** One PR that installs a shared fix and drops the
   15 workarounds it unblocks tells a reviewable story; 15 scattered one-line PRs do not.

4. **Let the compiler/tests decide, not a heuristic — and don't mistake "it compiles" for "it's
   gone."** The reliable procedure is: remove the workaround → rebuild/retest that unit → re-add
   **only** where the toolchain objects → iterate. But a bare recompile *vastly over-counts* what can
   actually be removed, so it is a candidate filter, not a verdict.
   *Worked example.* A whole-tree sweep found **207 of 331** rewrites "compile as `rw`." Applying the
   absorber test (§5.5) kept only **24** — a **~9×** gap, because 192 of the 207 sat in declarations
   whose scoped flag was silently doing the work. The same sweep's `change` class ran `689` sites →
   `98` compile-clean → `36` surviving a re-insertion demo → `29` after review (7 refuted, **4 of them
   docstring prose beginning with the word "change"** — cf. §6.6). "Compiles after deletion" is the
   start of the investigation, not the end of it.

5. **Apply the absorber test — the subtle one (this is §1.7 made operational).** For each candidate
   removal, ask: *did anything new appear to do the deleted workaround's job?* — a cast, a restated
   helper, a `show`/`convert`/coercion, a different suppression, a raised budget, an import that shifts
   elaboration. A removal counts **only if the site is green with nothing added in its place.**
   Mechanise the question rather than eyeballing it:
   - **Run a restricted-transparency oracle, not a bare recompile.** In the source repo this was
     `with_implicit tacs`, which runs the goal-closing tactics at a reduced unfolding level. Wrap the
     later closers in both the original (`O`) and the edited (`D`) versions. If `D` fails where `O`
     passes, the edit pushed work into that closer — **keep the debt**. If both fail, the goals at
     that point must be structurally identical (by goal hash) or **keep the debt**. For a deleted
     `change`, re-insert it under the oracle (`with_implicit change <deleted text>`): if it
     elaborates, it did only cheap work and nothing later can have absorbed more.
   - **Beware the flag that blinds the oracle.** A scoped widening flag can make a strict step pass
     for the wrong reason. The discriminator for a demoted rewrite: run strict `erw` and strict `rw`.
     If strict `erw` passes and strict `rw` *fails*, the flag absorbed the extra unfolding — keep it;
     if strict `erw` also fails, the step is entangled with the flag — keep it. On the source repo
     this rejected **25 of 38** dead `erw` as flag-absorbed or entangled; only **4** were real
     removals. Inside flagged declarations the oracle itself must re-assert strict transparency
     (`respectTransparency true in with_implicit …`), or it lies.
   ```lean
   -- D (edited): re-insert the deleted workaround under the oracle
   with_implicit change <deleted text>   -- elaborates ⇒ only cheap work ⇒ TRUE removal
   -- inside a flag-carrying declaration the flag blinds the oracle, so re-assert strictness:
   set_option backward.isDefEq.respectTransparency true in with_implicit exact closer
   ```

6. **Before crediting a *change* with freeing debt, use a control tree.** When a bump/upstream-PR/new
   abstraction lands, it is tempting to credit it with every removal that becomes possible afterward.
   Re-apply the gain in a tree that differs *only* by that change; items green in **both** trees are
   dead debt nobody had looked for, not debt the change freed.
   *Worked example.* After a bump, a sweep found **47** more removable items under the absorber
   standard — but every one of the **47 also compiled in the pre-bump tree**. The bump freed nothing;
   the debt had been dead all along and no sweep had looked. A timeline ("it appeared after the bump")
   would have falsely credited it; two built trees differing only by the change told the truth.

7. **Verify cold, then record.** Final verification is a clean-from-scratch build, never incremental.
   Then update the ledger, regenerate the tracker, and log the round (what moved, by how much, why)
   in the human debt log — with the attempted-and-kept sites named, not just the removals.

---

## 6. Safety rules for bulk / mechanical edits

Every rule here was paid for with a real incident.

1. **Never write a text transform whose output feeds its own input condition.** Iterate over a
   **frozen copy**; evaluate every condition against the *original* text.
   *Worked example.* A pass to fix exactly **3** wrapped-comment continuations read its "previous
   line" from the *output* buffer, so each freshly-commented line triggered the next — the comment
   front marched down each file. Result: **~7,300 lines across 150 files** turned into comments,
   **1083 errors**, on *uncommitted* work where a `git checkout` would have destroyed the whole bump.
   It was recoverable only because the transform was purely additive (the pre-change git baseline was
   a line-by-line oracle): 7,108 lines restored from git + 193 via a classifier, 7,439 genuine
   comments kept, net −21 fully explained.
   ```python
   # BUG: condition reads the buffer it is writing
   for line in lines:
       if out[-1].startswith('--') and not line.startswith('--'):
           out.append('--' + line)        # out[-1] is now a comment -> cascades
   # FIX: condition reads the frozen original
   for i, line in enumerate(lines):
       if lines[i-1].startswith('--') and not line.startswith('--'):
           out.append('--' + line)
   ```

2. **Snapshot before any bulk rewrite**, and before discarding any tree that holds uncommitted work.
   The pre-change VCS state is your oracle for recovery (it is what made §6.1 survivable).

3. **A "tidy" transform is a semantic transform until proven otherwise.** Deduping, reordering, and
   reformatting can change behaviour. Only provably idempotent operations are safe to batch; for a
   **handful of known sites, edit them individually.**
   *Worked example.* A review found **3** tactic lists with a literally repeated token after a rename.
   Instead of fixing the 3, a blanket pass collapsed consecutive duplicates in every bracketed list —
   **258 lists across 73 files** — and broke **28** proofs: `simp only [X, X]` is an idempotent set
   (safe to collapse) but `rw [h, h]` *rewrites twice* (collapsing it changes the proof). Recovery was
   messier than the damage: reverting by *content* over-fired on files holding both `rw [X]` and
   `rw [X, X]`, taking four passes to settle on the **2** legitimate dedupes.
   ```lean
   rw [h, h]          -- sequence: rewrites twice; collapsing to rw [h] => 28 errors
   simp only [X, X]   -- set: idempotent, collapse is safe
   -- Rule: for 3 known sites, edit them by hand; never reach for a repo-wide pass.
   ```

4. **Anchor patterns on the construct/token itself, never on a line number or a positional walk.**
   Code repeats shapes, so a position derived from an error line is not an identity. *(A repair that
   walked back from each error line to "the nearest match" landed on a *different*, working construct
   and turned 1 error into 8.)*

5. **When reverting a bulk edit, align by position / diff against the baseline — not by content.**
   Content matching silently conflates identical lines elsewhere in the file and turns a small
   problem into a long hunt (this is exactly what cost the extra passes in §6.3).

6. **Scanners reason about tokens, not lines, and mask comments/strings first** — with the repo's
   *shared* masker, not a scratch regex.
   *Worked example.* A sweep for removable `change`/`show` tactics used a line-start regex. **Four
   docstrings begin with the English word "change"** ("change of resolution…", "change of
   coordinates…"), so the regex matched *prose* as if it were a tactic and proposed **deleting 4 lines
   of documentation** — and even matched the re-insertion demo, since inside a docstring
   `with_implicit change …` is still prose. The repo already shipped a comment/docstring masker; this
   was a scratch script that didn't use it. Adversarial review caught all 4 before anything applied.
   ```text
   /-- change of resolution: ... -/   <- matched by  ^\s*·?\s*(change|show)\b
   # FIX: mask comments/docstrings with the repo's shared masker BEFORE scanning tokens,
   #      and self-test the scanner on a docstring line that opens with a tactic keyword.
   ```

7. **Validate the tool on one case — including one it must reject — before running it on hundreds.**
   Any code that parses source structure first passes a known-nasty sample (a comment that looks like
   code, a docstring ending in a code-like token, a header before the imports, one input it *must*
   reject). *(See §7.5 for the harness that silently scored broken variants as "identical to
   baseline" because it was never shown an input it had to fail.)*

8. **On a high failure rate, suspect the tool before the material.** Inspect two or three "hard
   cases" by hand before theorising about why they're hard.
   *Worked example.* A per-declaration conversion reported **36** "stragglers" that looked like
   genuinely hard mathematics. Inspecting a few by hand showed **25** were a single off-by-one in the
   insertion walker: it checked `startswith('--')` *before* `endswith('-/')`, and this repo's
   docstrings routinely end on a line like `-- blueprint.tex … -/`, so the walker stepped *into* the
   docstring and placed the flag inside it. After reordering the two checks, all 25 converted in
   minutes. The instrument was lying about where the debt was.
   ```python
   # BUG: comment test wins, so it fires on a docstring's '-- ... -/' tail
   if line.startswith('--'):      skip_comment()
   elif line.endswith('-/'):      in_doc = False
   # FIX: close the docstring first
   if line.endswith('-/'):        in_doc = False
   elif not in_doc and line.startswith('--'): skip_comment()
   ```

9. **Put the guard in the tool, at the line it governs — knowledge filed elsewhere does not fire.**
   A trap written up in a design doc won't save you while you're writing the parser; encode it as a
   guard in the parser, with a comment citing the rule. **Copying a walker counts as writing one** —
   re-check it against the trap list. *(The same docstring-boundary trap from §6.8 recurred three
   times, each in freshly-written or freshly-copied tooling, because the write-up lived where it
   didn't fire.)*

---

## 7. Verification discipline

1. **Run any check with the real build/CI configuration, explicitly.** A per-file probe that uses
   different options than the full build (different lint set, different optimisation, different
   synth/resolution settings) proves nothing about CI.
   *Worked example.* A first flag sweep (v1) accepted **101** removals in 26 minutes with the linters
   off and the wrong synth depth; the real build then broke — one rewrite failure two files away and
   seven linter warnings. A second sweep (v2), with the real lakefile options applied and a
   per-declaration signature hash appended to every compile, accepted **97** and the full build was
   green first time. v1 and v2 agreed on only **91**: v1 had **10** wrong, and v2 found **6** that
   v1's weaker config had masked. (Of all 590 flags only 97 were mechanically removable, ~16%; for the
   transparency subset specifically it was the cheap **13% — 65 of 509** — meaning that flag was
   genuinely load-bearing 87% of the time.)

2. **Judge by observable behaviour / exported API, not by exit code alone.** A unit can compile while
   its *exported signature* (public type, generated code, serialized schema, API shape) silently
   changed and only a downstream consumer notices. Hash/snapshot the exported surface before and
   after; reject a change that moves it even if the build is green.
   *Worked example.* During the first flag sweep, `cokernelπ_shiftUpMap` compiled green after its flag
   was removed — so a compiles/no-new-warnings check accepted it. But the `@[reassoc]` lemma
   *auto-generated* from it re-elaborated to a different statement, and a downstream consumer's rewrite
   silently stopped matching; the parents' own statements never moved, so nothing local flagged it.
   The defence was a signature guard appended to every compile that logs, per declaration, a hash of
   the fully-elaborated type and the proof-erased value; any hash that differs from baseline rejects
   the removal even on a green build. It caught drift in **3** generated lemmas whose parents were
   unchanged.
   ```text
   # exit-code check: PASS (file compiles) -> removal accepted, consumer silently broken
   # signature check: baseline hash != post-edit hash  ->  REJECT even though the build is green
   ```

3. **Read the log / the real exit status, never a wrapper's.** A wrapper's or a pipeline's exit code
   is not the build's.
   *Worked example.* `lake build … > log 2>&1; echo "EXIT=$?"` makes `$?` the exit code of `echo`, so
   the harness announced "completed (exit code 0)" while the log recorded `EXIT=1`. The same lie
   reappears through pipes: `lake build … | grep error` returns *grep's* status — 0 over a genuinely
   failed build (2026-08-19) and 1 over a green one (2026-09-26), exactly inverted — and a `… | tee`
   CI step without `set -o pipefail` reported a crashed script as green. In every case the breakage
   was fully present; only the status-reporting link was broken.
   ```bash
   lake build ... > log 2>&1; echo "EXIT=$?"   # $? is echo's  -> always 0
   lake build ... | grep error                 # $? is grep's  -> inverted
   # FIX: capture the real status, then read the whole log
   lake build ... > log 2>&1; REAL_EXIT=$?
   grep -E '^error|Build completed successfully' log
   ```

4. **A destructive step must verify its own effect** before anything downstream claims success. *(A
   "wipe the build cache" command ran from the wrong directory, deleted nothing, and the following
   "clean" build was silently incremental.)* Count what you deleted; confirm the directory is gone.

5. **Count diagnostics robustly; validate every harness on a known-bad input.** Prefer structured
   output (`--json`, severity fields) over text matching.
   *Worked example.* A leave-one-out harness counted per-variant errors with a regex on the literal
   text `error: `. The first candidates were misspelt, so their lines raised the newer *coded* form
   `error(lean.unknownIdentifier): …` — which the regex matched *neither*. It therefore counted **zero**
   errors, the genuinely-broken variants looked byte-identical to the baseline, and they were recorded
   "useless"; a real verification result was inverted into a false "no effect." The harness had never
   been shown an input it must reject.
   ```bash
   grep -c 'error: '                 # misses error(lean.unknownIdentifier): ...
   # FIX
   grep -cE 'error(\([^)]*\))?:'      # or: jq 'select(.severity=="error")' from --json
   # then feed the harness ONE input it must fail, and confirm it says so
   ```

6. **Confirm that your reporting actually reports.** An armed schedule is not a working one. *(A
   progress cron was listed as scheduled but never delivered a single tick — it only fired when the
   session was idle, which never happened; it recurred later because a stale one-line instruction
   still said "arm a cron.")* Prefer a mechanism that **pushes** and confirm the first message
   arrives; and when you change a rule, **fix every short form of it** (index lines, summaries,
   templates) in the same change, or the stale copy is what fires.

---

## 8. Working safely in a shared or owner's environment

1. **Isolate experimental/bulk work in a clone or worktree**, never in someone's live tree. Give
   delegated commands **absolute paths**; a bare relative path or `git` command lands wherever the
   shell happens to start.

2. **Never switch the owner's working tree under them, and never share a build cache across
   differing configs/manifests.**
   *Worked example.* A scratch worktree for a benchmark tool symlinked the shared dependency cache
   (`.lake/packages`) from the owner's main checkout but carried a *different* manifest. The build
   tool treats that checkout as the manifest's to move, so it checked the shared Mathlib clone out at
   the scratch commit and began rebuilding **~550 modules over the owner's prebuilt cache** before it
   was killed — destruction, not debt reduction. A sibling incident did the same by cutting a new
   branch in the owner's tree, reverting his toolchain. The fix: clones get their *own* cache, and a
   dry-run check proves nothing will rebuild before building.
   ```bash
   # BUG: shares the owner's cache under a different manifest
   ln -s /home/edison/CFT_clean/.lake/packages scratch/.lake/packages
   # FIX: own cache, then PROVE nothing will rebuild
   git clone --shared ... scratch && cd scratch && lake exe cache get
   lake build --no-build Mathlib    # must print nothing to build
   ```

3. **A cleanliness claim names exactly one tree.** `git -C <that-tree> status --short` — don't
   attribute a concatenated status covering two trees to one of them.

4. **Match processes by the binary's full path, never by a substring that also appears in the
   command doing the matching** — or your `pkill` matches your own shell.

---

## 9. When a migration or upgrade surfaces a *class* of breakage

Large mechanical migrations (a framework upgrade, a language-mode switch, an API sweep) tend to
produce a handful of recurring breakage *patterns* rather than N unique bugs. Treat them as a set:

1. **Taxonomise the classes, and give each a mechanical fix recipe with per-site counts.** This turns
   a scary error wall into a checklist and makes any re-run of the migration cheap.
   *Worked example.* Putting **1267** files on Lean's module system added a header + public import +
   blanket `@[expose]` section to **1266** of them. The one regression `@[expose]` causes — it changes
   elaboration order and breaks fragile casts whose target was inferred from the other side of an
   equation — could **not** be undone by any blanket switch; each site needed its statement pinned.
   The breakage collapsed into labelled classes with exact counts: **(B)** copy the stuck goal
   verbatim into an explicit target — **16** sites in 4 files; **(C)** append a default-transparency
   `; rfl` when pinning one side breaks the other — **6** sites in 2 files; argument pins — **5** sites
   in 3 files; plus smaller traps D–F. Because the fix was per-class and per-site, only **217** files
   were hand-fixed and **1053** were mechanical-only; the whole-tree build stayed green (5260 jobs),
   the census stayed at 0 holes, and the net tracked-debt cost was just the **+3** `erw` of §1.6.
   ```lean
   -- Class (B) fix — pin the cast target the new elaboration order can't infer
   -- before: target inferred from the other side -> stuck metavariable
   eqToHom (by rw [...])
   -- after: copy the stuck goal verbatim (note the .X₁ form, not bare X)
   eqToHom (show C.X₁ = D.X₁ by rw [...])
   ```

2. **No blanket switch fixes a class for free — pin each site that genuinely needs it individually,**
   and leave the rest clean. A global suppression to "make it build" just converts one debt class
   into another.

3. **Track the net debt delta honestly**, separating *mechanical-baseline* work (in scope) from any
   *deferred narrowing/tightening* (explicitly out of scope, logged as a follow-up). Report the real
   number even when it's worse than your first estimate (§1.6). And when the migration moves files,
   expect to pay the path-keyed-annotation cost of §3.5 once.

---

## 10. Reporting & collaboration discipline

- **Per-unit rows and deltas, not aggregate summaries.** "Module X: 12→9 (−3)" beats "debt down ~20%".
- **Finish diagnostics with a fix.** A probe ends in a repair and a resume, not a findings list.
- **Opinion before acting on design/policy.** When asked to make a judgement call (a tracker design,
  a gate policy), say *agree/disagree and why* before building it. Operational repairs stay
  act-then-report.
- **Honesty over optimism.** State absolute numbers and their causes; correct understatements out
  loud; never present an approximation as a measurement. The whole document rests on this: an example
  is only worth citing if its number is the measured one.

---

## 11. Starter checklist for a new repo

1. **Pin a baseline commit** and record it in the tracker config.
2. **Define the marker sets** for each tier in §2 (holes / suppressed-signal / soft / stylistic),
   precisely and greppably, for this repo's languages.
3. **Write the deterministic scanner** (§3): source scan + baseline diff + curated-annotations merge
   → one summary artifact + one human index. Prove determinism (two runs, varied hash seed, diff).
4. **Write the human debt log** (this document's local cousin): principles, a per-area ledger of
   *why each item exists and what removes it*, and a running log of cleanup rounds. Link to the
   generated numbers; never restate them.
5. **Wire the gates** (§4): hole census in CI (fast, first), a from-scratch audit job, a
   deeper/transitive check for release claims.
6. **Add the PR ritual:** every PR updates tracker + debt log; the PR template asks for the debt
   delta; status reports quote per-unit counts.
7. **Put the §6 safety guards into the tooling itself**, each at the line it governs, with a comment
   citing the rule.
8. **Do one real cleanup round** end to end (§5) to validate the whole loop — including the absorber
   test (§5.5) and a cold final verify — before scaling it.

---

## Appendix — the anti-pattern catalog (one line each)

| # | Failure | Rule |
|---|---|---|
| 0 | Accepted a green-compiling removal whose work had only *moved* | Removal ≠ deletion; run the absorber test (§1.7, §5.5) |
| 1 | Transform read its own output → cascading corruption (~7,300 lines) | Iterate over a frozen copy; evaluate against the original (§6.1) |
| 2 | Blamed the material for a tool bug (25 of 36 "hard cases") | High failure rate → suspect the tool first (§6.8) |
| 3 | Regex anchored on the wrong delimiter → dangling refs | Anchor on the token; have prose-aware review (§6.4) |
| 4/13 | Scheduled report never fired | An armed schedule ≠ a working one; confirm the first tick; push don't poll (§7.6) |
| 5 | Wrapper/pipe reported success over a failed build | Read the log / real exit status (§7.3) |
| 6 | Hand-copied a generated number → drift (90 vs 87 in a day) | One source of truth; derive, don't store (§1.4) |
| 7 | Generator not deterministic (set iteration) → spurious diffs | Total sort keys; prove under varied hash seeds (§3.1) |
| 8/14 | Re-made a documented trap in fresh/copied tooling | Guard in the tool, at the line; copying = writing (§6.9) |
| 9 | "Tidy" dedupe changed semantics (rw [h,h] → 28 breaks) | Tidy is semantic until proven; revert by position (§6.3, §6.5) |
| 10 | Per-file check used a different config than the build (101→97) | Real config + exported-signature check + self-verifying destructive steps (§7.1, §7.2, §7.4) |
| 11 | Harness regex couldn't see coded errors → broken scored "identical" | Count by structured severity; validate on known-bad input (§7.5) |
| 12 | Delegated agents ran in the owner's tree | Isolate in a clone; absolute paths; one-tree cleanliness claims (§8) |
| 15 | Sweep counted docstring prose as code (4 "change" lines) | Scanners mask comments and reason about tokens (§6.6) |
| 16 | Warnings hidden by baseline-relative checks (69 behind "71") | Account for warnings absolutely; record deferrals the same day (§4.3) |
| 17 | Wrong rule fanned out to N agents → N identical breakages | Check every rule against the compiler + precedent before fan-out (§6.7) |
| 18 | Repair anchored on the error line | Anchor on the construct; revert by diff against baseline (§6.4, §6.5) |
| 19 | Shared dependency cache overwritten across manifests (~550 modules) | Clones get their own cache; never move the owner's tree (§8.2) |
| 20 | Credited a bump with freeing debt that was dead all along (47/47) | Use a control tree, not a timeline (§5.6) |

---

*The throughline: debt management is an **instrumentation** problem before it is a **cleanup**
problem. Build the honest instrument first; the cleanup becomes a ranked, reviewable, reversible
sequence of small verified steps — and every number you report can be trusted because it was
measured, not remembered. And never confuse a green build with a removed debt: that single
confusion is what §1.7 and §5.5 exist to prevent.*
