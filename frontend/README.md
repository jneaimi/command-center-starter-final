# The face of your command center

A small **SvelteKit** app that gives your vault a face — a read surface, the
Human-Gate inbox, and a **governed kanban board** for every plan. It reads the
vault files next to it, keeps them in an in-memory index, and lets the humans
approve, commit, and gate the work through one governed door.

## Run it

```bash
cd frontend
npm install
npm run dev
```

Then open the local address it prints (**http://localhost:5180**, or the next
free port).

By default it reads the vault in the folder above `frontend/` (this repo). To
point it at a vault somewhere else:

```bash
VAULT_DIR=~/vault npm run dev
```

## What's inside (the four mechanics of Day 15)

| File | What it does |
|---|---|
| `src/lib/server/vault.js` | the engine — **load** · keep an **index** · **search** · re-read only on **change**, plus the governed writes |
| `src/routes/+page.*` | Home — recent notes + search |
| `src/routes/note/[slug]/+page.*` | read one note |
| `src/routes/projects/[name]/+page.*` | a project — its plans (commit + open board), decisions, history |
| `src/routes/projects/[name]/plan/[plan]/+page.*` | the **board** — backlog → planning → active → review → completed |
| `src/routes/inbox/+page.*` | the **Human Gate** — approve decisions, greenlight plans |
| `src/app.css` (`:root`) | your **design tokens** — change 4 lines to re-brand the whole face |

The pages never touch the disk themselves — they ask `vault.js` through the
`/api` seam. That one boundary is what keeps the face and the engine apart.

## The board — who moves what

The board is the work model made visible. Each column is a status; a card moves
by changing that status. **Who is allowed to make each move is the whole point:**

| Move | Who | Where |
|---|---|---|
| Commit a **plan** (proposed → accepted) | human | inbox / project / board |
| Commit a **scope** (its tasks → planning) | human | board |
| **Claim** a task (planning → active) | AI | terminal — `vault claim <project> <task>` |
| **Submit** a task (active → review) | AI | terminal — `vault submit <project> <task>` |
| **Approve** (review → completed) | human | board — the gate |
| **Send back** (review → planning + reason) | human | board — the gate |

The AI can **never** move a card to *completed* — `vault done` is blocked at the
door (the Hook). Only the human's **Approve** on the board writes `completed`.
That's the three-channel loop: the terminal does the work, the face gates it.

Because the board refreshes live, a card the AI moves from the terminal appears
in its new column on its own — no reload.

## Make it yours (homework / stretch)

- Change the four tokens in `src/app.css` to your Day-14 palette.
- Add drag-and-drop, filters, or a graph of your links.
- Deploy it (the Node adapter builds with `npm run build` → `npm run preview`).
