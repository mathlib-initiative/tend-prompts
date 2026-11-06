Resolve `TEND_TASK_ID`, `TEND_WORKTREE_ID` and `TEND_WORKTREE_PATH` from the environment. You are reviewing contribution `TEND_WORKTREE_ID` in the current git worktree. Find the task YAML under `tasks/` whose `id` matches `TEND_TASK_ID`; task ids do not necessarily match filenames.

Work in this order:

1. Read the task file to see what was asked (spec, prove, or single task), the plan entry it names in `<<PLAN_PATH>>`, and the discussion at `TEND_AGENT_DISCUSSION_PATH` for anything already said about this contribution, including questions the worker asked.
2. `git diff main...HEAD` to see exactly what changed. In a prove task, extract the statements of every declaration that existed on `main` and check they are unchanged.
3. For every declaration added or changed, compare it with the plan entry and with the mathematics: the right notion, the right generality, the strong form of the conclusion. For every new structure or class, find the simplest object satisfying it and the examples in the file; for every theorem, find the example witnessing its hypotheses. Write down, per declaration, one way it could be vacuous or weaker than intended and why it is not. This is the review; everything else is secondary. The build already passed, so it tells you nothing.
4. Check reuse against Mathlib (the inventory rows in `<<INVENTORY_DIR>>`, `grep -r .lake/packages/mathlib/Mathlib/`) and against the sibling modules under `<<INFRA_DIR>>`; check for instance diamonds.
5. Check Mathlib style: names, typeclass assumptions, `simp` attributes, docstrings, placement of auxiliary lemmas, absence of project-specific citations in declaration docstrings.
6. Check `SORRY_ALLOWLIST.txt`: every `sorry` covered, every new or raised budget justified with a specific reason appropriate to the task kind.
7. Dependencies, with the tool `AGENTS.md` names: for every theorem the contribution adds or changes, check what it depends on; a theorem that depends on a `sorry`-carrying declaration without containing a `sorry` is conditional and its docstring must say so. For every *definition* the contribution changes, list the declarations whose meaning changed with it and re-check each, or say why it is unaffected.
8. If the worker asked questions, answer each one explicitly in your notes and feedback. If the contribution is `blocked`, check that it touched only what the blocked contract allows and that any question task it created follows the `AGENTS.md` template.
9. Check that the task file is `status: complete` only if its completion criteria are met, and that the work is committed.

Do not merge. Do not edit the contribution. Do not write a verdict file yourself.

When the review is complete, call the `final_result` tool exactly once. Use `schema_version=1`, `verdict` `approve` or `request_changes`, and non-empty `notes` giving your per-criterion walkthrough, separating what you verified from what the worker reported, and your answers to the worker's questions. For `request_changes`, include non-empty `feedback_text` that names the declaration, states the defect with its evidence, and says what would be right; for `approve`, omit it. Do not provide a separate prose-only final answer.
