<script>
  let { data } = $props();
</script>

<h1>Home</h1>
<p class="sub">Everything in your command center, at a glance.</p>

<form class="search" method="GET" action="/">
  <input name="q" placeholder="Search your vault…" value={data.q} autocomplete="off" />
  <button type="submit">Search</button>
</form>

{#if data.results}
  <h2>{data.results.length} result{data.results.length === 1 ? '' : 's'} for “{data.q}”</h2>
  {#if data.results.length === 0}
    <div class="empty">Nothing matched. Try another word — or <a href="/">clear the search</a>.</div>
  {:else}
    <div class="cards">
      {#each data.results as r}
        <a class="card" href={r.href}>
          <div class="title">{r.title}</div>
          <div class="ex">{r.excerpt}</div>
          <div class="meta"><span class="chip">{r.kind || r.zone}</span><span class="date">{r.created}</span></div>
        </a>
      {/each}
    </div>
  {/if}
{:else}
  <h2>Recent</h2>
  {#if data.recent.length === 0}
    <div class="empty">No notes yet. Capture one from the terminal to see it here.</div>
  {:else}
    <div class="cards">
      {#each data.recent as n}
        <a class="card" href="/note/{n.slug}">
          <div class="title">{n.title}</div>
          <div class="ex">{n.excerpt}</div>
          <div class="meta">
            {#each n.tags as t}<span class="chip">{t}</span>{/each}
            <span class="date">{n.created}</span>
          </div>
        </a>
      {/each}
    </div>
  {/if}
{/if}
