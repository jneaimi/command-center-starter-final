<script>
  import { enhance } from '$app/forms';
  import { invalidateAll } from '$app/navigation';
  import { onMount } from 'svelte';

  let { data, form } = $props();
  const name = $derived(data.name);
  const b = $derived(data.board);

  // which review card has its "send back" reason box open
  let rejecting = $state('');

  // MECHANIC 4 — respond to changes: the AI moves cards from the terminal
  // (claim, submit); this board re-asks the vault every few seconds so those
  // moves appear here on their own.
  onMount(() => {
    const t = setInterval(invalidateAll, 4000);
    return () => clearInterval(t);
  });
</script>

<a class="back" href="/projects/{name}">← {name}</a>
<h1 style="margin-top:10px">{b.plan.title}</h1>
<p class="sub">
  plan · <span class="chip {b.plan.accepted ? 'st-done' : 'st-proposed'}">{b.plan.status}</span>
  <span class="live">· board refreshing live</span>
</p>

{#if form?.done}
  <div class="flash">{form.done}</div>
{:else if form?.error}
  <div class="flash">Couldn't do that: {form.error}</div>
{/if}

{#if !b.plan.accepted}
  <div class="banner">
    {#if b.plan.decision && !b.plan.decision.accepted}
      <div>This plan is <strong>proposed</strong>. First approve its decision — <strong>{b.plan.decision.title}</strong> — then you can commit the plan.</div>
      <a class="btn approve" href="/projects/{name}/{b.plan.decision.slug}">Open the decision →</a>
    {:else}
      <div>This plan is <strong>proposed</strong>. Commit it to greenlight the work — then commit the scopes you want built.</div>
      <form method="POST" action="?/commitPlan" use:enhance>
        <button class="btn approve" type="submit">Commit plan</button>
      </form>
    {/if}
  </div>
{/if}

<div class="board">
  <!-- BACKLOG — everything drafted, grouped by scope. Commit a scope to release
       its tasks into planning. -->
  <section class="col">
    <header class="col-head">Backlog <span class="ct">{b.scopeGroups.filter((s) => !s.committed).length + b.looseBacklog.length}</span></header>
    <div class="col-body">
      {#each b.scopeGroups.filter((s) => !s.committed) as s (s.slug)}
        <div class="scope-card">
          <div class="scope-title">{s.title}</div>
          {#if s.excerpt}<div class="scope-ex">{s.excerpt}</div>{/if}
          {#if s.tasks.length}
            <ul class="scope-tasks">
              {#each s.tasks as t}<li>{t.title}</li>{/each}
            </ul>
          {:else}
            <div class="scope-ex muted">No tasks drafted yet — add them with <code>vault task</code>.</div>
          {/if}
          {#if b.plan.accepted}
            <form method="POST" action="?/commitScope" use:enhance>
              <input type="hidden" name="slug" value={s.slug} />
              <button class="btn approve full" type="submit">Commit scope →</button>
            </form>
          {:else}
            <div class="scope-locked">Commit the plan first ↑</div>
          {/if}
        </div>
      {/each}
      {#each b.looseBacklog as t (t.slug)}
        <a class="task-card" href="/projects/{name}/{t.slug}">
          <div class="tc-title">{t.title}</div>
        </a>
      {/each}
      {#if b.scopeGroups.filter((s) => !s.committed).length === 0 && b.looseBacklog.length === 0}
        <div class="col-empty">Nothing here.</div>
      {/if}
    </div>
  </section>

  <!-- PLANNING — committed, waiting for the AI to claim. -->
  <section class="col">
    <header class="col-head">Planning <span class="ct">{b.columns.planning.length}</span></header>
    <div class="col-body">
      {#each b.columns.planning as t (t.slug)}
        <div class="task-card">
          <a class="tc-title" href="/projects/{name}/{t.slug}">{t.title}</a>
          {#if t.scope}<span class="tag">{t.scope.replace('scope-', '')}</span>{/if}
          <div class="hint">AI claims it: <code>vault claim {name} {t.slug}</code></div>
        </div>
      {/each}
      {#if b.columns.planning.length === 0}<div class="col-empty">Nothing here.</div>{/if}
    </div>
  </section>

  <!-- ACTIVE — the AI is working it. -->
  <section class="col">
    <header class="col-head">Active <span class="ct">{b.columns.active.length}</span></header>
    <div class="col-body">
      {#each b.columns.active as t (t.slug)}
        <div class="task-card">
          <a class="tc-title" href="/projects/{name}/{t.slug}">{t.title}</a>
          {#if t.scope}<span class="tag">{t.scope.replace('scope-', '')}</span>{/if}
          <div class="hint">AI submits it: <code>vault submit {name} {t.slug}</code></div>
        </div>
      {/each}
      {#if b.columns.active.length === 0}<div class="col-empty">Nothing here.</div>{/if}
    </div>
  </section>

  <!-- REVIEW — the Human Gate. Approve → completed, or send back with a reason. -->
  <section class="col gate">
    <header class="col-head">Review <span class="ct">{b.columns.review.length}</span></header>
    <div class="col-body">
      {#each b.columns.review as t (t.slug)}
        <div class="task-card">
          <a class="tc-title" href="/projects/{name}/{t.slug}">{t.title}</a>
          {#if t.scope}<span class="tag">{t.scope.replace('scope-', '')}</span>{/if}
          <div class="gate-actions">
            <form method="POST" action="?/approve" use:enhance>
              <input type="hidden" name="slug" value={t.slug} />
              <button class="btn approve sm" type="submit">✓ Approve</button>
            </form>
            <button class="btn reject sm" type="button" onclick={() => (rejecting = rejecting === t.slug ? '' : t.slug)}>✗ Send back</button>
          </div>
          {#if rejecting === t.slug}
            <form class="reject-form" method="POST" action="?/reject" use:enhance={() => async ({ update }) => { rejecting = ''; await update(); }}>
              <input type="hidden" name="slug" value={t.slug} />
              <input class="reason" name="reason" placeholder="Why is it going back?" autocomplete="off" />
              <button class="btn reject sm" type="submit">Send back →</button>
            </form>
          {/if}
        </div>
      {/each}
      {#if b.columns.review.length === 0}<div class="col-empty">Nothing to gate.</div>{/if}
    </div>
  </section>

  <!-- COMPLETED — approved by the human. The AI can never put a card here. -->
  <section class="col">
    <header class="col-head">Completed <span class="ct">{b.columns.done.length}</span></header>
    <div class="col-body">
      {#each b.columns.done as t (t.slug)}
        <a class="task-card done" href="/projects/{name}/{t.slug}">
          <div class="tc-title">{t.title}</div>
          {#if t.scope}<span class="tag">{t.scope.replace('scope-', '')}</span>{/if}
        </a>
      {/each}
      {#if b.columns.done.length === 0}<div class="col-empty">Nothing here yet.</div>{/if}
    </div>
  </section>
</div>
