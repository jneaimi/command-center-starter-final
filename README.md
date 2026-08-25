# Your Command Center

A personal command center: a **markdown vault** (your knowledge + your projects)
plus a **SvelteKit face** that gives it a read surface, a Human-Gate inbox, and a
**governed kanban board** for every plan. You drive it from the terminal and the
face; the AI drafts and does the work; you hold the judgment.

The repo root **is** the vault — the installer places it at `~/vault`, and the
face lives in `frontend/`.

## Install

```bash
git clone https://github.com/jneaimi/command-center-starter-final.git
bash command-center-starter-final/install.sh
```

The installer places the vault at `~/vault` (archiving any previous one to
`~/archive` — nothing is deleted), stages the `~/.claude` side (rules, settings,
the guard hook), puts the `vault` command on your PATH, and
**verifies everything**. Then, in two places:

```bash
# drive it from the terminal
cd ~/vault && claude

# open its face (the app)
cd ~/vault/frontend && npm install && npm run dev
```

Windows: run the same steps inside WSL (Ubuntu).

## Update (without reinstalling)

`install.sh` copies files *out* of this repo into `~/vault` **and** into
`~/.claude`. A plain `git pull` refreshes the vault, the `vault` command, and the
`my-vault` skill (a project skill — it lives in the vault at `.claude/skills/`),
but not the `~/.claude` side (the guard + settings). To pull everything up to date
without reinstalling — and without touching your notes, projects, or inbox:

```bash
cd ~/vault && git pull && bash update.sh
```

`update.sh` re-stages the `~/.claude` files and re-checks the tools. Your vault
content — notes, projects, inbox — is left exactly as it is. The `~/.claude`
files *are* replaced, so your previous ones are moved to `~/archive` first;
nothing is deleted. Restart your Claude Code session afterward so the refreshed
guard and skill load.

## What's inside

```
CLAUDE.md                     the vault rules the doctor enforces
bin/vault                     the doorway — one command, both of you use it:
                                draft   capture (→ inbox/) · adr · plan · scope · task
                                move    claim (→active) · submit (→review)
                                gate    accept · reject · commit  (human only)
                                read    projects · recent · search · tree
doctor.sh                     the read-only check-up for the whole vault
knowledge/                    interlinked notes + index (the method, the tools)
projects/hello-world/         a guided tour — each ADR/plan/scope/task explains
                              the step; build the tiniest thing and drive the
                              whole loop once
projects/profile-site/        a realistic build, ready to test on the board:
                              decisions + a draft plan + scopes + backlog tasks
inbox/                        captures waiting at the gate — a capture is a
                              proposal; only you move one into knowledge/
frontend/                     the SvelteKit face (see frontend/README.md)
.claude/skills/my-vault/      the skill, wired to the doorway — a project
                              skill, so it rides in the vault and updates on pull
setup/dot-claude/             the ~/.claude side the installer stages:
                                CLAUDE.md        global rules
                                settings.json    the guard on Bash|Write|Edit
                                hooks/           vault-write-guard.sh — its 4 laws
```

## How the work moves — and who moves it

The lifecycle of a task: **backlog → planning → active → review → completed.**
Each step has an owner, and the rules are enforced three ways — the engine
refuses illegal moves, the face reflects the gates, and the guard + `vault`
command stop the AI from going around them.

| Move | Who | Where |
|---|---|---|
| Accept a captured note (inbox/ → knowledge/) | human | the inbox |
| Approve a decision (ADR → accepted) | human | inbox / the ADR's page |
| Commit a plan (→ accepted) — only once its decision is accepted | human | the board |
| Commit a scope → its tasks move to planning | human | the board |
| Claim a task (planning → active) | **AI** | `vault claim <project> <task>` |
| Submit a task (active → review) | **AI** | `vault submit <project> <task>` |
| Approve (review → completed) / send back (→ planning) | human | the board |

The AI can **never** complete work or approve anything — `vault done`,
`vault accept`, `vault reject`, and `vault commit` are blocked at the door. It
drafts and does; you sign. And there is only one way in: `vault capture` always
lands in `inbox/`, so nothing reaches `knowledge/` without passing the gate.

## Keep it always on

To keep the face running in the background and surviving a reboot, run the built
server under **PM2** — see the bonus lesson. In short:

```bash
cd ~/vault/frontend && npm run build
VAULT_DIR=$HOME/vault HOST=127.0.0.1 PORT=5180 pm2 start build/index.js --name command-center
pm2 save && pm2 startup   # run the line it prints
```

`HOST=127.0.0.1` matters. The face has no login, and every gate lives on it —
approve, reject, commit, complete. Left on the default the server answers on
every address the machine has, so anyone on your café or office Wi-Fi could
sign in your name. Bound to `127.0.0.1` it answers only this computer.

## The rule that never moves

Non-sensitive content only. Reads run free; writes wait for your review. The AI
drafts, does the work, and stops at every gate. You hold the judgment.
