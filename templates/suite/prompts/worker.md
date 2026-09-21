Resolve TEND_TASK_ID and TEND_WORKTREE_PATH from the environment. Find the task
YAML under tasks/ whose id matches TEND_TASK_ID, read its requirements, and
inspect the relevant project files in the assigned worktree. Task IDs do not
necessarily match filenames.

TODO: Describe the task workflow, expected artifacts, and validation steps for
this suite.

Make the requested changes, run the appropriate checks, and inspect your diff.
Update the task to status: complete when its criteria are satisfied. Commit the
contribution and report the outcome using final_result as required by the
worker system prompt.
