#!/bin/bash
# git-secret-scan.sh: PreToolUse-Hook (Bash).
# Erzwingt die CLAUDE.md-Regel "Vor jedem Commit: Secret-Scan" deterministisch:
# blockt git commit (Exit 2), wenn im gestagten Diff Zeilen nach Secrets aussehen.
# Muster bewusst schaerfer als der Prosa-Grep (Zuweisung + bekannte Key-Formate),
# damit Fachtexte mit Woertern wie "Token" keine Fehlalarme ausloesen.

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
case "$CMD" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
if [ -n "$CWD" ] && [ -d "$CWD" ]; then
  cd "$CWD" || exit 0
fi
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

ASSIGN='(api[_-]?key|apikey|secret|password|passwd|bearer|access[_-]?token|auth[_-]?token|client[_-]?secret)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9_/+-]{8,}'
KEYFMT='sk_live_[A-Za-z0-9]|sk-ant-[A-Za-z0-9]|ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|github_pat_|sbp_[a-f0-9]{20,}|whsec_[A-Za-z0-9]{16,}|xox[bap]-[A-Za-z0-9]|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY'

DIFF=$(git diff --cached 2>/dev/null)
case "$CMD" in
  *" -a "*|*" -a"|*" -am "*|*" -am"|*"--all"*)
    DIFF="$DIFF
$(git diff 2>/dev/null)"
    ;;
esac

ADDED=$(printf '%s' "$DIFF" | grep -E '^\+[^+]' 2>/dev/null)
HITS=$(printf '%s' "$ADDED" | grep -icE "$ASSIGN" 2>/dev/null)
HITS2=$(printf '%s' "$ADDED" | grep -cE "$KEYFMT" 2>/dev/null)
TOTAL=$(( ${HITS:-0} + ${HITS2:-0} ))

if [ "$TOTAL" -gt 0 ]; then
  {
    echo "SECRET-SCAN BLOCKIERT: $TOTAL verdaechtige Zeile(n) im Commit-Diff."
    echo "Pruefe manuell mit: git diff --cached | grep -inE '<muster>'"
    echo "Betroffene Dateien:"
    printf '%s' "$DIFF" | grep -E '^\+\+\+ ' | sed 's|^+++ b/|  - |' | head -10
    echo "Wenn es sich um harmlose Beispiel-/Doku-Werte handelt: Zeile umformulieren oder Datei aus dem Commit nehmen."
  } >&2
  exit 2
fi
exit 0
