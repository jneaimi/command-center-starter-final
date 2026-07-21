#!/usr/bin/env bash
# install.sh — set up the finished command center on this machine.
#
#   git clone https://github.com/jneaimi/command-center-starter-final.git
#   bash command-center-starter-final/install.sh
#
# What it does, in order (nothing is ever deleted — only archived):
#   1. Places the vault at ~/vault (archives any vault already there).
#   2. Stages the ~/.claude side: global rules, the guard + settings, my-vault
#      skill (archives anything it replaces).
#   3. Makes the tools executable and puts ~/vault/bin on your PATH.
#   4. Verifies the install: the doctor, the doorway, the guard.
#
# The face (the SvelteKit app) lives in frontend/ — start it separately:
#   cd ~/vault/frontend && npm install && npm run dev
set -u

ts=$(date +%Y%m%d-%H%M%S)
here="$(cd "$(dirname "$0")" && pwd)"
pass=0; fail=0
ok()  { echo "  ✔ $1"; pass=$((pass+1)); }
bad() { echo "  ✘ $1"; fail=$((fail+1)); }

echo "== Command Center installer =="

# ---- 1 · place the vault at ~/vault -----------------------------------------
mkdir -p ~/archive
if [ "$here" != "$HOME/vault" ]; then
  if [ -e "$HOME/vault" ]; then
    mv "$HOME/vault" "$HOME/archive/vault-pre-week4-$ts"
    echo "  archived your previous vault -> ~/archive/vault-pre-week4-$ts"
  fi
  cp -R "$here" "$HOME/vault"
  echo "  vault placed at ~/vault"
else
  echo "  already running from ~/vault"
fi
cd "$HOME/vault"

# ---- 2 · stage the ~/.claude side --------------------------------------------
mkdir -p ~/.claude/hooks ~/.claude/skills
backup() {  # backup <path> — move an existing file/dir aside before replacing
  [ -e "$1" ] || return 0
  mkdir -p "$HOME/archive/dot-claude-backup-$ts"
  mv "$1" "$HOME/archive/dot-claude-backup-$ts/"
}
backup ~/.claude/CLAUDE.md
cp setup/dot-claude/CLAUDE.md ~/.claude/CLAUDE.md
backup ~/.claude/settings.json
cp setup/dot-claude/settings.json ~/.claude/settings.json
backup ~/.claude/hooks/vault-write-guard.sh
cp setup/dot-claude/hooks/vault-write-guard.sh ~/.claude/hooks/vault-write-guard.sh
backup ~/.claude/skills/my-vault
cp -R setup/dot-claude/skills/my-vault ~/.claude/skills/my-vault
# the Week-1 skill retires on Day 5; archive it if it's still around
[ -d ~/.claude/skills/capture-note ] && mv ~/.claude/skills/capture-note "$HOME/archive/capture-note-week1-$ts"
echo "  ~/.claude staged (rules, guard, settings, my-vault skill)"
[ -d "$HOME/archive/dot-claude-backup-$ts" ] && echo "  previous ~/.claude files -> ~/archive/dot-claude-backup-$ts"

# ---- 3 · tools executable + PATH ---------------------------------------------
chmod +x bin/vault doctor.sh ~/.claude/hooks/vault-write-guard.sh
for rc in ~/.zshrc ~/.bashrc; do
  [ -f "$rc" ] || continue
  grep -q 'vault/bin' "$rc" || printf '\nexport PATH="$HOME/vault/bin:$PATH"\n' >> "$rc"
done
export PATH="$HOME/vault/bin:$PATH"
echo "  ~/vault/bin added to PATH (open a new terminal to pick it up)"

# ---- 4 · verify -----------------------------------------------------------------
echo "== Verifying =="
./doctor.sh >/dev/null 2>&1              && ok "the doctor: clean bill of health"            || bad "the doctor found problems — run ./doctor.sh"
bin/vault help >/dev/null 2>&1           && ok "the doorway answers: vault help"             || bad "bin/vault won't run"
bin/vault capture "" >/dev/null 2>&1;  [ $? -eq 2 ] \
                                         && ok "the doctor refuses a bad parcel (exit 2)"    || bad "an empty capture was not refused"
bash -n ~/.claude/hooks/vault-write-guard.sh \
                                         && ok "the guard parses"                            || bad "the guard has a syntax error"
python3 -c 'import json; json.load(open("'"$HOME"'/.claude/settings.json"))' 2>/dev/null \
                                         && ok "settings.json is valid (guard registered)"   || bad "settings.json is not valid JSON"
command -v node >/dev/null 2>&1          && ok "node is installed ($(node -v)) — the face needs it" || bad "node is MISSING — the face needs it (install Node.js LTS)"
command -v claude >/dev/null 2>&1        && ok "claude is installed"                          || bad "claude not found on PATH"

echo
if [ "$fail" -eq 0 ]; then
  echo "All $pass checks passed."
  echo "  Drive it from the terminal:  open a NEW terminal, then  cd ~/vault && claude"
  echo "  Open its face (the app):      cd ~/vault/frontend && npm install && npm run dev"
  exit 0
else
  echo "$pass passed, $fail FAILED — fix the ✘ lines above (ask the facilitator)."
  exit 2
fi
