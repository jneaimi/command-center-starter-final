---
title: Static-site hosting, plainly
type: reference
created: 2026-07-19
tags: [hosting, deploy, sveltekit]
---

# Static-site hosting, plainly

A static site is just files — HTML, CSS, a little JS. Hosting it means putting
those files somewhere with a public address.

## The shape
1. **Build** — the framework turns your source into a `build/` (or `dist/`)
   folder of plain files.
2. **Upload** — a static host serves that folder. Most connect to a git repo and
   rebuild on every push.
3. **Address** — you get a free subdomain (`yourname.pages.dev`) now; point a real
   domain at it later.

## For a SvelteKit profile page
Use the static adapter so the build is plain files (no server needed). Then any
static host works. Ship on the free subdomain first — a real domain is a
five-minute upgrade, not a launch blocker.
