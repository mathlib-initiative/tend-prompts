# lean-formalization

Prompts for formalizing a mathematical text — a book or a long paper — in
Lean 4 with Mathlib, **blueprint-first**: a contribution lands faithful
definitions and theorem statements that compile and have been checked against
the source, proves what today's Mathlib supports, and records every remaining
gap as a tracked `sorry`. The reviewer's single job is semantic: does the Lean
say what the source says. Everything mechanical (build, debt accounting) is
left to the repository's validation gate, which runs before the reviewer is
called.

The suite was extracted from the prompts used to formalize Cieliebak and
Eliashberg's *From Stein to Weinstein and Back* (September 2026; see
Evaluation). Project-specific values are marked `<<LIKE_THIS>>` and must be
replaced before use; Tend does not expand them.

## Purpose

Use this suite when:

- there is a fixed source text whose numbered items (definitions, theorems,
  equations) are the units of work, and the source can be placed in the
  worktree so that worker and reviewer read the same words;
- faithfulness matters more than proof completeness — the output is a
  blueprint whose open proofs are explicit, justified and reviewable;
- Mathlib is the foundation, and part of the value is a precise record of what
  Mathlib lacks.

A different suite is more appropriate for proving a fixed list of statements
that are already formalized (there the reviewer's job is the proof, not the
statement), for library engineering without a source text, or for projects
whose success criterion is "no `sorry`".

## Assumptions and configuration

- Status: experimental. The original prompts ran on a real project (below); the
  extracted, placeholder-bearing suite has not itself been run.
- Runner: Tend's generated `--agent tend` scripts.
- Repository/task assumptions. The prompts expect, in the target repository:
  - `AGENTS.md` at the root: the working agreement (layout, build commands,
    citation convention, `sorry` policy). The prompts defer to it so that
    policy can change without editing prompts.
  - The source text extracted into `<<REFERENCE_DIR>>`, sliced per section,
    with each task naming the slice it owns. In the original project this
    directory is gitignored (the source is not under the project's licence)
    and reaches worktrees through Tend's workspace mirror.
  - One Lean module per source section, pre-created as a stub before tasks are
    dispatched, so that no two workers edit a shared import list; a Lake glob
    (`globs = ["<Lib>.+"]`) so new modules build without touching a root file.
  - `SORRY_ALLOWLIST.txt` with a per-file budget and
    `scripts/check_sorry_allowlist.py --fix` to regenerate it.
  - `scripts/validate.sh`: `lake build` plus the allowlist check, configured as
    Tend's pre-review and pre-merge validation command. The original project
    added a semantic debt gate (aftk's `tech-debt` scan: no `axiom`, heartbeat
    overrides, `erw`, `native_decide`, deprecated lemmas); the prompts mention
    such a gate conditionally.
  - Task YAML naming the source slice, the module to fill, and a definition of
    done. Task ids may differ from filenames; the prompts resolve by id.
  - A docstring convention: every declaration cites its source item
    (`<<CITE_PREFIX>> Theorem 3.1`), and every departure from the source is a
    `Deviation:` line.
- Required tools: `lake`, `python3`, `git`. Optional: aftk
  (`lake exe aftk diagnostics | goals | probe | deps | rdeps`) for a warm Lean
  worker and declaration-level dependency queries; if present, document the
  commands in `AGENTS.md`, which is where the prompts send the agents.
- Model or runtime requirements: used with a frontier model for workers and a
  mid-tier model for reviewers (below). Workers need a large per-response
  output budget — one proof-planning turn exceeded 65k reasoning tokens — and
  a model timeout of at least 30 minutes without streaming. The `bash` tool's
  600-second cap is assumed in the prompts; `lake build` of a single module
  fits, a full project build does not.
- Tend compatibility: actual worker and reviewer runs with Tend at commit
  `fad93f6e65048852501a53767a7e82f61e70abc9` (2026-09-29/30) and at an earlier
  September 2026 commit (2026-09-18/22), both with the generated `--agent tend`
  launchers and the `final_result` contracts described in this repository's
  README. The environment-variable and discussion-path conventions of this
  repository's README were applied during extraction (the originals assumed
  `tasks/$TEND_TASK_ID.yaml` and `.tend/discussion.md`).

### Placeholders

| Placeholder | Meaning | Value in the original project |
| --- | --- | --- |
| `<<SOURCE_CITATION>>` | The text being formalized, as a citation | Cieliebak & Eliashberg, *From Stein to Weinstein and Back: Symplectic Geometry of Affine Complex Manifolds* (AMS Colloquium Publications 59, 2012) |
| `<<REFERENCE_DIR>>` | Where the extracted, per-section source text lives in the worktree | `reference/sections/` |
| `<<CITE_PREFIX>>` | The prefix of the citation convention in docstrings | `CE` (as in `CE Theorem 3.1`, `CE (2.1)`, `CE p. 27`) |
| `<<MISSING_THEORIES>>` | What Mathlib lacks for this source, so workers define it rather than search for it | contact geometry, Liouville fields, h-principles, Stein manifolds or symplectic homology |
| `<<EXAMPLE_MODULE>>` | A real module name, for the single-module build command | `CE2012.Chapter02.S01LinearAlgebra` |

## Prompts

- [Worker system](prompts/worker-system.md)
- [Worker assignment](prompts/worker.md)
- [Worker revision](prompts/worker-revision.md)
- [Reviewer system](prompts/reviewer-system.md)
- [Review task](prompts/reviewer.md)

Install the five files into an initialized run's `prompts/` directory after
replacing the placeholders. See the repository README for the copy procedure.

### What the prompts encode, briefly

- Faithfulness over throughput; the explicit warning that a vacuous definition
  or a theorem with contradictory hypotheses passes every automated check.
- Read the whole source slice first; search Mathlib before defining; cite every
  declaration; declare every deviation.
- Open proofs are allowed, silent ones are not: keep the `sorry`, register it,
  justify it. Never fix a build by weakening, deleting, adding an `axiom` or
  using `native_decide`. `blocked` with a precise account of the gap is a
  valid, valued outcome.
- The reviewer is told that the build already passed and therefore tells it
  nothing; its checklist is hypotheses, conclusion, vacuity, deviations,
  debt justification, and conditional theorems (complete proofs resting on an
  open statement). `request_changes` is cheap and for mathematics only.
- Revision: engage with the mathematics, not the symptom; never delete a
  statement to satisfy a reviewer; disagree explicitly with source text when
  the reviewer is wrong.

## Evaluation and provenance

Derived from the prompts of the CE2012 project (the formalization of Cieliebak
and Eliashberg's book by a Tend swarm, `mathlib-initiative/stein-weinstein`),
written by the project's operator in September 2026. No third-party prompt text
is included. Changes made during extraction, beyond placeholders: Tend's
environment-variable and discussion-path conventions; a hard-coded scope
("chapters 2–5") removed; project-specific aftk commands replaced by a pointer
to `AGENTS.md` and a generic dependency check; three additions that respond to
observations below and have **not** been run — the worker must exhibit a
witness for every new definition and must declare conditional theorems in
their docstrings, the worker must quote only the statement being formalized
(the original project accumulated ~10% of the source text in docstrings before
trimming), and the reviewer is asked to write down one way the statement could
be weaker than the source before approving.

Evidence from the original project (the originals, not this extraction):

- Dates and runs: five Tend runs between 2026-09-18 and 2026-09-30, about 27
  hours of orchestrator wall time, 3–6 workers and 2–3 reviewers in parallel.
- Task set: 166 tasks — one per source section for 11 chapters and 2
  appendices, a planning task per later chapter, a roll-up task per chapter
  and part; 131 completed.
- Models and settings: workers `claude-opus-5`, reviewers `claude-sonnet-5`,
  reasoning effort high, worker output cap raised to 128k tokens after two
  failures at 32k and 64k; total API cost about USD 1,700.
- Validation: `lake build` + `sorry` allowlist before review and before merge
  on every contribution; from 2026-09-30 also an elaborator-level debt gate.
- Results: 104 Lean modules with content (~110,000 lines, ~6,000
  declarations); 598 declarations named after a numbered source item, of which
  156 proved, 33 proved from a statement still open, 409 stated with an open
  proof; 588 tracked `sorry`s, each with a per-file rationale; no `axiom`,
  `native_decide` or heartbeat override anywhere; 42 errors in the printed
  source found and recorded with corrected statements.
- Review: 236 reviews of 133 contributions, 230 `approve`, 6
  `request_changes`.

Observations that bear on the prompts:

- The high approval rate is a warning sign, not a success metric. The
  semantic defects that were found — a definition unsatisfiable in exactly the
  case the source cares about, 93 complete proofs that silently depended on an
  open statement, a model set that was a cylinder where the source means a
  half-disc — were found by cross-cutting roll-up tasks and operator audits,
  not by per-contribution review. A reviewer with a smaller, adversarial job
  may do better than one walking a checklist; this suite only begins to move
  in that direction.
- The source text in every worktree and a citation on every declaration are
  what made review possible at all, and are also why so many errata were found.
- Prompts that hard-code scope rot: the original worker prompt still said
  "chapters 2–5" when chapter 11 landed. Put scope in the task YAML and policy
  in `AGENTS.md`.
- Mathlib's reach, not the prompts, determined what got proved: sections close
  to Mathlib (linear algebra, one-variable analysis, local estimates) were
  proved almost entirely; sections quoting theorems Mathlib lacks (h-principles,
  Morse theory, flows) became statements. Measure success against that.

No evaluation of this extracted suite has been recorded.
