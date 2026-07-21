import { recent, search } from '$lib/server/vault.js';

export const load = ({ url }) => {
  const q = url.searchParams.get('q')?.trim() || '';
  return {
    q,
    recent: recent(6),
    results: q ? search(q) : null
  };
};
