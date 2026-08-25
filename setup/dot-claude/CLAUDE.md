# Global rules

Loaded in every Claude session, any folder.

## My vault
My knowledge vault lives at `~/vault`. When working there:
- Non-sensitive content only.
- Dates YYYY-MM-DD. Names in kebab-case.
- Frontmatter on every note (`title`, `type`, `created`, `tags`).
- Keep `knowledge/index.md` current. Every note earns a link — no orphans.
- Propose writes and STOP. I review the `git diff` and commit. You never commit.

## The write path (in ~/vault)
- Every write goes through the `vault` command — never by editing files directly.
- You draft: `capture` · `adr` · `plan` · `scope` · `task` (all land proposed or
  backlog — nothing is live until I say so). A capture lands in `inbox/`; only I
  move it into `knowledge/`. The `my-vault` skill has the details.
- You move only your own work: `vault claim` then `vault submit`. Do the actual
  work in code, outside the vault.
- You NEVER complete work and NEVER approve — `vault done`, `accept`, `reject`,
  and `commit` are mine, blocked at the door. Draft, submit, and stop.
