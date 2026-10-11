Resume your work on contribution `$TEND_WORKTREE_ID` in `$TEND_WORKTREE_PATH` for the task whose `id` is `$TEND_TASK_ID`. Resolve these values from the environment and read the discussion at `TEND_AGENT_DISCUSSION_PATH` for the history of this contribution.

Latest feedback:

{feedback_message}

Address it in this same worktree.

- If the feedback is a reviewer's `request_changes` that a claimed removal **failed the absorber test** — the site only builds because something was added to compensate — do not argue the build is green. Green was never the question. Either find the real root-cause fix that lets the workaround go with *nothing* added, or put the workaround back, drop it from your reported removals, and record it as attempted-and-kept with the compensation it would have required. Correct the tracker and `<<DEBT_LOG>>` so the reported delta matches what actually left the tree.

- If the feedback is that your contribution **introduced a hole or a new suppression** to make something pass, remove it and finish the work honestly or leave the site as it was. A marker in `<<HOLE_MARKERS>>`, a stubbed return, a disabled test, or a fresh `<<SUPPRESS_MARKERS>>` entry added to buy greenness is never the fix.

- If the feedback is that **the tracker or `<<DEBT_LOG>>` did not move with the code** (or disagrees with the diff), regenerate the tracker with `<<TRACKER_CMD>>`, confirm it is byte-identical across two runs, and update `<<DEBT_LOG>>` so the per-unit deltas, the root cause, and the attempted-and-kept sites all match the actual diff.

- If the feedback is a validation or build failure, reproduce it with `<<VALIDATE_CMD>>` from a clean build state (pass `timeout_seconds: 600`) before changing anything, and confirm the census still reads `<<CENSUS_OK>>`.

- If the feedback reports a merge conflict, run `git merge main` (or `git rebase main`) inside the worktree and resolve it as the debt accounting requires — `main` is a local branch in the same `.git` as your worktree, so no `git fetch` is needed and there may be no remote at all. After resolving, re-run the tracker so its counts reflect the merged tree.

- If you believe the reviewer is mistaken — a removal genuinely needed no compensation, or a flagged marker is a licensed, tracked exception — say so explicitly in your summary with the evidence (the clean-build diff, the annotation that licenses it) and leave it as it is. Engage with the debt accounting, not the symptom.

`<<VALIDATE_CMD>>` must pass from a clean build and the census must read `<<CENSUS_OK>>` before you finish. Commit your work yourself; anything left uncommitted at session end is discarded. Keep the task YAML's `status` consistent with whether its completion criteria are met.

When done, call the `final_result` tool exactly once with the structured worker contribution result (`schema_version=1`, `status`, non-empty `summary`), saying what you changed in response to the feedback, the corrected per-unit debt delta the tracker now reports, and what, if anything, remains attempted-and-kept or open.
