# Your Command Center

A markdown vault you own — your knowledge and your projects — with a SvelteKit face over it
that enforces one rule: **the AI drafts and does the work, you sign.** Every capture,
decision, plan and finished task waits at a gate only a human can open.

The repo root **is** the vault. The installer copies it to `~/vault`; the face lives in
`frontend/`.

## Requirements

| Need | Why | Without it |
|---|---|---|
| `bash`, `git` | the installer, the doorway, the doctor | nothing runs |
| Node **≥ 18.13** | the face (`@sveltejs/kit` declares `>=18.13`, `vite` wants `^18 \|\| >=20`) | `npm run dev` fails |
| `python3` | the guard hook parses Claude Code's hook JSON with it | **the guard silently enforces nothing — see below** |
| Claude Code | the AI half of the loop | the vault still works; you just drive it alone |
| `pm2` *(optional)* | keeping the face running across reboots | only affects "keep it always on" |

`install.sh` checks for `node` and `claude`, but not their versions, and it never checks
`python3` directly. That last one matters more than it looks: `vault-write-guard.sh` extracts
the tool name with `python3 -c '…' 2>/dev/null`. With no `python3` on PATH the extraction
comes back empty, no rule matches, and the hook exits `0` — every law off, no error shown.

```
with python3 present : exit 2 (blocked)
with python3 absent  : exit 0 (allowed)
```

## Install

```bash
git clone https://github.com/jneaimi/command-center-starter-final.git
bash command-center-starter-final/install.sh
```

The installer archives any existing `~/vault` to `~/archive/vault-pre-week4-<timestamp>`,
copies this repo to `~/vault`, stages three files into `~/.claude`, adds `~/vault/bin` to your
PATH via `~/.zshrc` / `~/.bashrc`, and runs 7 checks. Nothing is ever deleted — only archived.

The three staged files are the whole `~/.claude` footprint:

```
~/.claude/CLAUDE.md                   global rules
~/.claude/settings.json               registers the guard on Bash|Write|Edit
~/.claude/hooks/vault-write-guard.sh  the four laws
```

The `my-vault` skill is **not** among them — it is a project skill living at
`.claude/skills/my-vault/` inside the vault, so it loads when you work in `~/vault` and
refreshes on `git pull`.

Then, in two places:

```bash
# drive it from the terminal (open a NEW terminal first, for the PATH)
cd ~/vault && claude

# open its face
cd ~/vault/frontend && npm install && npm run dev   # http://localhost:5180
```

Windows: run the same steps inside WSL (Ubuntu).

## Update (without reinstalling)

`install.sh` copies the whole clone — `.git` included — so `~/vault` is itself a working
checkout and `git pull` works there. A pull refreshes the vault, `bin/vault`, and the
`my-vault` skill, but not the `~/.claude` side. `update.sh` does that half:

```bash
cd ~/vault && git pull && bash update.sh
```

Your notes, projects and inbox are never touched. The three `~/.claude` files **are**
replaced, so the previous ones are copied to `~/archive/dot-claude-backup-<timestamp>` first.
Restart your Claude Code session afterward so the refreshed guard and skill load.

## What's inside

```
CLAUDE.md                     the vault's 8 standing rules (doctor.sh enforces 4
                              outright and 2 in part — see "What it will not do")
bin/vault                     the doorway — one command, both of you use it:
                                draft   capture (→ inbox/) · adr · plan · scope · task
                                move    claim (→ active) · submit (→ review)
                                gate    accept · reject · commit    (human only)
                                read    projects · recent · search · tree · help
                                        done / complete — always refused
doctor.sh                     read-only check-up: frontmatter, known types, kebab-case
                              names, live links, ADR status, plan goal, scope parent
knowledge/                    15 interlinked notes + index.md, the front door
inbox/                        captures waiting at the gate — a capture is a proposal;
                              only you move one into knowledge/
projects/hello-world/         a guided tour — its ADR, plan, scope and 2 tasks each
                              explain their own step; drive the whole loop once
projects/profile-site/        a realistic build to test on the board: 3 decisions,
                              a plan, 3 scopes, 6 backlog tasks
templates/                    frontmatter stubs: decision · learning · project · reference
frontend/                     the SvelteKit face (see frontend/README.md)
.claude/skills/my-vault/      the skill, wired to the doorway — rides in the vault
setup/dot-claude/             the ~/.claude side the installer stages
docs/FACILITATOR.md           notes for running this as a taught program
```

## How the work moves — and who moves it

Three layers agree on the rules: the engine refuses illegal moves, the face only shows a
button where a move is legal, and the guard stops the AI going around either.

| Move | Who | Where |
|---|---|---|
| Accept a captured note (`inbox/` → `knowledge/`) | human | the inbox |
| Approve a decision (ADR → accepted) | human | the inbox, or the ADR's own page |
| Commit a plan — only once its decision is accepted | human | the board |
| Commit a scope → all its tasks move to planning | human | the board |
| Claim a task (planning → active) | **AI** | `vault claim <project> <task>` |
| Submit a task (active → review) | **AI** | `vault submit <project> <task>` |
| Approve (review → completed), or send back with a reason | human | the board |

The AI can never complete work or approve anything: `vault done`, `vault accept`,
`vault reject` and `vault commit` are blocked at the door, as are `git commit`, `git push`,
deletes inside the vault, direct `Write`/`Edit` into a vault folder, and hand-edits that
would move a task's status. And there is one way in — `vault capture` always lands in
`inbox/`, so nothing reaches `knowledge/` without passing the gate.

Both starter plans carry `governed_by`, so the "approve the decision first" rule is live from
the first click: try to commit `plan-hello-world` before its ADR and the engine refuses.

### The board's columns are not the words in your files

The board shows **Backlog · Planning · Active · Review · Completed**. The `status:` line in
the file says something shorter. When you read a note, this is the mapping:

| `status:` in the file | Board column |
|---|---|
| `proposed`, `backlog`, `draft`, blank | Backlog |
| `planned` | Planning |
| `active` | Active |
| `review` | Review |
| `done`, `completed`, `shipped` | Completed |

## Configuration

| Variable | Read by | Default |
|---|---|---|
| `VAULT_DIR` | `bin/vault`, `doctor.sh`, the face | `~/vault` for the tools; for the face, the folder above `frontend/` |
| `PORT` | the **built** server (`build/index.js`) | `3000`. The dev server ignores it — `vite.config.js` pins dev to `5180` |
| `HOST` | the **built** server only | every interface — **set it, see below** |

Point any of the three at another vault the same way:

```bash
VAULT_DIR=~/other-vault vault recent
VAULT_DIR=~/other-vault bash doctor.sh
VAULT_DIR=~/other-vault npm run dev      # from frontend/
```

## Keep it always on

To keep the face running across reboots, install `pm2` (`npm i -g pm2`) and run the built
server:

```bash
cd ~/vault/frontend && npm run build
VAULT_DIR=$HOME/vault HOST=127.0.0.1 PORT=5180 pm2 start build/index.js --name command-center
pm2 save && pm2 startup   # run the line it prints
```

`HOST=127.0.0.1` is the important part. The face has no login, and every gate lives on it —
approve, reject, commit, complete. Left on its default the Node server answers on every
address the machine has, so anyone on the same café or office Wi-Fi could sign in your name.
Bound to `127.0.0.1` it answers only this computer.

## What it will not do

- **No authentication.** The face is single-user by design. Keep it on localhost.
- **`vault capture` writes two types only** — `learning` and `reference`. `decision`,
  `project`, `adr`, `plan`, `scope` and `work-item` are valid in the vault and accepted by
  the doctor, but ADRs, plans, scopes and tasks are made by their own verbs, and the
  `templates/` stubs are filled in by hand.
- **The doctor enforces 4 of the 8 rules in `CLAUDE.md` outright, and 2 in part.** It checks
  frontmatter (rule 2), known types (3), ADR status (7) and the plan model's goal and parent
  (8). Of rule 4 it checks kebab-case names but not "one idea per note"; of rule 5 it catches
  a link pointing at nothing but not a note nobody links to. "Non-sensitive content" (1) and
  "keep the index current" (6) are yours to hold entirely.
- **No cost, no network, no telemetry.** Everything here is files on your disk.

## The rule that never moves

Non-sensitive content only. Reads run free; writes wait for your review. The AI drafts, does
the work, and stops at every gate. You hold the judgment.
