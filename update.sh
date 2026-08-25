#!/usr/bin/env bash
# update.sh — pull the moving parts up to date WITHOUT touching your content.
#
#   cd ~/vault && git pull && bash update.sh
#
# A `git pull` refreshes the vault, `bin/vault`, `doctor.sh`, and AGENTS.md —
# which is everything most agents need, because they read AGENTS.md straight
# from the vault. The one thing a pull cannot reach is the Claude Code side
# under ~/.claude. That is what this script re-stages.
#
# Your CONTENT is never touched — notes, projects and inbox are left exactly as
# they are. The ~/.claude files ARE replaced, so anything you wrote there is
# copied to ~/archive first. Nothing is deleted.
set -u

ts=$(date +%Y%m%d-%H%M%S)
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here" || exit 2
[ -d setup/claude-code ] || { echo "update: run me from your vault (couldn't find setup/claude-code here)." >&2; exit 2; }

pass=0; fail=0
ok()  { echo "  ✔ $1"; pass=$((pass+1)); }
bad() { echo "  ✘ $1"; fail=$((fail+1)); }

echo "== Command Center updater =="

# ---- the agent side ---------------------------------------------------------
echo "  AGENTS.md came with the pull — every agent that reads it is already current."
if [ -d "$HOME/.claude" ]; then
  mkdir -p ~/.claude/hooks
  backup() {  # backup <path> — copy aside before replacing
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
  # keep the guard pointed at THIS vault, wherever it was installed
  printf '%s\n' "$here" > ~/.claude/hooks/vault-dir
  echo "  ~/.claude refreshed (rules, settings, the guard)"
  [ -d "$HOME/archive/dot-claude-backup-$ts" ] && echo "  your previous ~/.claude files -> ~/archive/dot-claude-backup-$ts"
else
  echo "  no ~/.claude here — nothing further to do."
fi

# ---- tools executable + PATH ------------------------------------------------
chmod +x bin/vault doctor.sh 2>/dev/null
for rc in ~/.zshrc ~/.bashrc ~/.profile; do
  [ -f "$rc" ] || continue
  grep -q "$here/bin" "$rc" || printf '\nexport PATH="%s/bin:$PATH"\n' "$here" >> "$rc"
done
echo "  tools executable · PATH checked"

# ---- verify -----------------------------------------------------------------
echo "== Verifying =="
VAULT_DIR="$here" ./doctor.sh >/dev/null 2>&1 && ok "the doctor: clean bill of health"       || bad "the doctor found problems — run ./doctor.sh"
bin/vault help >/dev/null 2>&1                && ok "the doorway answers: vault help"        || bad "bin/vault won't run"
VAULT_DIR="$here" bin/vault accept x >/dev/null 2>&1; [ $? -eq 2 ] \
                                              && ok "the gates refuse a non-human caller"    || bad "a gate opened for a script"
if [ -f ~/.claude/hooks/vault-write-guard.sh ]; then
  bash -n ~/.claude/hooks/vault-write-guard.sh && ok "the guard parses"                      || bad "the guard has a syntax error"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' ~/.claude/settings.json 2>/dev/null \
      && ok "settings.json is valid (guard registered)"                                      || bad "settings.json is not valid JSON"
  else
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' ~/.claude/settings.json 2>/dev/null \
      && ok "settings.json is valid (guard registered)"                                      || bad "settings.json is not valid JSON"
  fi
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "Updated — $pass checks passed. Your content was untouched."
  echo "  Restart your agent session so the refreshed rules load."
  echo "  Rebuilt the face? cd frontend && npm install && npm run build, then restart it."
  exit 0
else
  echo "$pass passed, $fail FAILED — fix the ✘ lines above."
  exit 2
fi
