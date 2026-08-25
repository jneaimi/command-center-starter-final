<script>
  import { enhance } from '$app/forms';
  import { invalidateAll } from '$app/navigation';
  import { onMount } from 'svelte';

  let { data, form } = $props();
  const adrs = $derived(data.pending.filter((a) => a.kind === 'adr'));
  const plans = $derived(data.pending.filter((a) => a.kind === 'plan'));
  const waiting = $derived(data.notes.length + data.pending.length);

  const flash = {
    filed: (s) => `Filed “${s}” into knowledge.`,
    committed: (s) => `Committed “${s}” — greenlit.`,
    rejected: (s) => `Rejected “${s}” — logged.`
  };

  // MECHANIC 4 — respond to changes: re-ask the vault every few seconds, so a
  // note or decision the AI proposes from the terminal appears here on its own.
  onMount(() => {
    const t = setInterval(invalidateAll, 4000);
    return () => clearInterval(t);
  });
</script>

<h1>Inbox — the Human Gate</h1>
<p class="sub">
  Notes to file, decisions to approve, plans to greenlight.
  <span class="live">· refreshing live</span>
</p>

{#if form?.done}
  <div class="flash">{flash[form.done]?.(form.slug) ?? form.done}</div>
{:else if form?.error}
  <div class="flash">Couldn't do that: {form.error}</div>
{/if}

{#if waiting === 0}
  <div class="empty">
    Nothing waiting on you. 🎉<br />
    Captured notes and proposed ADRs and plans land here for your call.
  </div>
{:else}
  <!-- NOTES — a capture is a proposal. It is not knowledge until you say so. -->
  {#if data.notes.length}
    <h2>Notes to file</h2>
    {#each data.notes as n (n.slug)}
      <div class="proposal">
        <div class="meta" style="margin-bottom:6px">
          <span class="chip">{n.type}</span>
          <span class="chip st-proposed">proposed</span>
          <span class="date">{n.created}</span>
        </div>
        <a class="p-title" href="/note/{n.slug}" style="display:block">{n.title}</a>
        <div class="p-why">{n.excerpt || 'No body yet — open it to read the capture.'}</div>
        <div class="actions">
          <form method="POST" action="?/acceptNote" use:enhance>
            <input type="hidden" name="slug" value={n.slug} />
            <button class="btn approve" type="submit">Accept into knowledge</button>
          </form>
          <form method="POST" action="?/rejectNote" use:enhance>
            <input type="hidden" name="slug" value={n.slug} />
            <button class="btn reject" type="submit">Reject</button>
          </form>
        </div>
      </div>
    {/each}
  {/if}

  <!-- DECISIONS — approve or reject right here. -->
  {#if adrs.length}
    <h2>Decisions to approve</h2>
    {#each adrs as a (a.project + '/' + a.slug)}
      <div class="proposal">
        <div class="meta" style="margin-bottom:6px">
          <span class="chip">decision</span>
          <span class="chip">{a.project}</span>
        </div>
        <a class="p-title" href="/projects/{a.project}/{a.slug}" style="display:block">{a.title}</a>
        <div class="p-why">{a.goal || a.excerpt}</div>
        <div class="actions">
          <form method="POST" action="?/commit" use:enhance>
            <input type="hidden" name="project" value={a.project} />
            <input type="hidden" name="slug" value={a.slug} />
            <button class="btn approve" type="submit">Approve</button>
          </form>
          <form method="POST" action="?/reject" use:enhance>
            <input type="hidden" name="project" value={a.project} />
            <input type="hidden" name="slug" value={a.slug} />
            <button class="btn reject" type="submit">Reject</button>
          </form>
        </div>
      </div>
    {/each}
  {/if}

  <!-- PLANS — committed in the project, where the board is. -->
  {#if plans.length}
    <h2>Plans to greenlight</h2>
    {#each plans as a (a.project + '/' + a.slug)}
      <div class="proposal">
        <div class="meta" style="margin-bottom:6px">
          <span class="chip">plan</span>
          <span class="chip">{a.project}</span>
        </div>
        <div class="p-title">{a.title}</div>
        <div class="p-why">{a.goal || a.excerpt}</div>
        <div class="actions">
          <a class="btn board" href="/projects/{a.project}/plan/{a.slug}">Review &amp; commit on its board →</a>
        </div>
      </div>
    {/each}
  {/if}
{/if}

<!-- The record of your noes. Kept, not hidden. -->
{#if data.rejected.length}
  <h2>Rejected — kept as a record</h2>
  <div class="rows">
    {#each data.rejected as n (n.slug)}
      <a class="row" href="/note/{n.slug}">
        <span class="row-title">{n.title}</span>
        <span class="meta"><span class="chip">rejected</span><span class="date">{n.created}</span></span>
      </a>
    {/each}
  </div>
{/if}
