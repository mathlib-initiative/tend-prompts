# mixed-book-and-infrastructure

One prompt set for a Tend run whose task graph mixes **infrastructure tasks**
(library engineering against a plan, task ids `infra-*`) and **book tasks** (a
faithful formalization of a source text against that library, task ids such as
`ch02-s03`, chapter roll-ups `ch02`, a whole-book roll-up `book`). Tend runs
one prompt set per root, so a project that wants both kinds of work in one run
needs prompts that route by task kind. Each prompt here is the
`mathlib-infrastructure` prompt as Part I and the `lean-formalization` prompt
as Part II, under a router paragraph that selects the part by task id. The
parts share the channels for asking for help, the `sorry` policy, the shell
rules and the mechanics, stated once in Part I.

Project-specific values are marked `<<LIKE_THIS>>` and must be replaced before
use; Tend does not expand them.

## Purpose

Use this suite when a project has built (or is still building) shared
infrastructure above Mathlib and now formalizes a source text *against* it, in
the same run: library tasks keep the `mathlib-infrastructure` rules (spec and
prove, examples, Mathlib style, the plan as the specification), section tasks
keep the `lean-formalization` rules (the source slice is the specification,
every statement cited, every deviation declared), and one rule is added for
the section tasks: **the library is the vocabulary**. A section module never
defines a notion the library or Mathlib has; it identifies the book's
definition with the library's object (an `abbrev`, an `example`, a lemma that
the two agree), states the book's theorems about that object and proves them
from the library's results, and where the library is more general it states
the book's version as the special case. A redefinition is a reviewer finding.

Use one of the parent suites instead when the run has only one kind of task.

## Assumptions and configuration

- Status: experimental. Written 2026-11-08 for phase 5 of the Kock2003 project
  and run on it 2026-11-09 to 2026-11-17 (see Evaluation).
- Runner: Tend's generated `--agent tend` scripts.
- Repository assumptions: everything both parent READMEs assume. In addition,
  the task ids must make the kind recognisable (`infra-` prefix for library
  tasks; anything else is a book task), the infrastructure must be documented
  (a status document saying module by module what is proved and what is open,
  which the section tasks are sent to), and each section task must name the
  library modules it is to import and cite.
- Tend behaviour relied on: as for `mathlib-infrastructure`, including the
  parking rule for questions (a task gated on an operator answer adds the
  `ask-*` task to its `depends_on` and returns `blocked`).
- Required tools and model requirements: as for the parent suites; a frontier
  model for both roles.

### Placeholders

Those of both parents. `<<MISSING_THEORIES>>` of `lean-formalization` is not
used: the prompt points the book worker at the library instead.

| Placeholder | Meaning | Value in the original project |
| --- | --- | --- |
| `<<PLAN_PATH>>` | The plan the library tasks implement | `docs/infrastructure-plan.md` |
| `<<INVENTORY_DIR>>` | Verified Mathlib inventories, per chapter | `docs/planning/` |
| `<<INFRA_DIR>>` | Where the library modules live | `Kock2003/Infrastructure/` |
| `<<EXAMPLE_MODULE>>` | A real module name, for the single-module build command | `Kock2003.Infrastructure.LinearAlgebra.Pairing` |
| `<<SOURCE_CITATION>>` | The text being formalized, as a citation | Kock, *Frobenius Algebras and 2D Topological Quantum Field Theories* (LMS Student Texts 59, 2003) |
| `<<REFERENCE_DIR>>` | The extracted, per-section source text in the worktree | `reference/sections/` |
| `<<CITE_PREFIX>>` | The prefix of the citation convention in docstrings | `Kock` |

## Prompts

- [Worker system](prompts/worker-system.md)
- [Worker assignment](prompts/worker.md)
- [Worker revision](prompts/worker-revision.md)
- [Reviewer system](prompts/reviewer-system.md)
- [Review task](prompts/reviewer.md)

Install the five files into an initialized run's `prompts/` directory after
replacing the placeholders. See the repository README for the copy procedure.

## Evaluation and provenance

Composed from the two parent suites of this repository by the Kock2003
operator session on 2026-11-08; the router paragraphs, the "library is the
vocabulary" rule and the book-task bullets of the revision and review prompts
are the only new text. No third-party prompt text is included.

### Run: Kock2003 phase 5 (2026-11-09 07:30Z to 2026-11-17)

- Suite as in this commit (one stale sentence of the book worker prompt, a
  pointer to a survey file the project never had, was fixed afterwards).
  Placeholders as in the table. Tend commit `fad93f6`, Anthropic
  `claude-opus-5-5` for both roles, 8 workers / 3 reviewers, the validation
  gate of the parent suites' READMEs.
- Task set: 27 planned tasks (14 section tasks, the appendix, three small
  library additions, three chapter roll-ups and a book roll-up behind an
  operator sentinel, and a six-task library program on compact 1-manifolds),
  plus 7 tasks the agents spawned themselves (helper and library tasks, among
  them the Koszul sign symmetry on graded objects, which three sections
  needed and neither Mathlib nor the library had). All complete except the
  renaming task the operator added at the end. About 395 USD by 2026-11-17.
- Results: all 17 sections and the appendix formalized against the library
  (21 book modules, about 21 000 lines; the library grew to 89 modules, about
  48 900 lines, including the proved classification of compact 1-manifolds and
  the connectedness of the orientation-preserving diffeomorphisms of the
  circle); chapters 2 and 3 and the appendix with no open proof; 31 open
  proofs in all, every one in the chapter-1 geometry the project had deferred
  (gluing and collars, the seven relations as explicit gluings, the comparison
  of the smooth and presented cobordism categories); 515 alignment rows in the
  project's `formalization.yaml`, one per numbered item and exercise. Three
  operator questions (a linter conflict with the project's namespace
  convention; a false clause in a merged statement caused by `inferInstance`
  under an existential binder, which the agent corrected and reported; whether
  to add the Koszul symmetry to the library in general form). Reviewers
  requested changes on statements that did not match the source, including
  one wrong "blocked by" claim in a roll-up.
- Flaw observed: the book roll-up, forbidden to complete while questions were
  open, returned with the task left open and was relaunched after every merge,
  15 times, until the operator paused; the parking rule above is the fix.
