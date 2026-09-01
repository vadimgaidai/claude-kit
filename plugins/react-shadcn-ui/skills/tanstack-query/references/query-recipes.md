# Query Recipes

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names. Real infrastructure (`queryClient`, `createQueryKeyFactory`) keeps its real name.
>
> Where these files live and how they are named: the structure skill. What belongs inside them: the `tanstack-query` skill.

## Dependent query — `enabled`, never an early return

```tsx
const { data: user } = useQuery(userQueries.me())
const { data: orders, isPending } = useQuery({
  ...orderQueries.byUser(user?.id as string),
  enabled: Boolean(user?.id),
})
```

The disabled query stays a query: `isPending` is `true`, `isFetching` is `false`, nothing is requested. A `if (!user) return null` above the second `useQuery` would break the rules of hooks; an effect that triggers the fetch would reimplement the cache badly.

Note the cast: the options factory takes a real `string`, and `enabled` is what guarantees `queryFn` never runs without one. Prefer this over widening the factory's parameter to `string | undefined`, which would let a bad key reach the cache.

## Deriving from the response — `select`

`list({})` **as a query** is a real cache entry: the unfiltered list. That is a different act from invalidation, where the group key is `lists()` — reading one filter combination and invalidating all of them are not the same call.

```tsx
// Narrow: this component re-renders only when the count changes.
const { data: activeCount } = useQuery({
  ...[entity]Queries.list({}),
  select: (items) => items.filter((item) => item.status === [Entity]Status.Active).length,
})
```

When `select` depends on a prop, stabilize it — an inline closure is a new function every render:

```tsx
const selectByStatus = useCallback(
  (items: I[Entity][]) => items.filter((item) => item.status === status),
  [status]
)

const { data: filtered } = useQuery({ ...[entity]Queries.list({}), select: selectByStatus })
```

**`select` is not a filter for the server.** If the API can filter, put the filter in the key and let the backend do it — `select` on a 10 000-item payload still downloaded 10 000 items.

## Dynamic parallel queries — `useQueries`

A fixed set is just two hooks. Use `useQueries` only when the number of queries is data-driven:

```tsx
const results = useQueries({
  queries: ids.map((id) => [entity]Queries.byId(id)),
  combine: (queries) => ({
    data: queries.map((query) => query.data).filter(Boolean),
    isPending: queries.some((query) => query.isPending),
  }),
})
```

`combine` runs on the results array and keeps the component from re-rendering on every individual settle. Without it, read `results` directly — don't map it into `useState`.

## Pagination — keep the previous page on screen

```tsx
import { keepPreviousData, useQuery } from "@tanstack/react-query"

const { data, isPlaceholderData } = useQuery({
  ...[entity]Queries.list({ page }),
  placeholderData: keepPreviousData,
})
```

`page` is in the key, so each page is cached separately; `keepPreviousData` is what stops the list unmounting into the empty state between pages. Dim the container on `isPlaceholderData` and disable "next" while it is `true`, so a fast clicker can't skip a page that hasn't loaded.

## Infinite list

```typescript
// entities/[entity]/api/[entity].queries.ts
export const [entity]Queries = {
  infinite: (filters: I[Entity]Filters) =>
    infiniteQueryOptions({
      queryKey: [entity]Keys.list(filters),
      queryFn: ({ pageParam }) => [entity]Api.getList({ ...filters, cursor: pageParam }),
      // The cursor is NOT in the key — TanStack stores the pages under one key.
      // `filters` is, because changing a filter is a different list.
      initialPageParam: null as string | null,
      getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    }),
}
```

- `getNextPageParam` returns `undefined` or `null` to mean "no more pages". Any other value is treated as a valid cursor — returning `-1` or `0` from a page-number API leaves `hasNextPage` true forever and fetches page `-1`.
- Guard the trigger: `if (hasNextPage && !isFetchingNextPage) fetchNextPage()`. An intersection observer fires repeatedly while the sentinel is visible.
- The flat list is `data.pages.flatMap((page) => page.items)`. Derive it in render, or in `select` if it is expensive — never in state.
- On a very long list, cap retention with `maxPages` so the cache doesn't grow without bound; note that a cap makes the list re-fetch when scrolling back up.

## Cancellation

Pass the signal through when the request can be superseded — a search-as-you-type, or a page the user navigates away from mid-flight:

```typescript
queryFn: ({ signal }) => [entity]Api.getList(filters, { signal })
```

`ky` and `fetch` both take `{ signal }` directly. Without it the aborted response still arrives and still resolves.

## Prefetch on intent

```tsx
const queryClient = useQueryClient()

const prefetch = (id: string) => queryClient.prefetchQuery([entity]Queries.byId(id))

<Link to={paths.[entity].details(id)} onMouseEnter={() => prefetch(id)} onFocus={() => prefetch(id)}>
```

Spreading the same options object is the point — the prefetched key is the key the destination will read. `prefetchQuery` respects `staleTime`, so a second hover is free; it never throws, so it needs no error handling.
