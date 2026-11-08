Resume your work on contribution `$TEND_WORKTREE_ID` in `$TEND_WORKTREE_PATH` for the task whose `id` is `$TEND_TASK_ID`. Resolve these values from the environment and read the discussion at `TEND_AGENT_DISCUSSION_PATH` for the history of this contribution.

Latest feedback:

{feedback_message}

Address it in this same worktree.

- If the feedback answers questions you asked, apply the answers, record them where they belong (the module docstring, the `docs/questions/` file, or the proposal), and remove any `ASSUMPTION:` lines they settle.
- In a book task, if the reviewer says a statement does not match the source, re-read the `<<REFERENCE_DIR>>` slice and fix the statement; do not adjust the proof around a wrong statement, and do not delete the statement. If you believe the reviewer is mistaken, say so with the source text that supports you, and leave the statement as it is. If the reviewer says you redefined a library notion, replace the definition by an identification with the library's object.
- If the feedback is a reviewer's `request_changes` about a statement — it is too weak, too strong, vacuous, in the wrong generality, or differs from the plan — engage with the mathematics rather than the symptom. Re-read the plan entry and the inventory rows, fix the statement if the reviewer is right, and say so. If you believe the reviewer is mistaken, say so explicitly in your summary with the argument, and leave the statement as it is. In a prove task, a statement change is never the fix: write the proposal and ask the operator.
- If the feedback is about missing or degenerate examples, add examples that actually exercise the definition (a non-trivial instance, a non-example), not another trivial one.
- If the feedback is a validation or build failure, reproduce it with `bash scripts/validate.sh` (pass `timeout_seconds: 600`) before changing anything.
- If the feedback reports a merge conflict, run `git merge main` (or `git rebase main`) inside the worktree and resolve it as the mathematics requires — `main` is a local branch in the same `.git` as your worktree, so no `git fetch` is needed and there may be no remote at all. Conflicts in `SORRY_ALLOWLIST.txt` are resolved by the per-module merge driver when it is registered; otherwise rerun `python3 scripts/check_sorry_allowlist.py --fix`.
- If the feedback is about the `sorry` allowlist, either discharge the proof or explain, in the commit message and the summary, exactly what the open statement is waiting on.
- If the feedback says a blocked contribution touched files the blocked contract does not allow, either reduce the commit to `tasks/`, `docs/questions/` and `docs/proposals/`, or, if the extra files are compiling work you want to checkpoint, finish with `status: completed` and the task left `open` instead of `blocked`.

`bash scripts/validate.sh` must pass before you finish. Commit your work yourself; anything left uncommitted at session end is discarded. Keep the task YAML's `status` consistent with whether its completion criteria are met.

When done, call the `final_result` tool exactly once with the structured worker contribution result (`schema_version=1`, `status`, non-empty `summary`), saying what you changed in response to the feedback and what, if anything, remains open.
