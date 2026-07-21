// ─────────────────────────────────────────────────────────────────────────
//  vault.js — the engine behind the face. The ONLY place that touches the
//  vault files. Pages ask it through the /api seam; they never read the disk.
//
//  Day-15 mechanics:  1·LOAD  2·LIST (in-memory index)  3·SEARCH  4·CHANGES
//
//  The work model (one status field = the lifecycle state):
//    ADR   — a decision. proposed → accepted → shipped (or rejected).
//    plan  — an outcome. proposed → accepted, then it has a board.
//    scope — a slice of a plan. proposed(backlog) → committed.
//    task  — the work. backlog → planned → active → review → done.
//
//  Who moves what:
//    • The human COMMITS a plan (inbox / project) and a scope (board),
//      and GATES review → done or → back-to-planning. On the face.
//    • The AI CLAIMS a task (planned→active) and SUBMITS it (active→review)
//      from the terminal. The AI can NEVER set done — the Hook blocks it,
//      and this engine only writes `done` from the human's gate action.
// ─────────────────────────────────────────────────────────────────────────
import { readdirSync, readFileSync, writeFileSync, statSync, existsSync, appendFileSync } from 'node:fs';
import { join, resolve, basename } from 'node:path';

const VAULT_DIR = process.env.VAULT_DIR ? resolve(process.env.VAULT_DIR) : resolve(process.cwd(), '..');
const ZONES = ['inbox', 'knowledge'];

// ── the in-memory index (mechanic 2), refreshed only on change (mechanic 4) ──
let index = { notes: [], projects: [], stamp: '' };

// The change signal (mechanic 4). A folder's clock does NOT tick when a file's
// *contents* change — only when files are added or removed. But the AI edits a
// task's status in place (claim, submit) from the terminal, so we must notice
// content edits too. We walk the vault and fold in every .md file's mtime; any
// edit anywhere changes the stamp, and build() re-reads.
function stamp() {
  let s = '';
  const walk = (dir) => {
    if (!existsSync(dir)) return;
    for (const f of readdirSync(dir)) {
      const full = join(dir, f);
      const st = statSync(full);
      if (st.isDirectory()) walk(full);
      else if (f.endsWith('.md')) s += full + ':' + st.mtimeMs + ';';
    }
  };
  for (const z of ZONES) walk(join(VAULT_DIR, z));
  walk(join(VAULT_DIR, 'projects'));
  return s;
}

function parse(file) {
  const raw = readFileSync(file, 'utf-8');
  const m = raw.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
  // drop a leading "# Title" line — the page shows the title on its own
  const body = (m ? m[2] : raw).trim().replace(/^#\s+.*\n+/, '');
  const fm = {};
  for (const line of (m ? m[1] : '').split('\n')) {
    const kv = line.match(/^(\w+):\s*(.*)$/);
    if (kv) fm[kv[1]] = kv[2].trim().replace(/^["']|["']$/g, '');
  }
  // first real line of prose, cleaned of markdown so cards read plainly
  const clean = (s) => s
    .replace(/\[\[([^\]]*)\]\]/g, (_, p) => p.split('|').pop().split('/').pop()) // wikilinks → words
    .replace(/[*_`]/g, '')      // bold / italic / code markers
    .replace(/^>\s*/, '');       // blockquote marker
  const first = body.split('\n').map((l) => l.trim()).filter((l) => l && !l.startsWith('#'))[0] || '';
  return { fm, body, excerpt: clean(first).slice(0, 150) };
}

// "[[../../knowledge/foo|bar]]" → "foo"; "[[plan-x]]" → "plan-x"
function cleanLink(v) {
  return (v || '').replace(/\[\[|\]\]/g, '').replace(/\|.*$/, '').replace(/^.*\//, '').trim();
}

function noteFrom(file, zone) {
  const { fm, body, excerpt } = parse(file);
  const slug = basename(file, '.md');
  return {
    slug, zone, body, excerpt,
    title: fm.title || slug,
    type: fm.type || 'note',
    created: fm.created || '',
    status: fm.status || '',
    tags: (fm.tags || '').replace(/[[\]]/g, '').split(',').map((t) => t.trim()).filter(Boolean)
  };
}

// a project artifact: classify by filename prefix (adr- / plan- / scope- / wi-)
function kindOf(slug) {
  if (slug.startsWith('adr-')) return 'adr';
  if (slug.startsWith('plan-')) return 'plan';
  if (slug.startsWith('scope-')) return 'scope';
  if (slug.startsWith('wi-') || slug.startsWith('task-')) return 'task';
  return 'note';
}

// The kanban column a status maps to. Backlog is the default — anything not
// yet planned (proposed, backlog, draft, blank) waits there.
export function columnOf(status) {
  const s = (status || '').toLowerCase();
  if (s === 'planned') return 'planning';
  if (s === 'active') return 'active';
  if (s === 'review') return 'review';
  if (s === 'done' || s === 'completed' || s === 'shipped') return 'done';
  return 'backlog';
}
const isBacklog = (status) => columnOf(status) === 'backlog';

// A scope is "committed" once it leaves the backlog states. (A scope doesn't
// flow through active/review like a task — it's either drafted or committed.)
function scopeCommitted(status) {
  const s = (status || '').toLowerCase();
  return !(s === '' || s === 'proposed' || s === 'backlog' || s === 'draft');
}
// A plan is "accepted" (greenlit) once the human commits it. Only then can its
// scopes be committed and its tasks flow.
function planAccepted(status) {
  const s = (status || '').toLowerCase();
  return s !== '' && s !== 'proposed' && s !== 'rejected';
}
// A decision (ADR) is accepted once the human approves it (or it shipped).
function decisionAccepted(status) {
  const s = (status || '').toLowerCase();
  return s === 'accepted' || s === 'shipped';
}

function artFrom(file, project) {
  const { fm, body, excerpt } = parse(file);
  const slug = basename(file, '.md');
  return {
    project, slug, body, excerpt,
    kind: kindOf(slug),
    title: fm.title || slug,
    status: fm.status || '',
    created: fm.created || '',
    goal: fm.goal || '',
    parent: cleanLink(fm.parent),
    governed_by: cleanLink(fm.governed_by)
  };
}

// LOAD (mechanic 1): read everything once; re-read only when the vault changed.
function build() {
  const s = stamp();
  if ((index.notes.length || index.projects.length) && s === index.stamp) return index;

  const notes = [];
  for (const zone of ZONES) {
    const dir = join(VAULT_DIR, zone);
    if (!existsSync(dir)) continue;
    for (const f of readdirSync(dir)) {
      if (f.endsWith('.md') && f !== 'index.md') notes.push(noteFrom(join(dir, f), zone));
    }
  }
  notes.sort((a, b) => (b.created || '').localeCompare(a.created || ''));

  const projects = [];
  const pdir = join(VAULT_DIR, 'projects');
  if (existsSync(pdir)) {
    for (const name of readdirSync(pdir)) {
      const dir = join(pdir, name);
      if (!existsSync(dir) || !statSync(dir).isDirectory()) continue;
      const arts = [];
      let home = null;
      for (const f of readdirSync(dir)) {
        if (!f.endsWith('.md')) continue;
        if (f === 'index.md') { home = parse(join(dir, f)); continue; }
        arts.push(artFrom(join(dir, f), name));
      }
      arts.sort((a, b) => (b.created || '').localeCompare(a.created || ''));
      projects.push({
        name,
        title: home?.fm.title || name,
        status: home?.fm.status || 'active',
        goal: home?.fm.goal || '',
        artifacts: arts
      });
    }
  }
  index = { notes, projects, stamp: s };
  return index;
}

function forget() { index = { notes: [], projects: [], stamp: '' }; }

// ── reads (run free) ──
export const recent = (n = 8) => build().notes.filter((x) => x.zone === 'knowledge').slice(0, n);
export const byZone = (zone) => build().notes.filter((x) => x.zone === zone);
export const getNote = (slug) => build().notes.find((x) => x.slug === slug) || null;

export const projects = () => build().projects;
export const project = (name) => build().projects.find((p) => p.name === name) || null;
export const getArtifact = (name, slug) => project(name)?.artifacts.find((a) => a.slug === slug) || null;

// The plans of a project, and a single plan.
export const plans = (name) => (project(name)?.artifacts || []).filter((a) => a.kind === 'plan');
export const planItem = (name, slug) => (project(name)?.artifacts || []).find((a) => a.kind === 'plan' && a.slug === slug) || null;

// The Human-Gate queue: proposed ADRs and plans, across every project. The inbox
// commits ADRs directly; plans it points at their project board to commit there.
export function pendingDecisions() {
  const out = [];
  for (const p of build().projects)
    for (const a of p.artifacts)
      if ((a.kind === 'adr' || a.kind === 'plan') && a.status === 'proposed') out.push(a);
  return out;
}

// THE BOARD (mechanic 2, per plan): scopes and their tasks, laid out in columns.
// Backlog holds the not-yet-committed scope groups; planning…done hold task cards.
export function planBoard(name, planSlug) {
  const p = project(name);
  if (!p) return null;
  const plan = p.artifacts.find((a) => a.kind === 'plan' && a.slug === planSlug);
  if (!plan) return null;

  const scopes = p.artifacts.filter((a) => a.kind === 'scope' && a.parent === planSlug);
  const scopeSlugs = new Set(scopes.map((s) => s.slug));
  const committed = new Set(scopes.filter((s) => scopeCommitted(s.status)).map((s) => s.slug));

  // tasks under this plan = parented to the plan itself, or to one of its scopes
  const tasks = p.artifacts.filter((a) => a.kind === 'task' && (a.parent === planSlug || scopeSlugs.has(a.parent)));
  const card = (t) => ({ project: name, slug: t.slug, title: t.title, status: t.status, column: columnOf(t.status), scope: scopeSlugs.has(t.parent) ? t.parent : null });

  const columns = { planning: [], active: [], review: [], done: [] };
  const looseBacklog = [];
  for (const t of tasks) {
    const c = card(t);
    if (c.column === 'backlog') {
      // backlog tasks of an un-committed scope show inside that scope's group
      if (c.scope && !committed.has(c.scope)) continue;
      looseBacklog.push(c);
    } else columns[c.column].push(c);
  }

  const scopeGroups = scopes.map((s) => ({
    slug: s.slug, title: s.title, excerpt: s.excerpt, status: s.status,
    committed: committed.has(s.slug),
    tasks: tasks.filter((t) => t.parent === s.slug).map(card)
  }));

  // the governing decision (if any) and whether it's accepted — the plan can't
  // be committed until it is.
  let decision = null;
  if (plan.governed_by) {
    const adr = p.artifacts.find((x) => x.kind === 'adr' && x.slug === plan.governed_by);
    if (adr) decision = { slug: adr.slug, title: adr.title, accepted: decisionAccepted(adr.status) };
  }

  return {
    plan: { slug: plan.slug, title: plan.title, status: plan.status, goal: plan.goal, excerpt: plan.excerpt, accepted: planAccepted(plan.status), decision },
    scopeGroups,
    looseBacklog,
    columns
  };
}

export const counts = () => ({
  knowledge: build().notes.filter((n) => n.zone === 'knowledge').length,
  projects: build().projects.length,
  inbox: pendingDecisions().length
});

// SEARCH (mechanic 3): notes + project artifacts, by title / body.
export function search(q) {
  q = (q || '').toLowerCase().trim();
  if (!q) return [];
  const hit = (t, b) => t.toLowerCase().includes(q) || b.toLowerCase().includes(q);
  const notes = build().notes.filter((n) => hit(n.title, n.body)).map((n) => ({ ...n, href: `/note/${n.slug}` }));
  const arts = build().projects.flatMap((p) => p.artifacts).filter((a) => hit(a.title, a.body))
    .map((a) => ({ ...a, href: `/projects/${a.project}/${a.slug}` }));
  return [...notes, ...arts];
}

// ── the governed writes ──
function artFile(name, slug) { return join(VAULT_DIR, 'projects', name, slug + '.md'); }
function setStatus(file, status) {
  writeFileSync(file, readFileSync(file, 'utf-8').replace(/^status:.*$/m, `status: ${status}`));
}

// COMMIT: greenlight a proposed ADR or plan for implementation (→ accepted).
// A plan can't be committed until its governing decision is accepted — you don't
// build on a decision the human hasn't said yes to yet.
export function commit(name, slug) {
  const file = artFile(name, slug);
  if (!existsSync(file)) throw new Error(`no such item: ${name}/${slug}`);
  const a = getArtifact(name, slug);
  if (a && a.kind !== 'adr' && a.kind !== 'plan') throw new Error('only ADRs and plans are committed here');
  if (a && a.kind === 'plan' && a.governed_by) {
    const adr = project(name)?.artifacts.find((x) => x.kind === 'adr' && x.slug === a.governed_by);
    if (adr && !decisionAccepted(adr.status)) throw new Error(`approve the decision “${adr.title}” first — a plan can't be committed while its decision is ${adr.status}`);
  }
  setStatus(file, 'accepted');
  forget();
  return { name, slug, status: 'accepted' };
}

// REJECT a decision (→ rejected).
export function rejectDecision(name, slug) {
  const file = artFile(name, slug);
  if (!existsSync(file)) throw new Error(`no such item: ${name}/${slug}`);
  setStatus(file, 'rejected');
  forget();
  return { name, slug, status: 'rejected' };
}

// COMMIT A SCOPE (human, on the board): the scope becomes committed and ALL of
// its tasks move to planning — ready for the AI to claim. A scope can only be
// committed once its PLAN is accepted; you can't release work from a plan the
// human hasn't greenlit yet.
export function commitScope(name, scopeSlug) {
  const p = project(name);
  if (!p) throw new Error(`no such project: ${name}`);
  const scope = p.artifacts.find((a) => a.kind === 'scope' && a.slug === scopeSlug);
  if (!scope) throw new Error(`no such scope: ${scopeSlug}`);
  const plan = p.artifacts.find((a) => a.kind === 'plan' && a.slug === scope.parent);
  if (!plan) throw new Error(`scope “${scopeSlug}” isn't under a plan`);
  if (!planAccepted(plan.status)) throw new Error(`commit the plan first — a scope can't be released while “${plan.slug}” is still ${plan.status}`);

  setStatus(artFile(name, scopeSlug), 'committed');
  // move EVERY task under the scope into planning (they come from backlog)
  const tasks = p.artifacts.filter((a) => a.kind === 'task' && a.parent === scopeSlug);
  for (const t of tasks) setStatus(artFile(name, t.slug), 'planned');
  forget();
  return { scope: scopeSlug, moved: tasks.length };
}

// THE GATE — approve (review → done). Only the human, only from review.
export function gateApprove(name, taskSlug) {
  const file = artFile(name, taskSlug);
  if (!existsSync(file)) throw new Error(`no such task: ${taskSlug}`);
  const a = getArtifact(name, taskSlug);
  if (columnOf(a?.status) !== 'review') throw new Error('only a task in review can be approved');
  setStatus(file, 'done');
  forget();
  return { task: taskSlug, status: 'done' };
}

// THE GATE — reject (review → planning) with a reason written onto the task.
export function gateReject(name, taskSlug, reason) {
  const file = artFile(name, taskSlug);
  if (!existsSync(file)) throw new Error(`no such task: ${taskSlug}`);
  const a = getArtifact(name, taskSlug);
  if (columnOf(a?.status) !== 'review') throw new Error('only a task in review can be sent back');
  setStatus(file, 'planned');
  const day = new Date().toISOString().slice(0, 10);
  appendFileSync(file, `\n\n## Sent back — ${day}\n> ${(reason || 'no reason given').trim()}\n`);
  forget();
  return { task: taskSlug, status: 'planned' };
}

export const vaultDir = () => VAULT_DIR;
