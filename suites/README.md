# Suite catalogue

| Suite | Purpose | Status | Runner |
| --- | --- | --- | --- |
| [lean-formalization](lean-formalization/README.md) | Blueprint-first formalization of a mathematical text (a book or paper) in Lean 4 / Mathlib: one source section per task, every statement checked against the extracted source by an independent reviewer, every open proof tracked in a per-file `sorry` allowlist. | experimental | `--agent tend` |
| [mathlib-infrastructure](mathlib-infrastructure/README.md) | Library engineering above Mathlib against a written plan: spec tasks fix statements with mandatory examples, prove tasks close proofs with statements frozen; the reviewer compares with the plan and hunts vacuity; workers can ask another agent or the human operator through a question channel, and propose refactors of foundations. Written to be upstreamed. | experimental (two runs recorded) | `--agent tend` |
| [mixed-book-and-infrastructure](mixed-book-and-infrastructure/README.md) | One prompt set for a task graph that mixes `infra-*` library tasks with source-text section tasks formalized against that library; routes by task id to the rules of `mathlib-infrastructure` or `lean-formalization`, and forbids section modules to redefine library notions. | experimental (one run recorded) | `--agent tend` |

Link each suite name to its README. Use `draft` for suites under development,
`experimental` for suites being tried on tasks, and `maintained` for suites with
documented evaluation evidence and ongoing upkeep. Status is a description of
maturity, not a guarantee of quality. The suite README records compatibility,
limitations, and evidence.
