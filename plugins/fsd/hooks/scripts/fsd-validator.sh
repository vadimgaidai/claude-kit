#!/bin/bash
# Validates that file operations respect FSD layer structure
# Blocks creation of files in non-FSD directories under src/

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path or not in src/
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *"/src/"* ]]; then
  exit 0
fi

# Extract the relative path after src/
REL_PATH="${FILE_PATH#*src/}"

# Allowed top-level directories in src/
ALLOWED_LAYERS="app|pages|widgets|features|entities|shared"

# Get the first directory segment
FIRST_DIR=$(echo "$REL_PATH" | cut -d'/' -f1)

# Check if the first directory is an allowed FSD layer
if [[ ! "$FIRST_DIR" =~ ^($ALLOWED_LAYERS)$ ]] && [[ "$REL_PATH" == *"/"* ]]; then
  echo "FSD violation: 'src/$REL_PATH'" >&2
  echo "Allowed layers: src/{$ALLOWED_LAYERS}/" >&2
  echo "Use shared/lib for utils, shared/hooks for hooks, features/*/ui for feature components" >&2
  exit 2
fi

# Block common anti-patterns
BLOCKED_PATTERNS=(
  "components/"
  "utils/"
  "helpers/"
  "hooks/"
  "services/"
  "types/"
  "styles/"
  "constants/"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$REL_PATH" == "$pattern"* ]]; then
    echo "FSD violation: 'src/$pattern' is not an FSD layer" >&2
    echo "Move to: shared/lib (utils), shared/hooks (hooks), shared/types (types), entities or features" >&2
    exit 2
  fi
done

exit 0
