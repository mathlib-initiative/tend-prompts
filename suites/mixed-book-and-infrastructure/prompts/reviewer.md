Resolve `TEND_TASK_ID`, `TEND_WORKTREE_ID` and `TEND_WORKTREE_PATH` from the environment and find the task YAML under `tasks/` whose `id` matches `TEND_TASK_ID`. If the id begins with `infra-`, follow **A**; otherwise **B**.

## A. Infrastructure task

Work in this order:

1. Read the task file to see what was asked (spec, prove, or single task), the plan entry it names in `<<PLAN_PATH>>`, and the discussion at `TEND_AGENT_DISCUSSION_PATH` for anything already said about this contribution, including questions the worker asked.
2. `git diff main...HEAD` to see exactly what changed. In a prove task, extract the statements of every declaration that existed on `main` and check they are unchanged.
3. For every declaration added or changed, compare it with the plan entry and with the mathematics: the right notion, the right generality, the strong form of the conclusion. For every new structure or class, find the simplest object satisfying it and the examples in the file; for every theorem, find the example witnessing its hypotheses. Write down, per declaration, one way it could be vacuous or weaker than intended and why it is not. This is the review; everything else is secondary. The build already passed, so it tells you nothing.
4. Check reuse against Mathlib (the inventory rows in `<<INVENTORY_DIR>>`, `grep -r .lake/packages/mathlib/Mathlib/`) and against the sibling modules under `<<INFRA_DIR>>`; check for instance diamonds.
5. Check Mathlib style: names, typeclass assumptions, `simp` attributes, docstrings, placement of auxiliary lemmas, absence of project-specific citations in declaration docstrings. Then the quality-indicator questions of `AGENTS.md`: deletable hypotheses, Mathlib duplicates, docstring versus definition and its generality, repeated machinery, proof simplification, definitions of other modules unfolded by name.
6. Check `SORRY_ALLOWLIST.txt`: every `sorry` covered, every new or raised budget justified with a specific reason appropriate to the task kind.
7. Dependencies, with the tool `AGENTS.md` names: for every theorem the contribution adds or changes, check what it depends on; a theorem that depends on a `sorry`-carrying declaration without containing a `sorry` is conditional and its docstring must say so. For every *definition* the contribution changes, list the declarations whose meaning changed with it and re-check each, or say why it is unaffected.
8. If the worker asked questions, answer each one explicitly in your notes and feedback. If the contribution is `blocked`, check that it touched only what the blocked contract allows and that any question task it created follows the `AGENTS.md` template.
9. Check that the task file is `status: complete` only if its completion criteria are met, and that the work is committed.

## B. Book task

Work in this order:

1. Read the task file to see what was asked, and the discussion at `TEND_AGENT_DISCUSSION_PATH` for anything already said about this contribution.
2. `git diff main...HEAD` to see exactly what changed.
3. For every declaration added or changed, open the source text it cites in `<<REFERENCE_DIR>>` and compare hypotheses and conclusion line by line; then check it is stated about the library's objects (`<<INFRA_DIR>>`) and not a redefinition of them. This is the review; everything else is secondary. The build already passed, so it tells you nothing.
4. For every new definition, look for the witness that shows it is not vacuous, and check that the witness lives in the case the source cares about (not only a trivial or degenerate instance).
5. Check `SORRY_ALLOWLIST.txt`: every `sorry` covered, every new or raised budget justified with a specific reason, every open statement's docstring saying what it waits on.
6. For every theorem the contribution adds or changes, check what it depends on. If it depends on a `sorry`-carrying declaration (or `sorryAx` itself) without containing a `sorry`, it is complete but conditional on an open statement, and its docstring must name that statement. For every *definition* the contribution changes, find the declarations whose meaning changed with it and re-check each against the source, or say in your notes why it is unaffected.
7. Check that the task file is `status: complete` only if its completion criteria are met, and that the work is committed.

In either case: do not merge, do not edit the contribution, do not write a verdict file. Call the `final_result` tool exactly once with `schema_version=1`, `verdict` `approve` or `request_changes`, and non-empty `notes` giving your per-criterion walkthrough, separating what you verified from what the worker reported, and your answers to the worker's questions. For `request_changes`, include non-empty `feedback_text` that names the declaration, states the defect with its evidence (the source sentence or the plan sentence), and says what would be right; for `approve`, omit it.
