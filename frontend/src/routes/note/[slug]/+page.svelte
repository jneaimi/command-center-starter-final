<script>
  import { renderMarkdown } from '$lib/md.js';
  let { data } = $props();
  const n = data.note;
</script>

<a class="back" href="/">← back</a>
<h1 style="margin-top:10px">{n.title}</h1>
<div class="meta" style="margin-bottom:20px">
  <span class="chip">{n.zone}</span>
  <!-- proposed is not settled: say so on the note itself, not just in the inbox -->
  {#if n.status}<span class="chip" class:st-proposed={n.status === 'proposed'}>{n.status}</span>{/if}
  {#each n.tags as t}<span class="chip">{t}</span>{/each}
  <span class="date">{n.created}</span>
</div>

{#if n.zone === 'inbox' && n.status === 'proposed'}
  <div class="decision-gate">
    <span>This is a capture, not knowledge yet. It waits for your signature.</span>
    <span class="actions"><a class="btn approve" href="/inbox">File it at the gate →</a></span>
  </div>
{/if}

<div class="note-body">{@html renderMarkdown(n.body)}</div>
