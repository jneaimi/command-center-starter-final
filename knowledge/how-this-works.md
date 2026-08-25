---
title: How this command center works
type: reference
created: 2026-08-26
tags: [reference, orientation, index]
---

# How this command center works

The whole system on one page: what the pieces are, what the words mean, and how
work actually moves. Read it once and the rest of the vault explains itself.

## The big picture

You have a **vault** — plain markdown files you own — and a **face**, a small web
app that reads those files and puts a button where a decision is yours to make.
An AI agent works alongside you at a terminal. It can read anything and draft
anything. It cannot approve, complete, or publish anything.

That one asymmetry is the whole design. The agent is fast and tireless and
occasionally confidently wrong, so it does the work and you do the judgment.
Every irreversible step is a gate, and every gate is yours.

## The two halves

**`~/vault`** is your content. Notes in `knowledge/`, captures waiting in
`inbox/`, work in `projects/`. Every file is markdown with a small block of
frontmatter at the top. Nothing here is a database; you can read it with `cat`
and edit it with any editor, forever.

**The agent's rules** live in `AGENTS.md` at the top of the vault. Any CLI agent
that respects the convention reads it on the way in. Claude Code additionally
installs a guard hook that blocks the forbidden moves outright, rather than
asking nicely.

## The vocabulary

| Word | What it is |
|---|---|
| **capture** | a note the agent proposes. Lands in `inbox/`, waits for you |
| **knowledge** | a note you accepted. It is now part of what you know |
| **project** | a folder of work, with an `index.md` hub |
| **ADR** | a decision, written down, with a status. `adr-001-<slug>.md` |
| **plan** | an outcome you want. States a `goal` |
| **scope** | one slice of a plan. Names its plan as `parent` |
| **task** | a unit of work. Attaches to a scope or straight to a plan |
| **the gate** | any point where a status only changes because you said so |
| **the doorway** | `bin/vault` — the one command both of you write through |
| **the doctor** | `doctor.sh` — reads every note and reports what is malformed |
| **the guard** | the hook that stops an agent going around the doorway |

## How work moves

A plan states what done looks like. Scopes slice it. Tasks hang off scopes. An
ADR records a decision off to the side, and a plan can name the ADR that governs
it — in which case the plan cannot be committed until that decision is accepted.

```
you    accept a capture      inbox/ -> knowledge/
you    approve a decision    adr: proposed -> accepted
you    commit a plan         plan: proposed -> accepted
you    commit a scope        its tasks: backlog -> planned
agent  claim a task          planned -> active
agent  submit a task         active -> review
you    approve, or send back review -> done, or back to planned
```

The agent moves exactly two of those arrows, and only its own cards. It never
writes `accepted` and never writes `done`.

## What a note looks like

Frontmatter, then a heading, then one idea:

```markdown
---
title: Back up the database before every migration
type: learning
created: 2026-07-05
tags: [databases, habits]
---

# Back up the database before every migration

A migration changes the shape of your data in place. If it goes wrong halfway,
you want yesterday's copy, not an apology.

Related: [[a-checklist-beats-memory]] — "back up first" is exactly the kind of
step you skip once, on the day it mattered.
```

Two rules do the heavy lifting. **One idea per note**, so a note can be linked to
precisely. **Every note earns a link**, so nothing you write disappears into a
folder nobody opens. `knowledge/index.md` is the front door; keep it current and
you can always find your way back in.

## The commands you actually need

```bash
vault capture "a thing worth keeping"   # -> inbox/, waiting for you
vault adr    <project> "the decision"
vault plan   <project> "the outcome"
vault scope  <project> <plan-slug> "the slice"
vault task   <project> "the work" --scope <scope-slug>

vault projects            # what exists
vault tree <project>      # plan -> scopes -> tasks, with statuses
vault recent [n]          # newest notes
vault search <words>      # find by title or body

bash doctor.sh            # is the whole vault well-formed?
```

`vault help` prints the rest. Reads run free — looking was never the risk.

## Where to go next

- [[a-wall-is-part-of-the-door]] — why a refusal is a feature
- [[fail-closed-means-block-when-unsure]] — the rule the guard is built on
- [[the-guard-runs-before-every-action]] — how the guard actually fires
- [[../projects/hello-world/index|Hello World]] — drive the whole loop once, on
  something tiny
