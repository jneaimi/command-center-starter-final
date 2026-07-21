<script>
  import { renderMarkdown } from '$lib/md.js';
  let { data } = $props();
  const n = data.note;
</script>

<a class="back" href="/">← back</a>
<h1 style="margin-top:10px">{n.title}</h1>
<div class="meta" style="margin-bottom:20px">
  <span class="chip">{n.zone}</span>
  {#each n.tags as t}<span class="chip">{t}</span>{/each}
  <span class="date">{n.created}</span>
</div>

<div class="note-body">{@html renderMarkdown(n.body)}</div>
