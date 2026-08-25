#!/usr/bin/env bash
# the doctor: check every note against the vault rules. Read only.
# The vault is VAULT_DIR, or the folder this script sits in.
root="${VAULT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
cd "$root" || { echo "doctor: no vault at $root" >&2; exit 2; }
flags=0
for note in inbox/*.md knowledge/*.md projects/*/*.md; do
  [ -e "$note" ] || continue
  front="$(head -n 12 "$note")"
  # rule 1: every note carries its frontmatter
  for field in title type created tags; do
    echo "$front" | grep -q "^$field:" || { echo "MISSING $field: $note"; flags=1; }
  done
  # rule 2: the type is one of ours
  t=$(echo "$front" | grep '^type:' | head -1 | cut -d' ' -f2)
  case "$t" in learning|reference|decision|project|adr|work-item|plan|scope|"") ;; *) echo "UNKNOWN type $t: $note"; flags=1 ;; esac
  # rule 3: names are kebab-case
  case "$(basename "$note")" in *[A-Z]*|*" "*|*_*) echo "NOT kebab-case: $note"; flags=1 ;; esac
  # rule 4: every link points at a real note
  for target in $(grep -o '\[\[[^]|]*' "$note" | sed 's/\[\[//'); do
    b=$(basename "$target")
    ls knowledge/"$b".md inbox/"$b".md projects/*/"$b".md 2>/dev/null | grep -q . || { echo "DANGLING $target: $note"; flags=1; }
  done
  # rule 5: every ADR carries a status line
  case "$(basename "$note")" in adr-*)
    echo "$front" | grep -q '^status:' || { echo "NO STATUS on adr: $note"; flags=1; }
  esac
  # rule 6: a plan states its goal; a scope names its plan
  case "$(basename "$note")" in
    plan-*)  echo "$front" | grep -q '^goal:'   || { echo "NO GOAL on plan: $note"; flags=1; } ;;
    scope-*) echo "$front" | grep -q '^parent:' || { echo "NO PARENT on scope: $note"; flags=1; } ;;
  esac
done
if [ "$flags" -eq 0 ]; then echo "clean bill of health"; exit 0; else exit 2; fi
