#!/usr/bin/env bash
# vault-write-guard: the AI drafts, you sign. And the vault has one door.
# Laws:
#   1 · committing is the human's signature (no git commit/push)
#   2 · notes go through the doorway (no direct Write/Edit into the vault)
#   3 · deleting in the vault needs your hands
#   4 · the AI moves its own cards only through `vault claim` / `vault submit`,
#       and NEVER completes work — the Human Gate does that on the board.
input="$(cat)"
tool=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null)
block() { echo "vault-write-guard: $1" >&2; exit 2; }

case "$tool" in
  Write|Edit)
    # law 2: notes go through the doorway
    path=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
    case "$path" in
      "$HOME/vault/knowledge/"*|"$HOME/vault/projects/"*|"$HOME/vault/templates/"*|"$HOME/vault/inbox/"*)
        block "notes go through the doorway. Use the vault command (capture / adr / plan / scope / task / claim / submit) — never edit a vault file by hand." ;;
    esac ;;

  Bash)
    cmd=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)
    case "$cmd" in
      # law 1: committing is the human's signature
      *"git commit"*|*"git push"*)
        block "committing is the human's signature. Show the draft and stop." ;;
      # law 3: deleting in the vault needs your hands
      *"rm "*vault*)
        block "deleting in the vault needs your hands." ;;
      # law 4a: completing work is the Human Gate's move, never the AI's
      *"vault done"*|*"vault complete"*)
        block "completing work is the Human Gate's call, not the terminal's. Use 'vault submit', then let a human approve it on the board (review → completed)." ;;
    esac
    # law 4b: don't hand-edit a vault artifact file to move it — that would skip
    # the doorway's checks (a task can only be claimed once it's committed to
    # planning, and it can never be marked completed from here). Force the CLI.
    if printf '%s' "$cmd" | grep -Eq '(sed -i|tee |dd |truncate|>)' \
       && printf '%s' "$cmd" | grep -Eq '(vault/(projects|knowledge|inbox|templates)/|/(adr|plan|scope|wi|task)-[a-z0-9-]*\.md)'; then
      block "don't edit a vault file by hand. Task moves go through the door: 'vault claim' (→ active) and 'vault submit' (→ review). A task can only be claimed once a human has committed its scope, and only the Human Gate completes it."
    fi ;;
esac
exit 0
