# Vault — rules

Standing rules for this vault. Zone folders (e.g. `projects/`) add their own
CLAUDE.md on top of these.

1. Non-sensitive content only.
2. Every note has frontmatter: `title`, `type`, `created` (YYYY-MM-DD), `tags`.
3. Note types: `reference` · `learning` · `decision` · `project` (+ `adr`,
   `plan`, `scope`, `work-item` inside projects).
4. Names in kebab-case. One idea per note.
5. Every note earns at least one link. No orphans, no dangling links.
6. Keep `knowledge/index.md` current — it is the front door.
7. Every ADR carries a `status` line (proposed → accepted → shipped).
8. Project work follows the plan model: a `plan` states a `goal`, a `scope`
   slices a plan (`parent`), a `work-item` attaches to a scope or a plan.
   An `adr` records a decision, off to the side of that spine.

The write path: notes enter through the doorway — `bin/vault` — where
the doctor checks the form before anything lands. Writes stop as
`status: proposed`; the human reviews the `git diff` and commits. A capture waits
in `inbox/` until a human accepts it — on the Inbox page, or `vault accept
<slug>` — which moves it into `knowledge/` and links it from the index. The doctor
(`doctor.sh`) re-checks the whole vault any time: `run the doctor`.
