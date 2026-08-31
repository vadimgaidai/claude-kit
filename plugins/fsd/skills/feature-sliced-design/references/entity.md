# Entity Example

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.

An entity models a domain resource: its types, constants, base HTTP calls, read-side queries, and presentational UI.

### `model/constants.ts`

A closed set of string literals (roles, statuses, kinds) is modeled with an **`as const` object + derived type** instead of a TypeScript `enum` — no runtime class, tree-shakes cleanly, plays well with JSON, and the type is structurally the union of literal values.

The `as const` object is a **runtime value**, so it lives in `constants.ts` alongside the other constants:

```typescript
// src/entities/[entity]/model/constants.ts
export const [ENTITY]_ENTITY = "[entity]" as const

export const [ENTITY]_QUERY_KEYS = {
  LIST: "list",
} as const

// The `as const` "enum" — a value → constants.ts.
export const [Entity]Status = {
  Active: "active",
  Archived: "archived",
} as const
```

### `model/types.ts`

The **derived union is a type**, so it lives in `types.ts`. It derives from the `as const` value via a type-only import — this is erased at compile time, so there is no runtime cycle:

```typescript
// src/entities/[entity]/model/types.ts
import type { [Entity]Status } from "./constants"

export type T[Entity]Status = (typeof [Entity]Status)[keyof typeof [Entity]Status]
// → "active" | "archived"

export interface I[Entity] {
  id: string
  name: string
  status: T[Entity]Status
  createdAt: string
  updatedAt: string
}

export interface I[Entity]Profile extends I[Entity] {
  description?: string
}
```

Naming: interfaces are prefixed `I`, the derived union is prefixed `T`, the const value keeps its plain name (`[Entity]Status` value, `T[Entity]Status` type — distinct identifiers).

Usage in code:

```typescript
import { [Entity]Status } from "@/entities/[entity]"
import type { I[Entity], T[Entity]Status } from "@/entities/[entity]"

if (item.status === [Entity]Status.Active) {
  // ...
}

const setStatus = (status: T[Entity]Status) => {
  // status is "active" | "archived"
}
```

Why not `enum`:

- Numeric enums leak runtime objects and don't tree-shake.
- String enums are nominally typed — they don't accept the underlying string literal, which makes API/JSON round-trips awkward.
- The `as const` pattern gives you a real const value AND a literal-union type with zero extra runtime cost.

### `api/[entity].api.ts`

```typescript
// src/entities/[entity]/api/[entity].api.ts
import type { I[Entity] } from "../model/types"

import { httpClient } from "@/shared/lib"

export const [entity]Api = {
  getById: async (id: string): Promise<I[Entity]> => {
    return httpClient.get(`[entity]/${id}`).json<I[Entity]>()
  },
}
```

### `api/[entity].queries.ts`

```typescript
// src/entities/[entity]/api/[entity].queries.ts
import { queryOptions } from "@tanstack/react-query"

import { [entity]Api } from "./[entity].api"

import { [ENTITY]_ENTITY, [ENTITY]_QUERY_KEYS } from "@/entities/[entity]/model/constants"
import { createQueryKeyFactory } from "@/shared/lib/react-query"

export const [entity]Keys = createQueryKeyFactory([ENTITY]_ENTITY, (all) => ({
  byId: (id: string) => [...all(), id] as const,
}))

export const [entity]Queries = {
  byId: (id: string) =>
    queryOptions({
      queryKey: [entity]Keys.byId(id),
      queryFn: () => [entity]Api.getById(id),
    }),
}
```

### `index.ts` (public API)

`[Entity]Status` (the const object value) and `T[Entity]Status` (the derived union type) are distinct identifiers, so the value is a value-export and the type a `type`-export:

```typescript
// src/entities/[entity]/index.ts
export { [entity]Api } from "./api/[entity].api"
export { [entity]Queries, [entity]Keys } from "./api/[entity].queries"
export { [Entity]Status } from "./model/constants"
export type { I[Entity], I[Entity]Profile, T[Entity]Status } from "./model/types"
```

External code consumes the entity only through this barrel:

```typescript
import { [entity]Queries, [Entity]Status } from "@/entities/[entity]"
import type { I[Entity], T[Entity]Status } from "@/entities/[entity]"
```

