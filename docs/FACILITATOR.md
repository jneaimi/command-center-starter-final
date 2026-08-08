# Facilitator notes — Week-4 starter vault (v2)

This repo is the canonical **end-of-Day-12** vault: what a student's system
looks like after Weeks 2–3 went perfectly. It is the Day-13 adoption point and
the per-day restore fallback for the second half of the program. The Day-5
adoption point lives in the sibling repo `command-center-starter` (v1) — do
not mix them: v1 has no CLI, no live guard, no doctor; v2 assumes all three.

## Delivery model (Day 13, 09:00)

One command per student, AI not required for the install:

```bash
git clone https://github.com/jneaimi/command-center-starter-week4.git
bash command-center-starter-week4/install.sh
```

The installer is deliberately verbose and archive-only (nothing deleted;
previous vault → `~/archive/vault-pre-week4-<ts>`). It ends with a PASS/FAIL
verification block — **walk the room and check every screen says "All checks
passed"** before the concept segment. The Node check is part of it (Day 13's
SvelteKit lab needs Node before 09:30 — the workbook's prep item).

Students whose Weeks 2–3 vault is intact may keep it. The Day-13 prep bar is:
CLI + Hook + doctor + real notes. This repo IS that bar; a kept vault must
meet it (run `doctor.sh` + the three-bad-parcels check on theirs if unsure).

## Restore map

| Broke | Fix |
|---|---|
| Whole vault | re-run `install.sh` (archives the broken one first) |
| The doorway (`bin/vault`) | copy `bin/vault` from a fresh clone; `chmod +x` |
| The doctor | copy `doctor.sh`; `chmod +x` |
| The guard or its wiring | `setup/dot-claude/hooks/` → `~/.claude/hooks/` and `setup/dot-claude/settings.json` → `~/.claude/settings.json`; restart Claude |
| The skill | ships in the vault: `.claude/skills/my-vault/` — a PROJECT skill (Day-3/5 rule: vault tools live with the vault) |
| Global rules | `setup/dot-claude/CLAUDE.md` → `~/.claude/CLAUDE.md` |
| The todo app | `setup/todo-app/todo.html` → `~/todo-app/todo.html` |

## What "lived-in" means here (keep it intact)

- `projects/task-tracker/` carries the whole Week 2–3 trail: adr-003 (Day 5),
  adr-004 + five closed v1 work items (Day 8), adr-005 + two closed v2 items
  (Day 12), `wi-sync-across-devices` left open as the v3 seed. Day 14–16
  exercises lean on this history — do not trim it.
- `knowledge/` holds the six Week 2–3 lab captures alongside the original
  nine. They are the "real notes" the Day-13 page lists.
- `inbox/` holds four `status: proposed` captures. **These are Day 14's
  opening material** (the inbox/Human-Gate lab needs pending proposals on the
  morning it starts) — do not sign them into the vault beforehand.

## Terminology + canon (decisions applied here)

- **ADR-007:** the write-format check is **the doctor** (never "the
  Validator") — in `bin/vault`'s capture checks, in `doctor.sh`, in every doc.
- **House type system is canon** (operator decision 2026-07-15): capture types
  are `learning | reference` (+ `adr`, `work-item` via their verbs), zones
  `inbox/` (default) + `knowledge/`, `tags` always present, knowledge captures
  indexed. The Day-11 handout's divergent `note|task|idea` / `tasks/` model is
  being aligned to this — the repo is the reference implementation.
- `vault recent` + `vault search` (Day 12's cold open) are included in
  `bin/vault`.
- **The work model mirrors TeamSoul-lite** (operator request 2026-07-15):
  `plan` (states a `goal`) → `scope` (slices a plan via `parent`) → `task`
  (attaches to a scope or plan via `--scope`/`--plan`), with `adr` recording
  decisions off to the side. `vault tree <project>` renders the outline.
  Everything lands `proposed`/`planned` — the human still signs. The seeded
  example is `plan-version-3-sync` in the task tracker.

## Keeping it canonical

Source of truth is this repo itself. If a day's materials change the taught
anatomy of any artifact (CLI verb, guard law, doctor rule, skill wording),
change the artifact here in the same pass and re-verify: `bash install.sh` on
a scratch account, all checks green.
