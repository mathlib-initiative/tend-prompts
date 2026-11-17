# mathlib-infrastructure

Prompts for building Lean 4 / Mathlib **library infrastructure** with Tend:
definitions and theorems that Mathlib lacks and that a formalization project
needs, written to Mathlib's standards so that they can be upstreamed. The
source of truth for the agents is not a book but a *plan*: a document that
lists the modules to build, their contents, their generality and their design
decisions, together with a verified inventory of what Mathlib already has.

This suite is the companion of `lean-formalization`, which formalizes a source
text section by section and sends every statement to a reviewer that compares
it with the text. Here the reviewer compares statements with the plan and with
the mathematics, hunts for vacuity, and checks Mathlib style; and the work is
split into *spec* tasks (fix the statements, with examples) and *prove* tasks
(close the proofs without touching the statements).

Project-specific values are marked `<<LIKE_THIS>>` and must be replaced before
use; Tend does not expand them.

## Purpose

Use this suite when:

- a project has decided to build shared infrastructure above Mathlib before,
  or instead of, formalizing a text against ad hoc definitions;
- there is a written plan that fixes, module by module, what to build, in
  what generality, and why, and an inventory of Mathlib names checked against
  the pinned Mathlib;
- upstreaming is a goal, so Mathlib style and generality are requirements and
  not preferences;
- the operator wants agents to **ask** rather than guess: the suite gives
  workers a channel to other agents (through the reviewer and through helper
  tasks) and a channel to a human (question files plus a parked task), and it
  tells them that proposing a refactor of a foundation is expected when the
  evidence warrants it.

## Assumptions and configuration

- Status: experimental. Written 2026-11-06 for the Kock2003 project
  (Frobenius algebras and 2D TQFTs above Mathlib) and run on it twice: as is
  for the infrastructure campaign (2026-11-06/07) and as Part I of
  `mixed-book-and-infrastructure` for the book phase (2026-11-09/17). See
  Evaluation.
- Runner: Tend's generated `--agent tend` scripts.
- Repository assumptions. The prompts expect, in the target repository:
  - `AGENTS.md` with the working agreement, including: the build and
    validation commands, the `sorry` allowlist policy, the warm-Lean-worker
    and dependency tooling (the prompts defer to it by saying "the tool
    `AGENTS.md` names"), the **question channel** (a `docs/questions/`
    directory with a template, a sentinel task `operator` that is never ready,
    and a task template for `ask-*` tasks that depend on it), and the
    **proposal channel** (`docs/proposals/`).
  - The plan at `<<PLAN_PATH>>`, with one entry (a table row) per module
    giving its content, size, dependencies and the design decisions it falls
    under; tasks name the entry they implement.
  - The inventory directory `<<INVENTORY_DIR>>` with verified Mathlib names.
  - Infrastructure modules under `<<INFRA_DIR>>`.
  - `SORRY_ALLOWLIST.txt` with `scripts/check_sorry_allowlist.py --fix`, and
    `scripts/validate.sh` as Tend's validation command (build, allowlist, a
    debt gate that rejects `axiom`, heartbeat overrides, `erw`,
    `native_decide`, deprecated lemmas).
  - Tasks of three kinds, named in the task YAML: `spec`, `prove`, or single.
- Tend behaviour the suite relies on (checked against Tend `fad93f6`,
  `src/tend/orchestrator/orchestrator.py`): a `blocked` worker result with
  committed task-graph edits goes through review and merge and leaves the task
  open, so a task that adds a dependency on a parked `ask-*` task is
  rescheduled when the operator clears it; a `blocked` result with nothing
  committed closes the worktree for a fresh respawn; a blocked contribution
  that touched non-task files makes the orchestrator tell the reviewer to
  request changes "unless these non-task edits are intentionally allowed by a
  newer contract" — this suite's contract allows `docs/questions/`,
  `docs/proposals/` and compiling checkpointed Lean. `needs_review` goes to
  the reviewer like `completed`, which is what makes the reviewer usable as
  the agent a worker can ask.
- Required tools: `lake`, `python3`, `git`; aftk or equivalent for the warm
  worker and the dependency queries, documented in `AGENTS.md`.
- Model or runtime requirements: a frontier model for both roles (the
  reviewer's vacuity hunting is the quality control); a large per-response
  output budget and a model timeout of at least 30 minutes without streaming;
  the `bash` tool's 600-second cap is assumed.

### Placeholders

| Placeholder | Meaning | Value in the original project |
| --- | --- | --- |
| `<<PLAN_PATH>>` | The plan the tasks implement | `docs/infrastructure-plan.md` |
| `<<INVENTORY_DIR>>` | Verified Mathlib inventories | `docs/planning/` |
| `<<INFRA_DIR>>` | Where the infrastructure modules live | `Kock2003/Infrastructure/` |
| `<<EXAMPLE_MODULE>>` | A real module name, for the single-module build command | `Kock2003.Infrastructure.LinearAlgebra.Pairing` |

## Prompts

- [Worker system](prompts/worker-system.md)
- [Worker assignment](prompts/worker.md)
- [Worker revision](prompts/worker-revision.md)
- [Reviewer system](prompts/reviewer-system.md)
- [Review task](prompts/reviewer.md)

Install the five files into an initialized run's `prompts/` directory after
replacing the placeholders. See the repository README for the copy procedure.

### What the prompts encode, briefly

- Statements first: spec tasks fix definitions and theorem statements, with
  examples, before proof effort is spent; prove tasks close proofs with the
  statements frozen.
- Non-vacuity as a deliverable: every new structure needs a non-degenerate
  instance in the file, every non-obvious theorem an `example` witnessing its
  hypotheses, listed non-examples a proof of failure; the reviewer must write
  down one way each declaration could be vacuous and why it is not.
- Mathlib style and generality as requirements, because the output is meant
  to be upstreamed; no project citations in declaration docstrings.
- Asking is expected: `needs_review` with questions for another agent; helper
  tasks for delegated work; question files plus a parked `ask-*` task for the
  operator; proceed under a recorded `ASSUMPTION:` when possible.
- Proposing refactors of foundations is expected when warranted: a proposal
  file with evidence, blast radius and migration, routed to the operator;
  merged statements change only through an accepted proposal.
- Open proofs are allowed and tracked; silent weakening, deletion, `axiom`
  and `native_decide` are not.
- The quality indicators of RemyDegenne/lean-quality-indicators (unnecessary
  hypotheses, Mathlib duplicates, definition fidelity, statement generality,
  vacuity, repeated machinery, proof simplification, explicit unfoldings) are
  acceptance criteria for the worker and a checklist for the reviewer; the
  target repository is expected to gate the mechanical ones (linter warnings,
  `runLinter`) and to list the rest in `AGENTS.md`.

## Evaluation and provenance

Derived from the `lean-formalization` suite of this repository (itself
extracted from the CE2012 project's prompts) by the Kock2003 project's
operator session on 2026-11-06: the source-text comparison was replaced by
comparison with a plan, the spec/prove split, the examples and vacuity
requirements, the question and proposal channels and the blocked-contract
extension were added. No third-party prompt text is included.

### Run 1: the Kock2003 infrastructure campaign (2026-11-06 to 2026-11-07)

- Suite as in commit `ac31648` of this repository, placeholders filled as in the
  table above. Tend commit `fad93f6`, `--agent tend` launchers, Anthropic
  `claude-opus-5-5` for both roles (reasoning effort high, forced tool choice
  disabled), 8 workers / 3 reviewers, validation `bash scripts/validate.sh`
  (build, `sorry` allowlist, aftk debt gate, Mathlib linter gate), full gate
  before merge.
- Task set: 53 tasks against a plan of three layers (algebra of Frobenius
  algebras and pairings; monoidal categories, a generic presentation engine,
  Frobenius objects, the simplex categories, the presented and combinatorial
  `2Cob`, the universal properties and the main theorem; the smooth cobordism
  interface), as spec/prove pairs with roll-ups; 54 worktrees; about 9 hours;
  496 USD.
- Results: 68 modules, about 37 700 lines, 714 definitions, 353 examples; the
  main theorem (2-dimensional TQFTs ≌ commutative Frobenius algebras) proved
  with no open input for the presented and the combinatorial `2Cob`, which
  were proved equivalent; 25 open proofs, all in the smooth cobordism
  interface, where the plan had asked for statements only. Axioms checked.
- The channels were used as intended. Two operator questions: one chose
  namespaces; the other reported that the plan's statement "for every braided
  category" of the book's 3.6.19 is false (a reviewer supplied the
  counterexample, a Lagrangian algebra in a Drinfeld centre) and proposed the
  true restricted form, which the operator kept. Two proposals, both accepted:
  one replaced two false lemmas about disjoint unions of smooth embeddings by
  proved finite-dimensional versions, the other corrected the plan's
  description of the combinatorial `2Cob` (partitions cannot record closed
  components). Spec tasks that left nothing open retired their prove twins
  after the rule was added mid-run.
- Flaws found and fixed in the target project's `AGENTS.md`: (1) the sentinel
  task was reachable: it depended on the campaign-final roll-up, which an agent
  completed while two `ask-*` tasks were still parked, so the sentinel was
  completed too and the parked tasks were launched in a respawn loop until the
  operator paused; (2) spec tasks that closed every proof left redundant prove
  twins. Neither flaw is in the prompts themselves, but the suite now says
  what to do (below).

### Run 2: Part I of `mixed-book-and-infrastructure` (2026-11-09 to 2026-11-17)

The `infra-*` tasks of the Kock2003 book phase ran under this suite's rules
through the mixed suite: 9 planned infrastructure tasks (the classification of
compact 1-manifolds, the connectedness of `Diff⁺(S¹)`, small additions) and 6
more that agents spawned themselves as helper or library tasks (isotopy of
cylinders, universe lifts, a parity lemma, the Koszul sign symmetry on graded
objects, a copairing API). All completed; the 1-manifold classification is
proved. See the mixed suite's README for the whole run.

### What the runs taught about parking questions

A task that cannot complete until the operator answers (a campaign-final
roll-up, typically) must **add the open `ask-*` tasks to its own `depends_on`
and return `blocked`**. Returning `needs_review` or `completed` with the task
left open leaves it *ready*, and Tend relaunches it after every merge: in run 2
the book roll-up was relaunched 15 times while three questions were open (each
round closed another proof, so the spend was not wasted, but it was
unbounded) until the operator paused. The worker system prompt now says so.
