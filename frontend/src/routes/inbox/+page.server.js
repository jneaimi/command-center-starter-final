import {
  pendingNotes, rejectedNotes, acceptNote, rejectNote,
  pendingDecisions, commit, rejectDecision
} from '$lib/server/vault.js';
import { fail } from '@sveltejs/kit';

// The Human-Gate queue, both halves: captured notes waiting to be filed, and
// proposed ADRs and plans waiting to be committed. Nothing the AI drafts is
// live until it passes through here.
export const load = () => ({
  notes: pendingNotes(),
  rejected: rejectedNotes(),
  pending: pendingDecisions()
});

// The face makes writes only through this one governed door.
const slugOf = async (request) => String((await request.formData()).get('slug') || '');
const pairOf = async (request) => {
  const f = await request.formData();
  return [String(f.get('project') || ''), String(f.get('slug') || '')];
};

export const actions = {
  // a capture becomes knowledge — or a logged no
  acceptNote: async ({ request }) => {
    const slug = await slugOf(request);
    try { acceptNote(slug); return { done: 'filed', slug }; }
    catch (e) { return fail(400, { error: e.message }); }
  },
  rejectNote: async ({ request }) => {
    const slug = await slugOf(request);
    try { rejectNote(slug); return { done: 'rejected', slug }; }
    catch (e) { return fail(400, { error: e.message }); }
  },
  // a decision is greenlit for implementation — or refused
  commit: async ({ request }) => {
    const [project, slug] = await pairOf(request);
    try { commit(project, slug); return { done: 'committed', slug }; }
    catch (e) { return fail(400, { error: e.message }); }
  },
  reject: async ({ request }) => {
    const [project, slug] = await pairOf(request);
    try { rejectDecision(project, slug); return { done: 'rejected', slug }; }
    catch (e) { return fail(400, { error: e.message }); }
  }
};
