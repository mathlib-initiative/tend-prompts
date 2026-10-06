Resolve `TEND_TASK_ID` and `TEND_WORKTREE_PATH` from the environment. Your worktree is the current git worktree, on a detached HEAD created from local `main`. Find the task YAML under `tasks/` whose `id` matches `TEND_TASK_ID`; task ids do not necessarily match filenames.

Work in this order:

1. Read `AGENTS.md`, then your task file in full. Read the discussion at `TEND_AGENT_DISCUSSION_PATH` if it exists.
2. Read the `<<REFERENCE_DIR>>` slice the task names — all of it — before writing any Lean. If `docs/mathlib-survey.md` exists, read it too.
3. Look for what Mathlib already provides (`exact?`, `#check`, `grep -r .lake/packages/mathlib/Mathlib/`) before defining anything of your own.
4. Fill in the Lean module the task names. Formalize the section's definitions, numbered statements and displayed equations in the order the source gives them, each with a docstring citing its source item. Prove what today's Mathlib supports; state the rest faithfully and leave a tracked `sorry`. Give every new definition a witness.
5. Build the module you are editing with `lake build <Module>` — pass `timeout_seconds: 600`; the bash tool's hard cap is 600 seconds. Do not rebuild the whole project after every edit.
6. If you left any `sorry`, run `python3 scripts/check_sorry_allowlist.py --fix` and be ready to justify each new or raised budget. Anything else the project's gate calls debt — `set_option maxHeartbeats`, `erw`, an `axiom`, `native_decide` — fails validation; a proof that needs one stays open instead.
7. `bash scripts/validate.sh` must pass.
8. Inspect your diff. Commit your work. Set `status: complete` in the task YAML only if its completion criteria are met, and commit that too.

Then call the `final_result` tool exactly once with `schema_version=1`, `status` (`completed`, `blocked`, or `needs_review`), a non-empty `summary`, and any `files_changed`, `validation`, `tasks_created`, or `notes` you can report. In the summary, name the source items you formalized and list every `sorry` you left with the reason it is open.
