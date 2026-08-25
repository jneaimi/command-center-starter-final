# hooks/

`vault-write-guard.sh` is the **live guard** as it stands at the end of Week 3 —
not a stub. Four laws:

1. **Signing is the human's** (Day 6) — `git commit` / `git push` are blocked
   with exit 2, and so are `vault accept`, `vault reject` and `vault commit`:
   approving is a signature too.
2. **Notes go through the doorway** (Day 10) — `Write`/`Edit` into
   `knowledge/`, `projects/`, `templates/`, `inbox/` are blocked; the door sign
   points at the `vault` command. Tool files (`bin/vault`, `doctor.sh`) stay on
   the bench: the AI may edit them, your diff review covers them.
3. **Deleting in the vault needs your hands** (Day 6, make-it-yours).
4. **The AI moves only its own cards** — `vault claim` and `vault submit`, never
   `vault done`, and never by hand-editing a `status:` line to get around either.

It needs `python3` on PATH: each law reads the tool name out of the hook's JSON
with it. Without `python3` the read comes back empty, no law matches, and the
hook exits 0 — enforcing nothing, silently.

It is registered in `settings.json` as a `PreToolUse` hook watching
`Bash|Write|Edit`. The install script stages both files; restart Claude after
installing so the wiring loads.
