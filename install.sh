#!/usr/bin/env bash
# install.sh — set up your command center on this machine.
#
#   git clone https://github.com/jneaimi/command-center-starter-final.git
#   bash command-center-starter-final/install.sh
#
# Options:
#   --dir <path>   install the vault somewhere other than ~/vault
#   --no-agent     skip the Claude Code extras even if Claude Code is installed
#   -h, --help
#
# What it does, in order. Nothing is ever deleted — only archived.
#   1. Checks this machine has what the tools need, and says so plainly.
#   2. Places the vault (archiving any vault already there).
#   3. Wires whichever agent you have. Every agent reads AGENTS.md from the
#      vault; Claude Code additionally gets a hook that enforces it.
#   4. Puts the vault's bin/ on your PATH.
#   5. Verifies the install and prints a PASS/FAIL block.
#
# The face (the web app) is started separately — see the end of the output.
set -u

ts=$(date +%Y%m%d-%H%M%S)
here="$(cd "$(dirname "$0")" && pwd)"
dest="$HOME/vault"
wire_claude=auto
pass=0; fail=0; warn=0
ok()   { echo "  ✔ $1"; pass=$((pass+1)); }
bad()  { echo "  ✘ $1"; fail=$((fail+1)); }
note() { echo "  • $1"; }
soft() { echo "  ! $1"; warn=$((warn+1)); }

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) dest="$2"; shift 2 ;;
    --no-agent) wire_claude=no; shift ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "install: unknown option '$1' (try --help)" >&2; exit 2 ;;
  esac
done

echo "== Command Center installer =="

# ---- 1 · preflight ----------------------------------------------------------
# Fail here, with a sentence a person can act on, rather than halfway through.
missing=0
command -v git >/dev/null 2>&1 || { echo "  ✘ git is not installed — install it and run this again."; missing=1; }
if command -v node >/dev/null 2>&1; then
  nv=$(node -v | sed 's/^v//'); nmaj=${nv%%.*}
  if [ "$nmaj" -lt 18 ] 2>/dev/null; then
    echo "  ✘ Node $nv is too old — the web face needs 18.13 or newer. Install Node LTS and run this again."
    missing=1
  fi
else
  echo "  ✘ Node is not installed — the web face needs 18.13 or newer (nodejs.org, or your package manager)."
  missing=1
fi
[ "$missing" -eq 0 ] || { echo; echo "Fix the ✘ lines above, then run this again. Nothing was changed."; exit 2; }
echo "  preflight ok"

# ---- 2 · place the vault ----------------------------------------------------
mkdir -p "$HOME/archive"
if [ "$here" != "$dest" ]; then
  if [ -e "$dest" ]; then
    mv "$dest" "$HOME/archive/vault-backup-$ts"
    echo "  archived the vault already at $dest -> ~/archive/vault-backup-$ts"
  fi
  cp -R "$here" "$dest"
  echo "  vault placed at $dest"
else
  echo "  already running from $dest"
fi
cd "$dest" || { echo "install: cannot enter $dest" >&2; exit 2; }

# ---- 3 · wire the agent -----------------------------------------------------
# AGENTS.md at the top of the vault is the contract, and every CLI agent that
# follows the convention reads it with no setup at all. Claude Code is the one
# that can do better than convention: a PreToolUse hook that blocks the
# forbidden calls outright. So that is the only agent with anything to install.
echo "  agent wiring:"
note "AGENTS.md is in the vault — Codex, Cursor, Gemini CLI, Aider and friends read it as-is"
if [ "$wire_claude" = no ]; then
  note "skipping the Claude Code extras (--no-agent)"
elif command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
  mkdir -p ~/.claude/hooks
  backup() {  # backup <path> — move an existing file aside before replacing it
    [ -e "$1" ] || return 0
    mkdir -p "$HOME/archive/dot-claude-backup-$ts"
    cp -R "$1" "$HOME/archive/dot-claude-backup-$ts/"
  }
  backup ~/.claude/CLAUDE.md
  backup ~/.claude/settings.json
  backup ~/.claude/hooks/vault-write-guard.sh
  cp setup/claude-code/CLAUDE.md            ~/.claude/CLAUDE.md
  cp setup/claude-code/settings.json        ~/.claude/settings.json
  cp setup/claude-code/hooks/vault-write-guard.sh ~/.claude/hooks/vault-write-guard.sh
  chmod +x ~/.claude/hooks/vault-write-guard.sh
  # tell the guard where the vault actually is — it need not be ~/vault
  printf '%s\n' "$dest" > ~/.claude/hooks/vault-dir
  note "Claude Code found — installed the guard hook, settings, and global rules"
  [ -d "$HOME/archive/dot-claude-backup-$ts" ] && note "your previous ~/.claude files -> ~/archive/dot-claude-backup-$ts"
  # a stray global copy of the skill would shadow the one that ships in the vault
  [ -d ~/.claude/skills/my-vault ] && mv ~/.claude/skills/my-vault "$HOME/archive/my-vault-global-$ts"
else
  note "Claude Code not found — nothing else to install. AGENTS.md does the job."
fi

# ---- 4 · tools executable + PATH --------------------------------------------
chmod +x bin/vault doctor.sh
added=0; found_rc=0
for rc in ~/.zshrc ~/.bashrc ~/.profile; do
  [ -f "$rc" ] || continue
  found_rc=1
  grep -q "$dest/bin" "$rc" || { printf '\nexport PATH="%s/bin:$PATH"\n' "$dest" >> "$rc"; added=1; }
done
export PATH="$dest/bin:$PATH"
if [ "$added" -eq 1 ]; then
  echo "  $dest/bin added to PATH (open a new terminal to pick it up)"
elif [ "$found_rc" -eq 1 ]; then
  echo "  $dest/bin was already on your PATH"
else
  soft "no ~/.zshrc, ~/.bashrc or ~/.profile to edit — add this line to your shell's startup file yourself:"
  echo "      export PATH=\"$dest/bin:\$PATH\""
fi

# ---- 5 · verify -------------------------------------------------------------
echo "== Verifying =="
VAULT_DIR="$dest" ./doctor.sh >/dev/null 2>&1  && ok "the doctor: clean bill of health"        || bad "the doctor found problems — run ./doctor.sh"
bin/vault help >/dev/null 2>&1                 && ok "the doorway answers: vault help"         || bad "bin/vault won't run"
VAULT_DIR="$dest" bin/vault capture "" >/dev/null 2>&1; [ $? -eq 2 ] \
                                               && ok "a malformed note is refused (exit 2)"    || bad "an empty capture was not refused"
VAULT_DIR="$dest" bin/vault accept x >/dev/null 2>&1; [ $? -eq 2 ] \
                                               && ok "the gates refuse a non-human caller"     || bad "a gate opened for a script"
ok "node $(node -v) — the face can run"
if command -v python3 >/dev/null 2>&1 || command -v node >/dev/null 2>&1; then
  ok "the guard can read a tool call (python3 or node present)"
else
  bad "neither python3 nor node — the guard would refuse everything"
fi
if [ -f ~/.claude/settings.json ]; then
  bash -n ~/.claude/hooks/vault-write-guard.sh 2>/dev/null && ok "the guard parses" || bad "the guard has a syntax error"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' ~/.claude/settings.json 2>/dev/null \
      && ok "settings.json is valid (guard registered)" || bad "settings.json is not valid JSON"
  else
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' ~/.claude/settings.json 2>/dev/null \
      && ok "settings.json is valid (guard registered)" || bad "settings.json is not valid JSON"
  fi
fi
command -v git >/dev/null 2>&1 && ok "git is installed" || bad "git is missing"

echo
if [ "$fail" -eq 0 ]; then
  if [ "$warn" -gt 0 ]; then echo "All $pass checks passed, with $warn thing to do by hand (the ! line above)."
  else echo "All $pass checks passed."; fi
  echo
  echo "  Point your agent at it:   cd $dest && <your agent>     # claude · codex · gemini · aider"
  echo "  Open its face (the app):  cd $dest/frontend && npm install && npm run dev"
  echo "  Read the map:             $dest/knowledge/how-this-works.md"
  echo
  echo "  Open a NEW terminal first, so the 'vault' command is on your PATH."
  exit 0
else
  echo "$pass passed, $fail FAILED — fix the ✘ lines above."
  exit 2
fi
