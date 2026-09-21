# TODO: Suite name

This is an authoring template. Copy this directory to `suites/<suite-name>/`,
replace the `TODO` sections in this README and all five prompts, and remove this
paragraph before listing the suite in the catalogue.

## Purpose

TODO: Describe the work this suite is intended for, the expected outputs, and
when a different suite would be more appropriate.

## Assumptions and configuration

- Status: draft.
- Runner: Tend's generated `--agent tend` scripts.
- Repository/task assumptions: TODO.
- Required tools and validation commands: TODO.
- Model or runtime requirements, if any: TODO.
- Tend compatibility: TODO: record the version or commit checked and whether
  this was source inspection, a dry run, or an actual worker/reviewer run.

## Prompts

- [Worker system](prompts/worker-system.md)
- [Worker assignment](prompts/worker.md)
- [Worker revision](prompts/worker-revision.md)
- [Reviewer system](prompts/reviewer-system.md)
- [Review task](prompts/reviewer.md)

Install the five files into an initialized run's `prompts/` directory. See the
repository README for the copy procedure and placeholder conventions.

## Evaluation and provenance

TODO: Identify any prompts or suites this work is derived from and retain any
required attribution. For each evaluation, record the date, prompt repository
commit and suite path, Tend commit/version, task set, model/settings, validation
performed, observed results, and limitations. Link supporting evidence where
available. Do not include credentials or private run transcripts.

No task runs or quality measurements have been recorded for this template.
