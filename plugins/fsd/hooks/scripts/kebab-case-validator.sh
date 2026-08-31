#!/bin/bash
# Validates that new/edited files under src/ follow kebab-case naming convention
# Allows: kebab-case.tsx, kebab-case.ts, index.ts
# Blocks: MyComponent.tsx, camelCase.ts, PascalCase.tsx

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *"/src/"* ]]; then
  exit 0
fi

FILENAME=$(basename "$FILE_PATH")

# Remove extension for validation
NAME="${FILENAME%.*}"

# Allow index files
if [[ "$NAME" == "index" ]]; then
  exit 0
fi

# Check for uppercase letters (not kebab-case)
if [[ "$NAME" =~ [A-Z] ]]; then
  echo "Naming violation: '$FILENAME' is not kebab-case" >&2
  echo "Expected: '$(echo "$NAME" | sed 's/\([A-Z]\)/-\L\1/g' | sed 's/^-//')'" >&2
  exit 2
fi

# Check for underscores (should use hyphens)
if [[ "$NAME" =~ _ ]]; then
  echo "Naming violation: '$FILENAME' uses underscores instead of hyphens" >&2
  echo "Expected: '$(echo "$NAME" | tr '_' '-')'" >&2
  exit 2
fi

exit 0
