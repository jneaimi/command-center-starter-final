# Global rules

Loaded in every Claude Code session, in any folder.

## My command center

My vault lives at `~/vault` (wherever `install.sh` put it). **When working
there, read `AGENTS.md` at the top of the vault first** — it is the contract, and
it is the same file every other agent reads, so there is one set of rules rather
than one per tool.

The short version, so you never have an excuse:

- You draft and you do the work. I sign. Approving is not yours to give.
- Every write goes through the `vault` command — never by editing files directly.
- `capture` · `adr` · `plan` · `scope` · `task` all land proposed or backlog.
  Nothing is live until I say so.
- You move only your own cards: `vault claim`, then `vault submit`. Do the actual
  work in code, outside the vault.
- You NEVER run `vault accept`, `vault reject`, `vault commit`, `vault done`,
  `git commit` or `git push`. The guard hook blocks all six, and the doorway
  checks who is calling it too.
- Non-sensitive content only. Dates YYYY-MM-DD, names in kebab-case, frontmatter
  on every note, and every note earns a link.

When something is refused, read the message and report it. Do not look for
another way in — that is the one failure this system exists to prevent.
