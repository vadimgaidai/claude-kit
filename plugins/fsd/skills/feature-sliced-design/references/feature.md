# Feature Example

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.

A feature bundles the **write-side** of a flow (mutations) plus the hooks that compose it for UI.

### Folder layout

```
src/features/[feature]/
├── api/
│   ├── [feature].api.ts         # direct HTTP calls
│   └── [feature].mutations.ts   # use…Mutation hooks
├── hooks/
│   └── use-[feature].ts         # high-level facade combining state + mutations
├── model/
│   ├── types.ts                 # request/response shapes
│   └── schemas.ts               # zod schemas for the feature's forms
└── index.ts                     # barrel
```

### `model/types.ts`

```typescript
// src/features/[feature]/model/types.ts
export interface I[Feature]Payload {
  name: string
  email: string
}

export interface I[Feature]Result {
  id: string
}
```

### `api/[feature].api.ts`

```typescript
// src/features/[feature]/api/[feature].api.ts
import type { I[Feature]Payload, I[Feature]Result } from "../model/types"

import { httpClient } from "@/shared/lib"

export const [feature]Api = {
  submit: async (payload: I[Feature]Payload): Promise<I[Feature]Result> => {
    return httpClient.post("[entity]", { json: payload }).json<I[Feature]Result>()
  },
}
```

> When a call must bypass the shared client (e.g. an auth flow that must not send the Bearer token), call `ky` directly with `env.VITE_API_URL` instead of `httpClient`.

### `hooks/use-[feature].ts` — composing API + state

```typescript
// src/features/[feature]/hooks/use-[feature].ts
import { use[Feature]Mutation } from "../api/[feature].mutations"

export const use[Feature] = () => {
  const mutation = use[Feature]Mutation()

  return {
    submit: mutation.mutateAsync,
    isSubmitting: mutation.isPending,
  }
}
```

### `index.ts` (public API)

```typescript
// src/features/[feature]/index.ts
export { use[Feature] } from "./hooks/use-[feature]"
export { use[Feature]Mutation } from "./api/[feature].mutations"
export type { I[Feature]Payload, I[Feature]Result } from "./model/types"
```

