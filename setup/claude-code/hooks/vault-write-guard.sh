#!/usr/bin/env bash
# vault-write-guard: the AI drafts, you sign. And the vault has one door.
#
# Claude Code runs this before every Bash / Write / Edit call and blocks the
# call if it exits 2. Other agents have their own mechanisms or none; the rules
# themselves live in AGENTS.md at the top of the vault, and bin/vault checks the
# gates for itself, so the vault is never defended by this file alone.
#
# Laws:
#   1 · signing is the human's — no git commit/push, and no `vault accept`,
#       `vault reject`, or `vault commit` (approving is the human's signature)
#   2 · notes go through the doorway (no direct Write/Edit into the vault)
#   3 · deleting in the vault needs your hands
#   4 · the AI moves its own cards only through `vault claim` / `vault submit`,
#       and NEVER completes work — the Human Gate does that on the board.
input="$(cat)"
block() { echo "vault-write-guard: $1" >&2; exit 2; }

# Where the vault lives. install.sh writes this next to the hook, because the
# vault does not have to be at ~/vault (see `install.sh --dir`). If the file is
# missing we fall back to the default rather than guarding nothing.
vault_root="$(cat "$HOME/.claude/hooks/vault-dir" 2>/dev/null)"
[ -n "$vault_root" ] || vault_root="$HOME/vault"

# Reading the hook's JSON needs python3 or node. Decide WHICH one out here, in
# the main shell: `block` inside a $( ) substitution would only kill the subshell
# and the guard would sail on with an empty tool name. If neither runtime is
# present we cannot tell what the call was, so we FAIL CLOSED — a guard that
# waves everything through on a machine missing a runtime is worse than no guard
# at all, because it looks like one.
if command -v python3 >/dev/null 2>&1; then json_runtime=python3
elif command -v node >/dev/null 2>&1; then json_runtime=node
else
  block "cannot read this tool call — neither python3 nor node is on PATH. Refusing rather than waving it through. Install one, or remove this hook deliberately."
fi

json_get() {  # json_get <key> [nested key]
  if [ "$json_runtime" = python3 ]; then
    printf '%s' "$input" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for k in sys.argv[1:]:
    d = d.get(k, "") if isinstance(d, dict) else ""
print(d if isinstance(d, str) else "")
' "$@" 2>/dev/null
  else
    printf '%s' "$input" | node -e '
let s = "";
process.stdin.on("data", (d) => (s += d)).on("end", () => {
  let d; try { d = JSON.parse(s); } catch { return; }
  for (const k of process.argv.slice(1)) d = d && typeof d === "object" ? d[k] ?? "" : "";
  process.stdout.write(typeof d === "string" ? d : "");
});
' "$@" 2>/dev/null
  fi
}

tool=$(json_get tool_name)
[ -n "$tool" ] || exit 0   # not a tool-call shape we know; nothing to judge

case "$tool" in
  Write|Edit)
    # law 2: notes go through the doorway
    path=$(json_get tool_input file_path)
    case "$path" in
      "$vault_root/knowledge/"*|"$vault_root/projects/"*|"$vault_root/templates/"*|"$vault_root/inbox/"*)
        block "notes go through the doorway. Use the vault command (capture / adr / plan / scope / task / claim / submit) — never edit a vault file by hand." ;;
    esac ;;

  Bash)
    cmd=$(json_get tool_input command)
    case "$cmd" in
      # law 1: signing is the human's — code AND governance
      *"git commit"*|*"git push"*)
        block "committing is the human's signature. Show the draft and stop." ;;
      *"vault accept"*|*"vault reject"*|*"vault commit"*)
        block "approving is the human's signature, not the terminal's. You draft (capture / adr / plan / scope / task); a human accepts, rejects, or commits — on the board, or their own terminal. Stop here." ;;
      # law 3: deleting in the vault needs your hands
      *"rm "*vault*)
        block "deleting in the vault needs your hands." ;;
      # law 4a: completing work is the Human Gate's move, never the AI's
      *"vault done"*|*"vault complete"*)
        block "completing work is the Human Gate's call, not the terminal's. Use 'vault submit', then let a human approve it on the board (review -> completed)." ;;
      # the doorway checks its caller for itself; do not help anything lie to it
      *VAULT_I_AM_HUMAN*)
        block "VAULT_I_AM_HUMAN is how a person tells the doorway they are at a keyboard. Setting it here would be a lie. Draft, show, and stop." ;;
    esac
    # law 4b: don't hand-edit a vault artifact file to move it — that would skip
    # the doorway's checks (a task can only be claimed once it's committed to
    # planning, and it can never be marked completed from here). Force the CLI.
    if printf '%s' "$cmd" | grep -Eq '(sed -i|tee |dd |truncate|>)' \
       && printf '%s' "$cmd" | grep -Eq '(vault/(projects|knowledge|inbox|templates)/|/(adr|plan|scope|wi|task)-[a-z0-9-]*\.md)'; then
      block "don't edit a vault file by hand. Task moves go through the door: 'vault claim' (to active) and 'vault submit' (to review). A task can only be claimed once a human has committed its scope, and only the Human Gate completes it."
    fi ;;
esac
exit 0
