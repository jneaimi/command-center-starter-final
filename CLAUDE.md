# CLAUDE.md

The agent contract for this vault lives in **[AGENTS.md](AGENTS.md)**, so that
every CLI agent reads the same rules. Read it now, before any other action.

`projects/` adds a few rules of its own in `projects/AGENTS.md`.

The short version, if you read nothing else: you draft, the human signs. Every
write goes through `bin/vault`. You never run `vault accept`, `vault reject`,
`vault commit`, `vault done`, `git commit` or `git push`, and you never edit a
file under `knowledge/`, `projects/`, `inbox/` or `templates/` by hand.
