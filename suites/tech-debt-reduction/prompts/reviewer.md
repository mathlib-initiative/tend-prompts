Resolve `TEND_TASK_ID`, `TEND_WORKTREE_ID` and `TEND_WORKTREE_PATH` from the environment. You are reviewing contribution `TEND_WORKTREE_ID` in the current git worktree. Find the task YAML under `tasks/` whose `id` matches `TEND_TASK_ID`; task ids do not necessarily match filenames.

Work in this order:

1. Read the task file to see what was asked, the relevant part of `<<DEBT_LOG>>`, and the discussion at `TEND_AGENT_DISCUSSION_PATH` for anything already said about this contribution.

2. `git diff main...HEAD` to see exactly what changed. The build already passed, so it tells you nothing; your job is the debt accounting.

3. **Re-run the absorber test on every claimed removal.** For each workaround the worker says it deleted, look in the diff for anything that appeared to do its work: a new cast or type ascription, a restated helper, a `show`/`convert`/coercion, a different suppression, a raised budget, an import that shifts elaboration. A removal counts **only if the site is green with nothing added in its place.** If something is compensating, the debt moved, not left — `request_changes` and name the line. If you can, confirm by rebuilding the touched unit from a clean state (pass `timeout_seconds: 600`); an incremental build can mask it.

4. **Check the numbers against the tracker, not the prose.** Regenerate the tracker with `<<TRACKER_CMD>>` and confirm the worker's reported per-unit and whole-tree deltas (against baseline `<<BASELINE_REF>>`) match what it emits. Regenerate it twice and confirm byte-identical output; a non-deterministic tracker is a finding.

5. **Check the record moved with the code.** `<<DEBT_LOG>>` and the tracker output must be updated in this same contribution and must match the diff — the per-unit deltas, the root cause, and every attempted-and-kept site. A debt change with no record change, or a record that overstates what left the tree, is a `request_changes`. Watch for a delta quoted across a change in the counting unit.

6. **Check nothing was hidden to buy greenness.** No new hole (`<<HOLE_MARKERS>>`), stubbed return, disabled test, commented-out assertion, or type-system escape; no new suppression (`<<SUPPRESS_MARKERS>>`) except one the worker already flagged as unavoidable; and the exported surface (public signatures, generated code, serialized schema) did not silently move. Confirm the whole-tree census still reads `<<CENSUS_OK>>`.

7. Check that the task file is `status: complete` only if its completion criteria are met, and that the work is committed.

Do not merge. Do not edit the contribution. Do not write a verdict file yourself.

When the review is complete, call the `final_result` tool exactly once. Use `schema_version=1`, `verdict` `approve` or `request_changes`, and non-empty `notes` giving your per-criterion walkthrough, separating what you verified from what the worker reported. For `request_changes`, include non-empty `feedback_text` that names the removal and quotes the compensating line, or names the number and gives the tracker's actual value, so the worker can act on it; for `approve`, omit it. A workaround the worker honestly left as attempted-and-kept is **not** grounds for `request_changes`. Do not provide a separate prose-only final answer.
