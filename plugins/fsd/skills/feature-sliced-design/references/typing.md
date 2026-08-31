# Typing & File Splitting

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.

### Prefer `as const` objects over `enum`

For closed sets of string literals (roles, statuses, kinds, query-key segments), use a `const` object + derived union type instead of a TypeScript `enum`. **The value lives in `model/constants.ts`; the derived type lives in `model/types.ts`** (see the Entity Example above).

```typescript
// model/constants.ts — the value
export const [Entity]Status = {
  Draft: "draft",
  Pending: "pending",
  Paid: "paid",
  Refunded: "refunded",
} as const
```

```typescript
// model/types.ts — the derived type
import type { [Entity]Status } from "./constants"

export type T[Entity]Status = (typeof [Entity]Status)[keyof typeof [Entity]Status]
```

If `constants.ts` needs the union to annotate another constant, either let inference do it (`export const OPTIONS = Object.values([Entity]Status)` infers `T[Entity]Status[]`) or `import type { T[Entity]Status } from "./types"` — the type-only import is erased, so no runtime cycle results.

### Naming: `I` for interfaces, `T` for types

- `interface I[Entity]`, `interface I[Feature]Payload`, `interface I[Widget]Props`
- `type T[Entity]Status`, `type T[Feature]FormValues`, `type TQueryKey`
- The derived type from a `const` object also gets the `T` prefix — the value keeps its plain name (`[Entity]Status` value, `T[Entity]Status` type).
- Generic parameters keep the standard short form (`T`, `K`, `V`, `TData`) — no double prefix.

### Default: one `model/types.ts`

Most modules need a single `model/types.ts`. Co-locate domain interfaces, derived unions, and helper aliases together — readers can scan one file. (The `as const` values they derive from live in `constants.ts`.)

```typescript
// features/[feature]/model/types.ts
export interface I[Feature]Payload { name: string; email: string }
export interface I[Feature]Result { id: string }
export type T[Feature]FormValues = z.infer<typeof [feature]Schema>
```

### When `types.ts` gets large — split by concern, not by usage site

If a module's types file grows past ~150 lines or covers clearly separate concerns, convert it into a `model/types/` folder and re-export from a single `index.ts`:

```
features/[feature]/model/
├── types/
│   ├── [concern-a].ts   # one cohesive group of types
│   ├── [concern-b].ts   # another cohesive group
│   └── index.ts         # export * from "./[concern-a]" / "./[concern-b]"
├── constants.ts
└── schemas.ts
```

```typescript
// features/[feature]/model/types/index.ts
export * from "./[concern-a]"
export * from "./[concern-b]"
```

Rules:

- **Never** scatter `*.types.ts` next to api / ui / hooks files. They must live under `model/`.
- Consumers always import from `../model/types` (or the module barrel), not from a specific sub-file.
- Inferred types from zod schemas live next to the schema (`model/schemas.ts`) and may be re-exported from `model/types.ts` if needed externally.

