# Reviewing & Managing Technical Debt — A Portable Playbook

*Distilled from a large, battle-tested debt tracker built over months on a formal-maths
codebase, then abstracted to any language and repo. The original's specifics (Lean/Mathlib,
`set_option`, `sorry`, `@[expose]`) appear only as worked examples in parentheses; every rule
below is meant to transfer. Where a lesson was paid for with a real incident, the incident is
named so the rule keeps its teeth.*

---

## 0. The one-paragraph version

Technical debt you cannot **count** you cannot **manage**. Stand up one deterministic tracker
that scans the source and emits priced, categorised, dependency-ordered numbers; measure debt as a
**delta from a fixed baseline**, never as an absolute; put a **hard gate** on the categories that
are not allowed to exist (holes); make the tracker and a human-readable debt log **move with every
PR**; and when you pay debt down, let the **compiler/tests adjudicate** each removal rather than a
heuristic — because a workaround that still compiles after you delete it may just have moved its
work somewhere invisible. Above all: **measure, don't guess**, and correct your own numbers out
loud when they turn out wrong.

---

## 1. Core principles

1. **Working first, clean second.** Get to a green, reproducible baseline *before* you clean, and
   before any big dependency bump/upgrade. Cleaning before upgrading means re-doing the cleanup when
   the upgrade obsoletes it. *(On the source repo, a toolchain bump made 6 of 7 performance
   workarounds obsolete and let 5 more be deleted outright — cleaning first would have wasted all of
   that.)*

2. **Make debt visible and priced before paying it.** An amorphous "let's improve things" stalls; a
   priced, dependency-ordered queue does not. The tracker exists precisely to turn "improve things"
   into a ranked worklist.

3. **Everything you track exists to be removed.** A debt ledger is a list of *scaffolding*, not of
   features. Anything meant to stay (a measured, justified performance budget; a deliberate,
   licensed stub) is documented **as an exception, with its reason**, so it is never confused with
   removable debt.

4. **One source of truth per fact; derive history, don't store it.** If a number can be computed
   from the tree, it lives in the generator's output and **nowhere else** — a hand-copied number is
   a second source that *will* drift (it did: a hand-maintained "87 vs 90 files" table disagreed
   with the scanner within a day). Recompute past milestones from each historical commit rather than
   writing them down, so that when the scanner itself improves, one fix corrects the whole history
   at once instead of freezing old bugs into the record.

5. **Prefer deletion — especially by upstreaming.** The single highest-leverage cleanup is debt
   that *leaves the repo entirely*: push the fix into the upstream library/platform/shared module so
   your problem disappears **and** everyone downstream benefits (one upstream PR turned an 808-line
   file into a ~250-line adapter). Rank candidates by *leverage for you × general appeal × review
   cost*, and prefer changes that remove a **class** of problems over one-off fixes.

6. **Measure, don't guess — and correct your own numbers.** Never give a receding, optimistic
   estimate; measure throughput and quote data-backed figures. When a number you published turns out
   wrong, restate the accurate one and the cause, loudly. *(A migration was first reported as "+1
   workaround"; re-measuring against the whole-tree counter found a second site it had missed and the
   honest figure was +3. State the correction; do not quietly fix it.)*

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
useful if "a hole" has a precise, greppable definition the whole team agrees on.

A hole is a **task, never a hole.** If something genuinely cannot be finished now, it is written as
a tracked, licensed stub that names its follow-up task (e.g. `TODO(JIRA-1234): …` with the ticket
actually filed) — not left as a bare gap the census can't distinguish from an oversight.

---

## 3. Build the quantified tracker (the single source of truth)

A tracker is **code**, and it must behave like code:

1. **Deterministic: a pure function of its inputs.** Run it twice, get byte-identical output — or
   every regeneration produces a spurious diff and reviewers stop reading it. Sort every collection
   with a **total key** (add a unique tiebreaker like the name); never rely on set/hash/dict
   iteration order. *Prove it*: run twice under different hash seeds (`PYTHONHASHSEED`, etc.) and
   diff. The only permitted variation is an explicit timestamp.

2. **Never drop a row in silence.** When the generator *cannot* compute something (a file it failed
   to parse, a missing historical commit), it must say so **in the output**. A silently shortened
   table is indistinguishable from a genuinely shorter one.

3. **Count as a delta from a fixed baseline**, not as an absolute. "235 workarounds" means nothing;
   "+3 vs the pre-migration baseline" is a reviewable fact. Pin a baseline ref and diff against it.

4. **Count at the right granularity — and document the unit.** Decide whether you count per *call*
   or per *occurrence* (e.g. one suppression comment covering five lines: is that 1 or 5?) and write
   it down. **When the unit changes, recompute every historical row under the new rule and never
   quote a delta across the change** — otherwise a pure re-definition reads as a regression. *(One
   project's workaround count jumped 231→590 purely because it switched from counting file-level to
   line-level directives while the actual debt fell; "+359" looked like a 2.5× regression and wasn't.)*

5. **Curated annotations are the human layer — match them robustly.** The scanner produces raw
   counts; a separate, human-curated annotations file records *why each item exists* and *what would
   remove it*. **Match annotations to code by something stable** (declaration/symbol name + basename),
   not by full file path, so they survive file moves and renames. Include a **"resolved" detector**:
   annotations that no longer match any code are surfaced so stale curation gets pruned. *(Keeping
   annotations keyed by exact path once cost a 225-false-"resolved" spike after a big reshape; keying
   the durable layer by symbol/basename avoided it.)*

6. **Emit two artifacts from one run:** a machine-readable summary (counts, trends) and a
   human-readable index. Both regenerated by the same command; neither hand-edited.

---

## 4. Gates — make debt impossible to accumulate silently

1. **Hard gate on holes, enforced three ways:**
   - **Per-merge:** CI fails if the whole-tree hole census is non-zero (or exceeds the licensed set).
     A holed change *compiles and may even pass local tests*, so run the census **first and fast**,
     before the expensive build.
   - **Final whole-tree audit:** on a clean checkout, from scratch, re-run the census — not the
     incremental one, which can mask.
   - **Transitive / honesty sweep** for any external "it's complete" claim: a hole can hide behind a
     dependency. Run whatever deep check your ecosystem offers (dependency-closure scan, coverage
     over the real entry points, `#print axioms`-style introspection) before you tell a stakeholder
     "done."

2. **Debt moves with every PR.** The tracker output *and* the human debt log are updated **in the
   same PR** that changes the debt. Debt counts appear in **every** status report (per-unit rows +
   deltas, not just an aggregate). Never land a change that moves debt without moving its record.

3. **Record deferrals the same day, where the target is written.** If you consciously leave
   something out of a PR, log it in the roadmap/issue tracker immediately. *(69 new warnings once
   went unnoticed for days because every check was "same as the last build" and the baseline already
   contained the regression; the deeper failure was that the deferral was never written down.
   "Same as last time" is not a check when last time was already wrong — account for every warning
   **absolutely**, against a documented target.)*

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

4. **Let the compiler/tests decide, not a heuristic.** The reliable procedure is: remove the
   workaround → rebuild/retest that unit → re-add **only** where the toolchain objects → iterate to
   convergence. A heuristic guess about which sites "probably need" the workaround is both wrong and
   unfalsifiable.

5. **Apply the absorber test — the subtle one.** A workaround that still compiles after you delete it
   is **not necessarily removed**: its work may have moved somewhere invisible (a later tactic/cast/
   default now does it; a different suppression now covers it). *That hides the debt, it does not
   remove it.* A removal counts **only** if nothing new had to be added to compensate. If deleting it
   would require any repair — a new cast, a restated helper, a type ascription — the debt **stays**.
   *(Under this standard, one project rejected 65 of 121 candidates that all compiled green.)*

6. **Verify cold, then record.** Final verification is a clean-from-scratch build, never incremental.
   Then update the ledger, regenerate the tracker, and log the round (what moved, by how much, why)
   in the human debt log.

---

## 6. Safety rules for bulk / mechanical edits

Every rule here was paid for with a real incident.

1. **Never write a text transform whose output feeds its own input condition.** Iterate over a
   **frozen copy**; evaluate every condition against the *original* text. *(A "comment-fixing" pass
   that read its own just-written output cascaded and commented out ~7,300 lines across 150 files —
   on uncommitted work.)*

2. **Snapshot before any bulk rewrite**, and before discarding any tree that holds uncommitted work.
   The pre-change VCS state is your oracle for recovery.

3. **A "tidy" transform is a semantic transform until proven otherwise.** Deduping, reordering, and
   reformatting can change behaviour (collapsing `rewrite [h, h]` → `[h]` changes what runs;
   reordering imports with side effects changes load order). Only provably idempotent operations are
   safe to batch. *(A blanket "remove consecutive duplicate tokens" pass broke 28 proofs.)* For a
   **handful of known sites, edit them individually** — don't reach for a repo-wide transform.

4. **Anchor patterns on the construct/token itself, never on a line number or a positional walk.**
   Code repeats shapes, so a position derived from an error line is not an identity. *(A repair that
   walked back from each error line to "the nearest match" landed on a *different*, working
   construct and turned 1 error into 8.)*

5. **When reverting a bulk edit, align by position / diff against the baseline — not by content.**
   Content matching silently conflates identical lines elsewhere in the file and turns a small
   problem into a long hunt.

6. **Scanners reason about tokens, not lines, and mask comments/strings first** — with the repo's
   *shared* masker, not a scratch regex. *(A sweep counted four docstring lines beginning with the
   word "change" as live tactics and proposed deleting documentation.)*

7. **Validate the tool on one case — including one it must reject — before running it on hundreds.**
   Any code that parses source structure first passes a known-nasty sample (a comment that looks like
   code, a docstring ending in a code-like token, a header before the imports, one input it *must*
   reject). *(A harness that counted errors by matching old-style `error:` text silently scored
   genuinely-broken variants as "identical to baseline" because the new diagnostics carried an error
   *code* it didn't match.)*

8. **On a high failure rate, suspect the tool before the material.** Inspect two or three "hard
   cases" by hand before theorising about why they're hard. *(25 of 36 "hard mathematical cases" were
   one off-by-one bug in an insertion walker.)*

9. **Put the guard in the tool, at the line it governs — knowledge filed elsewhere does not fire.**
   A trap written up in a design doc won't save you while you're writing the parser; encode it as a
   guard in the parser, with a comment citing the rule. **Copying a walker counts as writing one** —
   re-check it against the trap list. *(The same docstring-boundary trap recurred three times, each
   in freshly-written or freshly-copied tooling, because the write-up lived where it didn't fire.)*

---

## 7. Verification discipline

1. **Run any check with the real build/CI configuration, explicitly.** A per-file probe that uses
   different options than the full build (different lint set, different optimisation, different
   synth/resolution settings) proves nothing about CI. Mirror the real config, or you'll accept
   removals that CI rejects. *(A probe ran with the linters off and the wrong synth depth; it
   accepted 101 removals, and the real build then failed.)*

2. **Judge by observable behaviour / exported API, not by exit code alone.** A unit can compile while
   its *exported signature* (public type, generated code, serialized schema, API shape) silently
   changed and only a downstream consumer notices. Hash/snapshot the exported surface before and
   after; reject a change that moves it even if the build is green.

3. **Read the log / the real exit status, never a wrapper's.** `build > log 2>&1; echo "EXIT=$?"`
   reports the exit code of `echo`, not the build. Check the actual tool's status and grep the log for
   the success/failure line.

4. **A destructive step must verify its own effect** before anything downstream claims success. *(A
   "wipe the build cache" command ran from the wrong directory, deleted nothing, and the following
   "clean" build was silently incremental.)* Count what you deleted; confirm the directory is gone.

5. **Count diagnostics robustly; validate every harness on a known-bad input.** Prefer structured
   output (`--json`, severity fields) over text matching. A twenty-line scoring script deserves the
   same "show it one input it must fail" check as a real tool.

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
   differing configs/manifests.** *(A scratch worktree that symlinked a shared dependency cache under
   a different manifest rebuilt ~550 modules over the owner's cache.)* Clones get their own cache.

3. **A cleanliness claim names exactly one tree.** `git -C <that-tree> status --short` — don't
   attribute a concatenated status covering two trees to one of them.

4. **Match processes by the binary's full path, never by a substring that also appears in the
   command doing the matching** — or your `pkill` matches your own shell.

---

## 9. When a migration or upgrade surfaces a *class* of breakage

Large mechanical migrations (a framework upgrade, a language-mode switch, an API sweep) tend to
produce a handful of recurring breakage *patterns* rather than N unique bugs. Treat them as a set:

1. **Taxonomise the classes, and give each a mechanical fix recipe.** Document "Class A: symptom →
   fix", "Class B: …" in the debt log, with counts (files/sites affected). This turns a scary error
   wall into a checklist and makes any re-run of the migration cheap. *(One migration's breakage
   collapsed into six classes, each with a one-line fix; most files needed no hand-editing at all.)*

2. **No blanket switch fixes a class for free — pin each site that genuinely needs it individually,**
   and leave the rest clean. A global suppression to "make it build" just converts one debt class
   into another.

3. **Track the net debt delta honestly**, separating *mechanical-baseline* work (in scope) from any
   *deferred narrowing/tightening* (explicitly out of scope, logged as a follow-up). Report the real
   number even when it's worse than your first estimate (see §1.6).

---

## 10. Reporting & collaboration discipline

- **Per-unit rows and deltas, not aggregate summaries.** "Module X: 12→9 (−3)" beats "debt down ~20%".
- **Finish diagnostics with a fix.** A probe ends in a repair and a resume, not a findings list.
- **Opinion before acting on design/policy.** When asked to make a judgement call (a tracker design,
  a gate policy), say *agree/disagree and why* before building it. Operational repairs stay
  act-then-report.
- **Honesty over optimism.** State absolute numbers and their causes; correct understatements out
  loud; never present an approximation as a measurement.

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
8. **Do one real cleanup round** end to end (§5) to validate the whole loop before scaling it.

---

## Appendix — the anti-pattern catalog (one line each)

| # | Failure | Rule |
|---|---|---|
| 1 | Transform read its own output → cascading corruption | Iterate over a frozen copy; evaluate against the original (§6.1) |
| 2 | Blamed the material for a tool bug | High failure rate → suspect the tool first (§6.8) |
| 3 | Regex anchored on the wrong delimiter → dangling refs | Anchor on the token; have prose-aware review (§6.4) |
| 4/13 | Scheduled report never fired | An armed schedule ≠ a working one; confirm the first tick; push don't poll (§7.6) |
| 5 | Wrapper reported success over a failed build | Read the log / real exit status (§7.3) |
| 6 | Hand-copied a generated number → drift | One source of truth; derive, don't store (§1.4) |
| 7 | Generator not deterministic → spurious diffs | Total sort keys; prove under varied hash seeds (§3.1) |
| 8/14 | Re-made a documented trap in fresh/copied tooling | Guard in the tool, at the line; copying = writing (§6.9) |
| 9 | "Tidy" dedupe changed semantics | Tidy is semantic until proven; revert by position (§6.3, §6.5) |
| 10 | Per-file check used a different config than the build | Real config + exported-signature check + self-verifying destructive steps (§7.1, §7.2, §7.4) |
| 11 | Harness regex couldn't see coded errors | Count by structured severity; validate on known-bad input (§7.5) |
| 12 | Delegated agents ran in the owner's tree | Isolate in a clone; absolute paths; one-tree cleanliness claims (§8) |
| 15 | Sweep counted docstring prose as code | Scanners mask comments and reason about tokens (§6.6) |
| 16 | Warnings hidden by baseline-relative checks | Account for warnings absolutely; record deferrals the same day (§4.3) |
| 17 | Wrong rule fanned out to N agents → N identical breakages | Check every rule against the compiler + precedent before fan-out (§6.7) |
| 18 | Repair anchored on the error line | Anchor on the construct; revert by diff against baseline (§6.4, §6.5) |
| 19 | Shared dependency cache overwritten across manifests | Clones get their own cache; never move the owner's tree (§8.2) |

---

*The throughline: debt management is an **instrumentation** problem before it is a **cleanup**
problem. Build the honest instrument first; the cleanup becomes a ranked, reviewable, reversible
sequence of small verified steps — and every number you report can be trusted because it was
measured, not remembered.*
