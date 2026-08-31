# Validation Schemas (`schemas.ts`)

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.

All zod validation lives in `model/schemas.ts`. Do **not** inline schemas inside components or API files.

### Defining a schema + inferring the type

```typescript
// features/[feature]/model/schemas.ts
import { z } from "zod"

export const [feature]Schema = z.object({
  email: z.string().email("Invalid email"),
  password: z.string().min(8, "Password must be at least 8 characters"),
})

export const [feature]ExtendedSchema = [feature]Schema.extend({
  name: z.string().min(2, "Name is too short"),
})

export type T[Feature]FormValues = z.infer<typeof [feature]Schema>
export type T[Feature]ExtendedFormValues = z.infer<typeof [feature]ExtendedSchema>
```

### Reference: env validation (`src/shared/config/env/schema.ts`)

```typescript
import { z } from "zod"

const envSchema = z.object({
  MODE: z.enum(["development", "production"]).default("development"),
  VITE_API_URL: z.string().url(),
  VITE_APP_NAME: z.string().default("React App"),
  VITE_ENABLE_DEVTOOLS: z
    .string()
    .default("false")
    .transform((val) => val === "true"),
})

export type TEnv = z.infer<typeof envSchema>
export { envSchema }
```

### Using a schema with React Hook Form

```tsx
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"

import { [feature]Schema, type T[Feature]FormValues } from "../model/schemas"

const form = useForm<T[Feature]FormValues>({
  resolver: zodResolver([feature]Schema),
  defaultValues: { email: "", password: "" },
})
```

Rules:

- Filename: `schemas.ts` for multiple schemas, or `[name].schema.ts` if a single dominant schema (e.g. `env/schema.ts`).
- Always `export type X = z.infer<typeof xSchema>` next to the schema — no manual duplicate interfaces.
- Schemas and their inferred types are imported via `../model/schemas` from inside the module, or via the module barrel from outside.

