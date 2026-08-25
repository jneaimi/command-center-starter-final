# setup/

How each agent learns the rules, and how hard those rules bite.

## Every agent: `AGENTS.md`

`AGENTS.md` sits at the top of the vault. Codex, Cursor, Gemini CLI, Aider,
Claude Code and anything else that follows the convention read it when they start
work in that folder. There is nothing to install and nothing to configure — the
file is the interface.

That gets you **convention**: the agent has been told the rules, in the place it
looks for rules, in language written for it. Most agents most of the time will
follow them. But a told rule is not an enforced rule, which is why the other two
layers exist.

## Every agent: the doorway checks its caller

`bin/vault` refuses `accept`, `reject` and `commit` when it can tell an agent is
calling — no interactive terminal, or a known agent environment variable. This
needs no setup and works under every CLI.

It is a speed bump rather than a wall: `VAULT_I_AM_HUMAN=1` exists so a person in
a script can still open their own gates, and an agent that sets it is lying on
purpose. That is a deliberate trade. The web face is the surface where a human
signs, and it is the one that cannot be spoofed from a terminal at all.

## Claude Code: a real hook

`claude-code/` is the only agent-specific directory, because Claude Code is the
one that offers a place to stand:

```
claude-code/CLAUDE.md                   global rules, staged to ~/.claude/
claude-code/settings.json               registers the hook on Bash|Write|Edit
claude-code/hooks/vault-write-guard.sh  the four laws — see hooks/README.md
```

`install.sh` stages these only if it finds Claude Code. The hook runs before
every tool call and blocks the forbidden ones outright, so here the rules are
enforced rather than requested. It also writes `~/.claude/hooks/vault-dir` so the
guard knows where the vault is when you installed it somewhere other than
`~/vault`.

## Adding your own agent

If your agent supports pre-execution hooks, port `hooks/vault-write-guard.sh` —
it is fifty lines of `case` statements over a tool name and a command string, and
the laws it enforces are listed at the top of the file. Drop the result in a
folder next to `claude-code/` and teach `install.sh` to look for it.

If it does not, `AGENTS.md` plus the doorway's own check is what you get, and
that is the same deal every other agent gets today.

## What is not here

`todo-app/` is a tiny static page used by the `hello-world` project. It is not
part of the setup; it is something to build.
