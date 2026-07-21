<script>
  import '../app.css';
  import { page } from '$app/stores';
  let { data, children } = $props();
</script>

<div class="app">
  <aside class="sidebar">
    <div class="brand">My Command Center</div>
    <nav>
      <a href="/" class:active={$page.url.pathname === '/'}>Home</a>
      <a href="/knowledge" class:active={$page.url.pathname.startsWith('/knowledge')}>
        Knowledge <span class="badge">{data.counts.knowledge}</span>
      </a>
      <a href="/projects" class:active={$page.url.pathname.startsWith('/projects')}>
        Projects <span class="badge">{data.counts.projects}</span>
      </a>
      <a href="/inbox" class:active={$page.url.pathname.startsWith('/inbox')}>
        Inbox <span class="badge accent">{data.counts.inbox}</span>
      </a>
    </nav>
  </aside>

  <main class:wide={$page.url.pathname.includes('/plan/')}>
    {@render children()}
  </main>
</div>
