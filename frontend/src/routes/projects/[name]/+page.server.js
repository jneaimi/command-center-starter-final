import { project } from '$lib/server/vault.js';
import { error } from '@sveltejs/kit';

export const load = ({ params }) => {
  const p = project(params.name);
  if (!p) throw error(404, `No project named “${params.name}”.`);
  const of = (k) => p.artifacts.filter((a) => a.kind === k);
  return {
    project: { name: p.name, title: p.title, status: p.status, goal: p.goal },
    adrs: of('adr'),
    plans: of('plan'),
    // work items not attached to any plan/scope — historical, shown read-only
    loose: of('task').filter((t) => !t.parent)
  };
};
