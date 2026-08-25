# hooks/

`vault-write-guard.sh` is the guard, and it is live — not a stub. Four laws:

1. **Signing is the human's** — `git commit` / `git push` are blocked
   with exit 2, and so are `vault accept`, `vault reject` and `vault commit`:
   approving is a signature too.
2. **Notes go through the doorway** — `Write`/`Edit` into
   `knowledge/`, `projects/`, `templates/`, `inbox/` are blocked; the door sign
   points at the `vault` command. Tool files (`bin/vault`, `doctor.sh`) stay on
   the bench: the AI may edit them, your diff review covers them.
3. **Deleting in the vault needs your hands.**
4. **The AI moves only its own cards** — `vault claim` and `vault submit`, never
   `vault done`, and never by hand-editing a `status:` line to get around either.

It needs `python3` on PATH: each law reads the tool name out of the hook's JSON
with it. Without `python3` the read comes back empty, no law matches, and the
hook exits 0 — enforcing nothing, silently.

It is registered in `settings.json` as a `PreToolUse` hook watching
`Bash|Write|Edit`. The install script stages both files; restart Claude after
installing so the wiring loads.

**It reads the tool call with `python3`, or `node` if there is no `python3`.**
If neither is on PATH it blocks everything and says why. A guard that cannot
read the call has no business waving it through — it would look like protection
while being none, which is the failure mode this vault has a note about
(`knowledge/fail-closed-means-block-when-unsure.md`).

**It finds the vault via `~/.claude/hooks/vault-dir`,** written by `install.sh`,
falling back to `~/vault`. That is what lets `install.sh --dir` put the vault
somewhere else without law 2 quietly ceasing to apply.
