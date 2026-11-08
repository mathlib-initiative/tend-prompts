# mixed-book-and-infrastructure

One prompt set for a Tend run whose task graph mixes **infrastructure tasks**
(library engineering against a plan, task ids `infra-*`) and **book tasks** (a
faithful formalization of a source text against that library, task ids such as
`ch02-s03`). Tend runs one prompt set per root, so a project that wants both
kinds of work in one run needs prompts that route by task kind; this suite is
the composition of `mathlib-infrastructure` (Part I of each prompt) and
`lean-formalization` (Part II), with a router paragraph on top and one new rule
for book tasks: the library is the vocabulary and is never redefined in a
section module.

Status: experimental, written 2026-11-08 for phase 5 of the Kock2003 project;
not yet run. Placeholders: those of both parent suites
(`<<PLAN_PATH>>`, `<<INVENTORY_DIR>>`, `<<INFRA_DIR>>`, `<<EXAMPLE_MODULE>>`,
`<<SOURCE_CITATION>>`, `<<REFERENCE_DIR>>`, `<<CITE_PREFIX>>`); the
`<<MISSING_THEORIES>>` placeholder of `lean-formalization` is replaced by a
pointer to the library. Everything the parent READMEs assume of the repository
applies.
