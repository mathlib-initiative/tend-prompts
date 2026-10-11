Resolve `TEND_TASK_ID` and `TEND_WORKTREE_PATH` from the environment. Your worktree is the current git worktree, on a detached HEAD created from local `main`. Find the task YAML under `tasks/` whose `id` matches `TEND_TASK_ID`; task ids do not necessarily match filenames.

Work in this order:

1. Read `AGENTS.md`, then your task file in full, then the parts of `<<DEBT_LOG>>` that cover the area the task names — its ledger of *why each item exists and what would remove it* is your starting map. Read the discussion at `TEND_AGENT_DISCUSSION_PATH` if it exists.

2. **Census first, and distrust it.** Run `<<CENSUS_CMD>>` and the tracker regeneration `<<TRACKER_CMD>>` to see the current, authoritative counts rather than trusting the log's prose. If you grep for anything yourself, mask comments/strings/docstrings before counting and match paths exactly and symbols by qualified name. The whole-tree hole census must already read `<<CENSUS_OK>>`; if it does not, that is a finding — report it, do not build on top of it.

3. **Pick the target the task names, and attack its root.** The task scopes an area or a debt class; find the *upstream* declaration the downstream workarounds re-suffer. Fix bottom-up: repair the cause first, highest blast-radius first. If the task is open-ended, choose the root cause whose fix unblocks the most workarounds and say in your summary why you chose it.

4. **Remove by letting the compiler decide.** For each workaround the root fix should unblock: delete it and nothing else, rebuild the unit with `<<BUILD_CMD>>` (pass `timeout_seconds: 600`), and re-add it **only** where the build actually objects. Do not guess which sites are safe.

5. **Apply the absorber test to every removal.** A site that still builds after deletion counts as removed **only if you added nothing** to compensate — no cast, ascription, helper, alternate suppression, or raised budget. If making it green needed any such change, put the workaround back and leave the site for a real fix; record it as attempted-and-kept. Keep the contribution to a single root cause so the story is reviewable; bundle the removals it unblocks, not unrelated ones.

6. **Never close a goal or silence an error with a hole.** Any marker in `<<HOLE_MARKERS>>`, a stubbed return, a disabled test, a type-system escape — forbidden, even where the gate would tolerate it. A proof or path you cannot complete honestly stays as it was; you do not manufacture greenness.

7. **Move the debt record with the code.** In this same contribution, regenerate the tracker with `<<TRACKER_CMD>>` and update `<<DEBT_LOG>>` for this round: the per-unit deltas, the root cause fixed, and every attempted-and-kept site with the compensation it would have needed. Regenerate the tracker twice and confirm byte-identical output; a non-deterministic diff is a bug to report.

8. **Verify cold.** Run `<<VALIDATE_CMD>>` from a clean build state (not incremental) and confirm it passes and the census still reads `<<CENSUS_OK>>`. If your change could move the exported surface (public signatures, generated code, serialized schema), confirm it did not.

9. Inspect your diff. Commit your work. Set `status: complete` in the task YAML only if its completion criteria are met, and commit that too.

Then call the `final_result` tool exactly once with `schema_version=1`, `status` (`completed`, `blocked`, or `needs_review`), a non-empty `summary`, and any `files_changed`, `validation`, or `notes` you can report. In the summary, quote the **tracker's** per-unit debt delta and the whole-tree delta against `<<BASELINE_REF>>`, name the root cause you fixed, and list every workaround you tried to remove but kept because it failed the absorber test. If you could not reduce debt without adding a compensating change or a hole, that is a `blocked` outcome with the reason — not a padded "removed" count.
