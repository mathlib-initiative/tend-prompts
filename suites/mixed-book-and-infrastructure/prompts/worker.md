Resolve `TEND_TASK_ID` and `TEND_WORKTREE_PATH` from the environment and find the task YAML under `tasks/` whose `id` matches `TEND_TASK_ID`. If the id begins with `infra-`, follow **A**; otherwise follow **B**.

## A. Infrastructure task

Work in this order:

1. Read `AGENTS.md`, then your task file in full, then the discussion at `TEND_AGENT_DISCUSSION_PATH` if it exists. Read any `docs/questions/` or `docs/proposals/` file your task names.
2. Read the plan entry your task names in `<<PLAN_PATH>>` — the whole row, the layer's decisions, and the principles section — and the rows of the inventory in `<<INVENTORY_DIR>>` that cover its notions. These are your specification and your Mathlib map.
3. Look at what Mathlib already provides for every notion involved (`exact?`, `#check`, `grep -r .lake/packages/mathlib/Mathlib/`, the inventory). Look at what sibling modules under `<<INFRA_DIR>>` already define; do not redefine their notions, import them.
4. If the task is a **spec** task (or a single task): write the module docstring (purpose, plan entry, what it serves, design choices and why), the definitions in final form with Mathlib-style docstrings, the theorems stated with tracked `sorry`s where you do not prove them now, and an `Examples` section: at least one non-degenerate instance of every new structure or class, an `example` witnessing the hypotheses of every non-obviously-satisfiable theorem, and the non-examples the plan lists, proved to fail. Prove what is cheap. Commit the skeleton before you spend long on any proof.
   If the task is a **prove** task: diff your module against `main` as you go and keep every statement identical; close the `sorry`s; add auxiliary lemmas in Mathlib style; keep the examples compiling. If a statement cannot be proved as stated, stop, write the proposal, and ask (see the system prompt); do not adjust the statement.
5. Iterate with the warm Lean worker `AGENTS.md` describes, then `lake build <Module>` to confirm — pass `timeout_seconds: 600`; the bash tool's hard cap is 600 seconds. Do not rebuild the whole project after every edit.
6. Before finishing, ask the vacuity questions of your own work and write the answers into the module docstring: what is the simplest instance, what is a non-instance, could any theorem be proved by `trivial` for reasons unrelated to the mathematics, is every universal property instantiated on a concrete target somewhere in the file.
7. Lint: `lake env lean <your file>` must show no warning except `declaration uses sorry`, and `lake exe runLinter <Module>` must exit cleanly (unused arguments, missing docstrings, simp normal forms). Fix what they report; a `nolint` or a disabled linter needs a justifying comment and the reviewer's agreement.
8. If you left any `sorry`, run `python3 scripts/check_sorry_allowlist.py --fix` and justify each new or raised budget. Anything else the gate calls debt — `set_option maxHeartbeats`, `erw`, an `axiom`, `native_decide` — fails validation; a proof that needs one stays open instead.
9. `bash scripts/validate.sh` must pass.
10. Inspect your diff. Commit your work. Set `status: complete` in the task YAML only if its definition of done is met, and commit that too. In a spec task that left no `sorry`, also set the matching `-prove` task to `status: complete` with a `notes:` line saying why. If you asked the operator a question, follow the blocked contract exactly: only `tasks/` and `docs/questions/` (and `docs/proposals/`) in the commit, progress in your task's `notes:`, `status: blocked`.

## B. Book task

Work in this order:

1. Read `AGENTS.md`, then your task file in full. Read the discussion at `TEND_AGENT_DISCUSSION_PATH` if it exists.
2. Read the `<<REFERENCE_DIR>>` slice the task names — all of it — before writing any Lean. If `docs/mathlib-survey.md` exists, read it too.
3. Read the infrastructure modules your task names (`docs/status.md` and the layer notes say what each proves and leaves open), then look for what Mathlib provides; define nothing the library or Mathlib has.
4. Fill in the Lean module the task names. Formalize the section's definitions, numbered statements and displayed equations in the order the source gives them, each with a docstring citing its source item: the book's definitions as identifications with the library's objects, the book's theorems stated about those objects and proved from the library's results. Prove what the library and Mathlib support; state the rest faithfully and leave a tracked `sorry`. Give every new definition a witness; render the book's own examples as `example`s or instances.
5. Build the module you are editing with `lake build <Module>` — pass `timeout_seconds: 600`; the bash tool's hard cap is 600 seconds. Do not rebuild the whole project after every edit.
6. If you left any `sorry`, run `python3 scripts/check_sorry_allowlist.py --fix` and be ready to justify each new or raised budget. Anything else the project's gate calls debt — `set_option maxHeartbeats`, `erw`, an `axiom`, `native_decide` — fails validation; a proof that needs one stays open instead.
7. `bash scripts/validate.sh` must pass.
8. Inspect your diff. Commit your work. Set `status: complete` in the task YAML only if its completion criteria are met, and commit that too.

Then, in either case, call the `final_result` tool exactly once with `schema_version=1`, `status` (`completed`, `blocked`, or `needs_review`), a non-empty `summary`, and any `files_changed`, `validation`, `tasks_created`, or `notes` you can report. In the summary, name the items you formalized or the statements you added, the examples and what each demonstrates, every `sorry` you left with the reason it is open, every deviation you declared, and every question you asked and of whom.
