import { getArtifact, commit, rejectDecision } from '$lib/server/vault.js';
import { error, fail } from '@sveltejs/kit';

export const load = ({ params }) => {
  const a = getArtifact(params.name, params.slug);
  if (!a) throw error(404, `No item “${params.slug}” in ${params.name}.`);
  return { artifact: a };
};

// Approve / reject a proposed decision (ADR) right here on its page — the same
// Human-Gate action the Inbox offers, with the full decision in front of you.
export const actions = {
  approve: async ({ params }) => {
    try { commit(params.name, params.slug); return { done: 'approved' }; }
    catch (e) { return fail(400, { error: e.message }); }
  },
  reject: async ({ params }) => {
    try { rejectDecision(params.name, params.slug); return { done: 'rejected' }; }
    catch (e) { return fail(400, { error: e.message }); }
  }
};
