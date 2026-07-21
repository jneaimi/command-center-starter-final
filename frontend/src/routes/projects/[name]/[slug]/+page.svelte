<script>
  import { enhance } from '$app/forms';
  import { renderMarkdown } from '$lib/md.js';
  let { data, form } = $props();
  const a = $derived(data.artifact);
  const isProposedAdr = $derived(a.kind === 'adr' && a.status === 'proposed');
</script>

<a class="back" href="/projects/{a.project}">← {a.project}</a>
<h1 style="margin-top:10px">{a.title}</h1>
<div class="meta" style="margin-bottom:20px">
  <span class="chip">{a.kind}</span>
  <span class="chip">{a.status}</span>
  <span class="date">{a.created}</span>
</div>

{#if form?.done}
  <div class="flash">{form.done === 'approved' ? 'Approved — this decision is now accepted.' : 'Rejected — logged.'}</div>
{:else if form?.error}
  <div class="flash">Couldn't do that: {form.error}</div>
{/if}

{#if isProposedAdr}
  <!-- the Human Gate for a decision, right on its page -->
  <div class="decision-gate">
    <span>This decision is waiting on you.</span>
    <div class="actions">
      <form method="POST" action="?/approve" use:enhance>
        <button class="btn approve" type="submit">Approve</button>
      </form>
      <form method="POST" action="?/reject" use:enhance>
        <button class="btn reject" type="submit">Reject</button>
      </form>
    </div>
  </div>
{/if}

<div class="note-body">{@html renderMarkdown(a.body)}</div>
