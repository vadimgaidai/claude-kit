# Barrel Exports

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.

Every module exposes its public API through one `index.ts`. External code may **only** import from the barrel — never reach into a module's internal files.

### Entity barrel

```typescript
// src/entities/[entity]/index.ts
export { [entity]Api } from "./api/[entity].api"
export { [entity]Queries, [entity]Keys } from "./api/[entity].queries"
export { [Entity]Status } from "./model/constants"
export type { I[Entity], I[Entity]Profile, T[Entity]Status } from "./model/types"
```

Note: the `as const` value (`[Entity]Status`) is re-exported from `./model/constants`, the derived type (`T[Entity]Status`) from `./model/types` — each from the file it lives in.

### Feature barrel

```typescript
// src/features/[feature]/index.ts
export { use[Feature] } from "./hooks/use-[feature]"
export { use[Feature]Mutation } from "./api/[feature].mutations"
export type { I[Feature]Payload, I[Feature]Result } from "./model/types"
```

### Widget barrel

```typescript
// src/widgets/[widget]/index.ts
export { [Widget] } from "./ui/[widget]"
export { [widget]Config } from "./config/[widget].config"
export type { I[Widget]Config, I[Widget]Item } from "./model/types"
```

### Consuming

```typescript
// Correct — through the barrel
import { use[Feature] } from "@/features/[feature]"
import { [entity]Queries } from "@/entities/[entity]"
import type { I[Entity] } from "@/entities/[entity]"
import { [Widget] } from "@/widgets/[widget]"

// Wrong — reaching into internals
import { use[Feature] } from "@/features/[feature]/hooks/use-[feature]"
import { [entity]Api } from "@/entities/[entity]/api/[entity].api"
```

Exception: shadcn components in `shared/ui/` are imported directly by file path (`@/shared/ui/button`) — they're not a module, they're a flat component library managed by shadcn CLI.
