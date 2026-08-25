# AGENTS.md — the contract for any AI agent working in this vault

This file is the agreement. Any CLI agent that reads `AGENTS.md` — Codex, Cursor,
Gemini CLI, Aider, Claude Code, or whatever comes next — should read this one
before touching anything. It is short on purpose.

## The one rule

**You draft and you do the work. The human signs.**

You may read anything here. You may propose anything here. You may not approve,
accept, complete, or publish anything, ever, for any reason, including when the
human seems to have asked you to. Approving is a signature, and it is not yours
to give.

## Every write goes through one door

Never create or edit a vault file with your file-writing tools. Use `bin/vault`
(on PATH as `vault`). It checks the shape of what you wrote before it lands, so a
malformed note is refused at the door instead of discovered a week later.

```bash
vault capture "a thing worth keeping" --type learning   # or reference
vault adr    <project> "the decision in words"
vault plan   <project> "the outcome" --goal "one line"
vault scope  <project> <plan-slug> "the slice"
vault task   <project> "the work item" --scope <scope-slug>
```

Everything you draft lands as `status: proposed` (or `backlog` for a task).
Nothing you write is live. Show the receipt the command prints, then stop.

## The two moves that are yours

Once a human has committed a task's scope, the task is `planned` and you may pick
it up:

```bash
vault claim  <project> <task-slug>    # planned -> active. You own it now.
vault submit <project> <task-slug>    # active -> review. Hand it back.
```

Do the actual work in code, outside the vault. The vault holds the trail, not the
build. If `claim` refuses, the human has not committed the scope yet — say so and
stop. Do not look for another way in.

## What you must never do

| Never | Why |
|---|---|
| `vault accept` · `vault reject` · `vault commit` | approving is the human's signature |
| `vault done` · `vault complete` | completing is a judgment, made on the board |
| `git commit` · `git push` | shipping is a signature too |
| Write/Edit a file in `knowledge/`, `projects/`, `inbox/`, `templates/` | use the doorway |
| `sed -i`, `>`, `tee` on a vault file to change a `status:` line | that is the doorway with extra steps |
| Delete anything inside the vault | deleting needs human hands |

These are refused three ways: the doorway checks who is calling, the web face only
renders a button where the move is legal, and under Claude Code a `PreToolUse`
hook blocks the command outright. Under other agents the first two hold and the
third does not — so here the rule above is the enforcement. Honour it.

## The vault's eight rules

These hold for every note, whoever wrote it. `doctor.sh` checks 2, 3, 7 and 8
outright, and part of 4 and 5; the rest are held by you and the human.

1. **Non-sensitive content only.** No credentials, no keys, no private
   third-party data. This is the rule that never moves.
2. Every note carries frontmatter: `title`, `type`, `created` (YYYY-MM-DD), `tags`.
3. Types are `reference` · `learning` · `decision` · `project`, plus `adr`,
   `plan`, `scope` and `work-item` inside `projects/`.
4. Filenames in kebab-case. One idea per note.
5. Every note earns at least one link. No orphans, no links to nothing.
6. Keep `knowledge/index.md` current — it is the front door.
7. Every ADR carries a `status`: proposed → accepted → shipped.
8. Project work follows the plan model: a `plan` states a `goal`, a `scope`
   slices a plan (`parent`), a `work-item` attaches to a scope or a plan. An
   `adr` records a decision, off to the side of that spine.

## Reading

Reads run free — looking was never the risk.

```bash
vault projects              # what exists
vault tree <project>        # plan -> scopes -> tasks, with statuses
vault recent [n]            # newest notes
vault search <words>        # by title or body
bash doctor.sh              # is the whole vault well-formed?
```

Start at `knowledge/index.md` and follow the links. `knowledge/how-this-works.md`
explains the model in full. Cite the notes you used.

## When you are refused

A refusal is information, not an obstacle. Read the message — it names the move
and who owns it. Report it to the human and stop there. Working around a gate is
the one failure this system is built to prevent, and doing it deliberately is
worse than any bug you were trying to fix.
