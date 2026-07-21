---
name: my-vault
description: The vault tool. Use when the user says "save this",
  "record this decision", "we decided", "plan this", "break this down",
  "pick up / work on this task", or asks "what do I know about...". Reads run
  free. Every write goes through the vault command and stops for review.
---
Pick the verb by what the user asked. Writes go through the counter (the `vault`
command) — the doctor checks the form; a clean form is accepted first time.
You NEVER edit a vault file by hand and you NEVER complete work — the door
(`vault-write-guard`) enforces both.

CAPTURE (write) · "save this / capture this..."
1. Call: vault capture "<title>" --type <learning|reference> --zone <inbox/|knowledge/>
2. Always give a real title and a known type. Default zone is inbox/ — use
   knowledge/ only when the user says it belongs in the knowledge base.
3. It records status: proposed. Show the receipt, then STOP. The human signs at the gate.

RECORD A DECISION (write) · "record this decision", "we decided..."
1. Call: vault adr <project> "<the decision in words>"
2. The counter finds the next free number, writes type adr, status proposed,
   and links it from the project index.
3. Show the receipt, then STOP. The user reviews and commits.

BREAK DOWN A PROJECT (write) · "plan this", "break this down..."
1. Plan first: vault plan <project> "<the outcome>" --goal "<one line>"
2. Slice it:  vault scope <project> <plan-slug> "<the slice>"  (one per slice)
3. First steps: vault task <project> "<the work>" --scope <scope-slug>
4. Everything lands status: proposed / planned. Show the receipts and
   `vault tree <project>`, then STOP. The user reviews and commits.

MOVE THE WORK (write) · "pick up / work on this task", "start on..."
The lifecycle: backlog → planning → active → review → completed. A human commits
the plan, then the scope, on the board — that moves the scope's tasks to
planning. Only a task in planning can be picked up.
1. Claim one:  vault claim <project> <task-slug>    (planning → active)
   - If it refuses ("only a planned task can be claimed"), the human hasn't
     committed its scope yet. Say so and STOP — don't try to force it.
2. Do the work. Write code OUTSIDE the vault; the trail stays inside it.
3. Hand it back: vault submit <project> <task-slug>  (active → review)
4. STOP. You can NEVER complete a task. The Human Gate approves it on the board
   (review → completed) or sends it back with a reason. `vault done` is blocked
   at the door, and so is editing a task file by hand to change its status.

RECALL (read) · "what do I know about..."
1. Read knowledge/index.md and follow its links, into projects too.
   (vault recent, vault search, and vault tree are quick entry points.)
2. Answer and cite the notes you used. Read only. No writes.

THE DOOR (why the rules hold)
`~/.claude/hooks/vault-write-guard.sh` runs before every tool call and refuses:
git commit/push (the human signs), direct Write/Edit into the vault (use the
verbs), deletes in the vault, `vault done`/`complete`, and any hand-edit of a
task file. When it refuses, read the message and follow it — don't work around
it.
