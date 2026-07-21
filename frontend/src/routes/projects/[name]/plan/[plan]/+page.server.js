import { planBoard, commit, commitScope, gateApprove, gateReject } from '$lib/server/vault.js';
import { error, fail } from '@sveltejs/kit';

export const load = ({ params }) => {
  const board = planBoard(params.name, params.plan);
  if (!board) throw error(404, `No plan “${params.plan}” in ${params.name}.`);
  return { name: params.name, board };
};

// Every write on the board is a HUMAN move: commit the plan, commit a scope, or
// gate a task in review. The AI's moves (claim, submit) happen from the terminal
// — and the AI can never reach `done`, here or there.
export const actions = {
  commitPlan: async ({ params }) => {
    try { commit(params.name, params.plan); return { done: 'plan committed' }; }
    catch (e) { return fail(400, { error: e.message }); }
  },
  commitScope: async ({ request, params }) => {
    const slug = String((await request.formData()).get('slug') || '');
    try { const r = commitScope(params.name, slug); return { done: `scope committed — ${r.moved} task(s) moved to planning` }; }
    catch (e) { return fail(400, { error: e.message }); }
  },
  approve: async ({ request, params }) => {
    const slug = String((await request.formData()).get('slug') || '');
    try { gateApprove(params.name, slug); return { done: `approved “${slug}” — completed` }; }
    catch (e) { return fail(400, { error: e.message }); }
  },
  reject: async ({ request, params }) => {
    const f = await request.formData();
    const slug = String(f.get('slug') || '');
    const reason = String(f.get('reason') || '');
    try { gateReject(params.name, slug, reason); return { done: `sent “${slug}” back to planning` }; }
    catch (e) { return fail(400, { error: e.message }); }
  }
};
