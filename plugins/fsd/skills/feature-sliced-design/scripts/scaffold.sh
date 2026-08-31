#!/bin/bash
# !Deterministic FSD module scaffolder
#
# Usage:
#   scaffold.sh <layer>/<module-name> [relative-file ...]
#
#   layer        entities | features | widgets | pages
#   module-name  kebab-case
#   files        optional explicit list (paths relative to the module root),
#                e.g. api/pet.api.ts model/types.ts ui/pet-card.tsx index.ts
#                Omit to get the default skeleton for the layer.
#
# Creates folders + placeholder files + empty barrel. Refuses to touch an
# existing module. Prints the resulting tree.

set -euo pipefail

err() { echo "scaffold: $1" >&2; exit 1; }

[ $# -ge 1 ] || err "usage: scaffold.sh <layer>/<module-name> [file ...]"

TARGET="$1"; shift
LAYER="${TARGET%%/*}"
NAME="${TARGET#*/}"

case "$LAYER" in
  entities|features|widgets|pages) ;;
  *) err "layer must be entities|features|widgets|pages (got '$LAYER')" ;;
esac
[[ "$NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || err "module name must be kebab-case (got '$NAME')"

DIR="src/$LAYER/$NAME"
[ -e "$DIR" ] && err "$DIR already exists — extend it instead of scaffolding"

if [ $# -gt 0 ]; then
  FILES=("$@")
else
  case "$LAYER" in
    entities) FILES=("api/$NAME.api.ts" "api/$NAME.queries.ts" "model/types.ts" "model/constants.ts" "index.ts") ;;
    features) FILES=("api/$NAME.api.ts" "api/$NAME.mutations.ts" "hooks/use-$NAME.ts" "model/types.ts" "model/constants.ts" "index.ts") ;;
    widgets)  FILES=("ui/$NAME.tsx" "model/types.ts" "index.ts") ;;
    pages)    FILES=("$NAME-page.tsx") ;;
  esac
fi

for f in "${FILES[@]}"; do
  base="$(basename "$f")"
  [[ "$base" =~ ^[a-z0-9][a-z0-9.-]*\.(ts|tsx)$ ]] || err "file '$f' is not kebab-case .ts/.tsx"
  mkdir -p "$DIR/$(dirname "$f")"
  case "$base" in
    types.ts)     echo "// types" > "$DIR/$f" ;;
    constants.ts) echo "// constants" > "$DIR/$f" ;;
    schemas.ts)   echo "// schemas" > "$DIR/$f" ;;
    index.ts)     echo "// public API — downstream agents fill exports" > "$DIR/$f" ;;
    *)            : > "$DIR/$f" ;;
  esac
done

echo "Scaffolded $DIR:"
find "$DIR" | sort | sed "s|^|  |"
