# projects/ — zone rules

Rules for everything under `projects/`. They stack on top of the vault's eight
rules in the root `AGENTS.md`.

## Required frontmatter
- `created` — YYYY-MM-DD, always.
- `type` — one of: project · adr · plan · scope · work-item.

## Conventions
- Each project is a folder with an `index.md` hub.
- Decisions are ADRs: `adr-NNN-<slug>.md`, numbered per project, status one of
  proposed · accepted · shipped.
- The filename prefix is what the board reads, so it has to be right:
  `adr-` · `plan-` · `scope-` · `wi-` or `task-`.
- A scope names its plan in `parent`. A task names its scope, or its plan, the
  same way. A plan may name the decision that governs it in `governed_by` — and
  then it cannot be committed until that decision is accepted.
- A task's `status` moves backlog → planned → active → review → done. Only the
  human writes `planned`, `done`, or anything back from review.
