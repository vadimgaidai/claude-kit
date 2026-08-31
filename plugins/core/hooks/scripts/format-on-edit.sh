#!/bin/bash
# PostToolUse(Edit|Write): auto-formats the touched file with Prettier.
# Agents never spend tokens on formatting; the reviewer never checks it.

INPUT=$(cat)

FILE=$(printf '%s' "$INPUT" | node -e "
let d = '';
process.stdin.on('data', (c) => (d += c)).on('end', () => {
  try { process.stdout.write(JSON.parse(d).tool_input?.file_path || '') } catch {}
})")

[ -z "$FILE" ] && exit 0

case "$FILE" in
  */node_modules/*|*/dist/*|*/.git/*) exit 0 ;;
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.html)
    if [ -f "$FILE" ]; then
      cd "$CLAUDE_PROJECT_DIR" && npx --no-install prettier --write "$FILE" >/dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
