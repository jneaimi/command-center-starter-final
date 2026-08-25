---
title: Rebase vs merge — which and when
type: learning
created: 2026-06-26
tags: [git, workflow]
---

# Rebase vs merge — which and when

Both integrate changes; they differ in the **history** they leave.

- **Merge** keeps the true shape — a merge commit records "these two lines met
  here." Honest, but noisy on busy branches.
- **Rebase** replays your commits on top of the target — linear, clean history,
  but it **rewrites** commit hashes.

## My rule
- Rebase my **local, unpushed** work to tidy it before a PR.
- **Never** rebase a branch others have pulled — that rewrites shared history.
- Merge to integrate a finished PR (the merge commit is a useful landmark).

Part of the everyday workflow — see [[how-this-works]] for the command set.
