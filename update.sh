#!/usr/bin/env bash
# update.sh — pull the moving parts up to date WITHOUT touching your vault.
#
# Use it after fetching new changes:
#
#   cd ~/vault && git pull && bash update.sh
#
# install.sh copies two things OUT of this repo: the vault + tools into ~/vault,
# and the ~/.claude side (rules, settings, the guard hook). The my-vault skill
# lives in the vault itself (.claude/skills/), so git pull already refreshed it.
# A `git pull` refreshes the vault and bin/vault, but NOT the ~/.claude side —
# that's what this script does. It re-stages the ~/.claude files and re-checks
# the tools. It NEVER touches your notes, projects, or inbox, and it archives
# nothing — your vault content is left exactly as it is.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"
[ -d setup/dot-claude ] || { echo "update: run me from your vault (couldn't find setup/dot-claude here)." >&2; exit 2; }

pass=0; fail=0
ok()  { echo "  ✔ $1"; pass=$((pass+1)); }
bad() { echo "  ✘ $1"; fail=$((fail+1)); }

echo "== Command Center updater =="

# ---- refresh the ~/.claude side (rules · settings · guard) -------------------
mkdir -p ~/.claude/hooks
cp setup/dot-claude/CLAUDE.md            ~/.claude/CLAUDE.md
cp setup/dot-claude/settings.json        ~/.claude/settings.json
cp setup/dot-claude/hooks/vault-write-guard.sh ~/.claude/hooks/vault-write-guard.sh
echo "  ~/.claude refreshed (rules, settings, the guard) — my-vault came with the pull"

# ---- tools executable + PATH -------------------------------------------------
chmod +x bin/vault doctor.sh ~/.claude/hooks/vault-write-guard.sh 2>/dev/null
for rc in ~/.zshrc ~/.bashrc; do
  [ -f "$rc" ] || continue
  grep -q 'vault/bin' "$rc" || printf '\nexport PATH="$HOME/vault/bin:$PATH"\n' >> "$rc"
done
echo "  tools executable · PATH checked"

# ---- verify ------------------------------------------------------------------
echo "== Verifying =="
./doctor.sh >/dev/null 2>&1        && ok "the doctor: clean bill of health"          || bad "the doctor found problems — run ./doctor.sh"
bin/vault help >/dev/null 2>&1     && ok "the doorway answers: vault help"           || bad "bin/vault won't run"
bash -n ~/.claude/hooks/vault-write-guard.sh \
                                   && ok "the guard parses"                          || bad "the guard has a syntax error"
python3 -c 'import json; json.load(open("'"$HOME"'/.claude/settings.json"))' 2>/dev/null \
                                   && ok "settings.json is valid (guard registered)" || bad "settings.json is not valid JSON"

echo
if [ "$fail" -eq 0 ]; then
  echo "Updated — $pass checks passed. Your vault content was untouched."
  echo "  Restart your Claude Code session so the refreshed guard + skill load."
  echo "  Rebuilt the face? cd frontend && npm install && npm run build, then pm2 restart."
  exit 0
else
  echo "$pass passed, $fail FAILED — fix the ✘ lines above."
  exit 2
fi
