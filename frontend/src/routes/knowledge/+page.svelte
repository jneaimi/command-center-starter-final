<script>
  let { data } = $props();
</script>

<h1>Knowledge</h1>
<p class="sub">Your settled notes — everything you've accepted into the vault.</p>

{#if data.notes.length === 0}
  <div class="empty">No notes yet. Accept a capture at the <a href="/inbox">inbox gate</a> and it lands here.</div>
{:else}
  <div class="cards">
    {#each data.notes as n}
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
