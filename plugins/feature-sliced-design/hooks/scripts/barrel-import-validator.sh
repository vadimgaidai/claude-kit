#!/bin/bash
# Blocks barrel imports from @/shared/ui — must import by direct path
# Allowed: import { Button } from "@/shared/ui/button"
# Blocked: import { Button } from "@/shared/ui"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')

if [[ -z "$FILE_PATH" ]] || [[ -z "$CONTENT" ]]; then
  exit 0
fi

# Skip files inside shared/ui itself (barrel exports are fine there)
if [[ "$FILE_PATH" == *"/shared/ui/"* ]]; then
  exit 0
fi

# Check for barrel import from @/shared/ui (without a sub-path)
if echo "$CONTENT" | grep -qE 'from\s+["\x27]@/shared/ui["\x27]'; then
  echo "Import violation: barrel import from '@/shared/ui' is not allowed" >&2
  echo "Import directly: '@/shared/ui/button', '@/shared/ui/card', etc." >&2
  exit 2
fi

exit 0
