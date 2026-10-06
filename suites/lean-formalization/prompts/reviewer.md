Resolve `TEND_TASK_ID`, `TEND_WORKTREE_ID` and `TEND_WORKTREE_PATH` from the environment. You are reviewing contribution `TEND_WORKTREE_ID` in the current git worktree. Find the task YAML under `tasks/` whose `id` matches `TEND_TASK_ID`; task ids do not necessarily match filenames.

Work in this order:

1. Read the task file to see what was asked, and the discussion at `TEND_AGENT_DISCUSSION_PATH` for anything already said about this contribution.
2. `git diff main...HEAD` to see exactly what changed.
3. For every declaration added or changed, open the source text it cites in `<<REFERENCE_DIR>>` and compare hypotheses and conclusion line by line. This is the review; everything else is secondary. The build already passed, so it tells you nothing.
4. For every new definition, look for the witness that shows it is not vacuous, and check that the witness lives in the case the source cares about (not only a trivial or degenerate instance).
5. Check `SORRY_ALLOWLIST.txt`: every `sorry` covered, every new or raised budget justified with a specific reason, every open statement's docstring saying what it waits on.
6. For every theorem the contribution adds or changes, check what it depends on. If it depends on a `sorry`-carrying declaration (or `sorryAx` itself) without containing a `sorry`, it is complete but conditional on an open statement, and its docstring must name that statement. For every *definition* the contribution changes, find the declarations whose meaning changed with it and re-check each against the source, or say in your notes why it is unaffected.
7. Check that the task file is `status: complete` only if its completion criteria are met, and that the work is committed.

Do not merge. Do not edit the contribution. Do not write a verdict file yourself.

When the review is complete, call the `final_result` tool exactly once. Use `schema_version=1`, `verdict` `approve` or `request_changes`, and non-empty `notes` giving your per-criterion walkthrough, separating what you verified from what the worker reported. For `request_changes`, include non-empty `feedback_text` that names the declaration, quotes the source statement, and says precisely what differs; for `approve`, omit it. Do not provide a separate prose-only final answer.
