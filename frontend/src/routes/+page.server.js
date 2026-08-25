import { recent, search, pendingNotes, pendingDecisions } from '$lib/server/vault.js';

export const load = ({ url }) => {
  const q = url.searchParams.get('q')?.trim() || '';
  const notes = pendingNotes().length;
  const decisions = pendingDecisions().length;
  return {
    q,
    recent: recent(6),
    results: q ? search(q) : null,
    // the gate, surfaced on the front door
    waiting: { notes, decisions, total: notes + decisions }
  };
};
