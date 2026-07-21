<script>
  let { data } = $props();
  const p = data.project;
  const cls = (s) => (s === 'proposed' ? 'st-proposed' : s === 'done' || s === 'shipped' || s === 'accepted' || s === 'committed' ? 'st-done' : '');

  let tab = $state('plans');
  const tabs = $derived([
    { id: 'plans', label: 'Plans', n: data.plans.length },
    { id: 'decisions', label: 'Decisions', n: data.adrs.length },
    { id: 'work', label: 'Work items', n: data.loose.length }
  ]);
</script>

<a class="back" href="/projects">← projects</a>
<h1 style="margin-top:10px">{p.title}</h1>
<p class="sub">{p.goal || `status: ${p.status}`}</p>

<div class="tabs">
  {#each tabs as t}
    <button class="tab" class:active={tab === t.id} onclick={() => (tab = t.id)}>
      {t.label} <span class="tab-n">{t.n}</span>
    </button>
  {/each}
</div>

{#if tab === 'plans'}
  <!-- PLANS — click a plan to open its board (commit / reject live there). -->
  {#if data.plans.length === 0}
    <div class="empty">No plans yet. Draft one from the terminal: <code>vault plan {p.name} "the outcome"</code></div>
  {:else}
    <div class="rows">
      {#each data.plans as pl}
        <a class="row" href="/projects/{p.name}/plan/{pl.slug}">
          <span class="row-title">{pl.title}</span>
          <span class="chip {cls(pl.status)}">{pl.status}</span>
        </a>
      {/each}
    </div>
  {/if}
{:else if tab === 'decisions'}
  <!-- DECISIONS — read-only here; they are gated in the Inbox. -->
  {#if data.adrs.length === 0}
    <div class="empty">No decisions recorded yet.</div>
  {:else}
    <div class="rows">
      {#each data.adrs as a}
        <a class="row" href="/projects/{p.name}/{a.slug}">
          <span class="row-title">{a.title}</span>
          <span class="chip {cls(a.status)}">{a.status}</span>
        </a>
      {/each}
    </div>
  {/if}
{:else}
  <!-- WORK ITEMS — standalone (not under a plan). -->
  {#if data.loose.length === 0}
    <div class="empty">No standalone work items. Everything lives under a plan.</div>
  {:else}
    <div class="rows">
      {#each data.loose as t}
        <a class="row" href="/projects/{p.name}/{t.slug}">
          <span class="row-title">{t.title}</span>
          <span class="chip {cls(t.status)}">{t.status}</span>
        </a>
      {/each}
    </div>
  {/if}
{/if}
