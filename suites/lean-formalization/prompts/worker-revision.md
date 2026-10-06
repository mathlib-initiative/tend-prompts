Resume your work on contribution `$TEND_WORKTREE_ID` in `$TEND_WORKTREE_PATH` for the task whose `id` is `$TEND_TASK_ID`. Resolve these values from the environment and read the discussion at `TEND_AGENT_DISCUSSION_PATH` for the history of this contribution.

Latest feedback:

{feedback_message}

Address it in this same worktree.

- If the feedback is a reviewer's `request_changes`, engage with the mathematics rather than the symptom. If the reviewer says a statement does not match the source, re-read the `<<REFERENCE_DIR>>` slice and fix the statement — do not adjust the proof around a wrong statement, and do not delete the statement to make the complaint go away. If you believe the reviewer is mistaken, say so explicitly in your summary with the source text that supports you, and leave the statement as it is.
- If the feedback is a validation or build failure, reproduce it with `bash scripts/validate.sh` (pass `timeout_seconds: 600`) before changing anything.
- If the feedback reports a merge conflict, run `git merge main` (or `git rebase main`) inside the worktree and resolve it as the mathematics requires — `main` is a local branch in the same `.git` as your worktree, so no `git fetch` is needed and there may be no remote at all.
- If the feedback is about the `sorry` allowlist, either discharge the proof or explain, in the commit message and the summary, exactly what the open statement is waiting on.

`bash scripts/validate.sh` must pass before you finish. Commit your work yourself; anything left uncommitted at session end is discarded. Keep the task YAML's `status` consistent with whether its completion criteria are met.

When done, call the `final_result` tool exactly once with the structured worker contribution result (`schema_version=1`, `status`, non-empty `summary`), saying what you changed in response to the feedback and what, if anything, remains open.
