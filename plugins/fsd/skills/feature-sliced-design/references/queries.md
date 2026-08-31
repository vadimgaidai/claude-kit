# Query Key Factory & TanStack Query

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.

### The factory itself (`src/shared/lib/react-query/query-key-factory.ts`)

```typescript
type TQueryKeyFactory<T extends Record<string, (...args: never[]) => readonly unknown[]>> = {
  [K in keyof T]: T[K]
} & {
  all: () => readonly [string]
}

export const createQueryKeyFactory = <
  T extends Record<string, (...args: never[]) => readonly unknown[]>,
>(
  entity: string,
  keys: (all: () => readonly [string]) => T
): TQueryKeyFactory<T> => {
  const all = () => [entity] as const
  return { all, ...keys(all) }
}
```

### Defining keys + queryOptions

Defined inside the entity (`entities/[entity]/api/[entity].queries.ts`). Constants live in `model/constants.ts` to keep string segments out of the api layer.

```typescript
// entities/[entity]/api/[entity].queries.ts
export const [entity]Keys = createQueryKeyFactory([ENTITY]_ENTITY, (all) => ({
  byId: (id: string) => [...all(), id] as const,
  list: (filters: { status?: T[Entity]Status }) => [...all(), [ENTITY]_QUERY_KEYS.LIST, filters] as const,
}))

export const [entity]Queries = {
  byId: (id: string) =>
    queryOptions({ queryKey: [entity]Keys.byId(id), queryFn: () => [entity]Api.getById(id) }),
  list: (filters: { status?: T[Entity]Status }) =>
    queryOptions({ queryKey: [entity]Keys.list(filters), queryFn: () => [entity]Api.getList(filters) }),
}
```

### Consuming a query in a component

```tsx
import { useQuery } from "@tanstack/react-query"
import { [entity]Queries } from "@/entities/[entity]"

export const [Entity]Badge = ({ id }: { id: string }) => {
  const { data: item, isPending } = useQuery([entity]Queries.byId(id))
  if (isPending || !item) return null
  return <span>{item.name}</span>
}
```

### Invalidation patterns

```typescript
// Invalidate a specific query
queryClient.invalidateQueries({ queryKey: [entity]Keys.byId(id) })

// Invalidate all [entity]-scoped queries
queryClient.invalidateQueries({ queryKey: [entity]Keys.all() })
```

