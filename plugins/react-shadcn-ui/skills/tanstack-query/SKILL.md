---
name: tanstack-query
description: TanStack Query v5 policy for a client-rendered SPA — what the shared QueryClient already decides, what belongs in a query key, when to use enabled/select/useQueries/placeholderData, and how a mutation touches the cache. Use when writing or reviewing queries, mutations, cache invalidation, pagination, prefetching, or a data-fetching effect.
---

# TanStack Query v5

Client-rendered SPA only. Nothing here is about SSR — no `dehydrate`/`hydrate`, no `HydrationBoundary`, no per-request client. If a snippet from the internet has those, it is answering a different question.

**This skill owns what goes inside a query or mutation.** Where the file lives and what it is called is owned by the project's structure skill — in FSD projects, `structure` → `references/queries.md` and `references/mutations.md`. Read that one for the shape, this one for the policy.

## Read the shared client once, then stop repeating it

The project builds one `QueryClient` (FSD: `src/shared/lib/react-query/client.ts`). Open it before writing your first query. It typically already sets `staleTime`, `gcTime`, `refetchOnWindowFocus`, `refetchOnReconnect`, a `retry` predicate that gives up on 4xx, and `QueryCache`/`MutationCache` `onError` handlers.

- **Do not restate a default per query.** `staleTime: 1000 * 60 * 5` on a query when the client already says that is noise the next reader has to diff.
- Override a default only when this query's data really is more or less volatile than the rest, and say why in a short comment on that line.
- **Auth belongs to the cache handlers, not to your hook.** If the client's `QueryCache`/`MutationCache` `onError` handles 401 and token refresh, never add a local `onError` that re-handles it — you get two refresh flows racing.
- `mutations: { retry: false }` is deliberate. A retried POST is a duplicate write.

## Query keys

The key is the cache identity. Get it wrong and you either serve stale data for the wrong inputs or lose the cache entirely.

**Every input the response depends on is in the key** — id, filters, pagination, sort, locale. A parameter the `queryFn` uses but the key omits is a cache bug, not a style issue.

### Half of that is the linter's job — leave it alone

Where `@tanstack/eslint-plugin-query` is enabled (`flat/recommended`), `exhaustive-deps` **errors** on a variable that the `queryFn` closes over and the key omits, and it resolves through the key factory: `keys.lists()` with `queryFn: () => api.getList(filters)` is a lint error, while `keys.list(filters)` passes. Don't hand-audit key completeness, and don't spend a review comment on it.

**But the rule only looks at an inline function.** Give `queryFn` a bare reference and it bails out silently, checking nothing:

```typescript
queryFn: () => [entity]Api.getMe(),  // checked
queryFn: [entity]Api.getMe,          // rule skips this object entirely
```

**So always write the arrow form, even for a fetcher that takes no arguments.** It costs five characters and keeps the check armed for the day someone adds a parameter. The bare reference is an opt-out disguised as brevity.

Also machine-owned and not worth reviewing by hand: `stable-query-client`, `no-unstable-deps`, `no-void-query-fn`, `no-rest-destructuring`, and the `queryOptions` / infinite / mutation property-order rules.

### What no rule can see — this is the part you own

- **Whether the key came from the factory at all.** A hand-written `["user", id]` at a call site passes every rule and is invisible to `keys.all()`.
- **`lists()` vs `list(filters)`** — which one an invalidation should use, and whether the unfiltered parent key even exists.
- **The breadth of an invalidation.** Nothing checks that a single-item edit didn't sweep the entity.
- **Serializability and stability.** A fresh object literal in a key is fine — TanStack hashes deterministically — but a `Date`, a `Map`, a class instance or a function is not. Normalize to a primitive or a plain object first.
- **One `queryFn`, one key.** Two endpoints sharing a key is the same bug twice, and no linter compares two files.
- **Mutations.** The plugin does no key analysis on them at all.

### What the factory guarantees, and what it doesn't

`createQueryKeyFactory(entity, (all) => ({ ... }))` hands your callback an `all` function and merges it into the result. Three consequences that decide whether invalidation works:

- **Every entry is a function — call it.** `keys.all()`, `keys.me()`, not `keys.all`. A zero-argument key is still `() => [...]`; passing the function itself into `queryKey` hashes the function, not the key.
- **Every key spreads `all()` as its first element.** That single shared prefix is the only reason `invalidateQueries({ queryKey: keys.all() })` sweeps the entity. A key built without it is invisible to the sweep and will go stale forever — this is why the callback receives `all` instead of you rebuilding the prefix by hand.
- **A filtered key needs an unfiltered parent.** Matching is by array prefix, so `[entity, "list", filters]` cannot be invalidated as a group by its own factory method — you would have to pass a filters object and lean on TanStack's partial-object matching, which breaks the day someone adds `exact: true`. Give the factory both:

```typescript
export const [entity]Keys = createQueryKeyFactory([ENTITY]_ENTITY, (all) => ({
  lists: () => [...all(), [ENTITY]_QUERY_KEYS.LIST] as const,
  list: (filters: I[Entity]Filters) => [...all(), [ENTITY]_QUERY_KEYS.LIST, filters] as const,
  byId: (id: string) => [...all(), id] as const,
}))
```

`lists()` invalidates every filter combination by prefix; `list(filters)` addresses one. Same rule for any other parameterized key.

Breadth, narrowest first: `byId(id)` → `list(filters)` → `lists()` → `all()`. Pick the narrowest that covers what changed.

## Reading data

Queries are declared as `queryOptions({ ... })` objects in the entity, and consumed with `useQuery(entityQueries.x(...))`. The component picks the hook; it never re-declares the key or the fetcher.

- **Dependent query → `enabled`**, not an early `return` and not an effect. `enabled: Boolean(userId)` keeps it a disabled query, which is a real state (`isPending` true, no fetch) instead of a conditional hook.
- **Deriving from the response → `select`**, not a `.filter().sort()` in the component body. `select` re-runs only when the data changes and narrows what re-renders the component. If `select` closes over a prop, wrap it in `useCallback`.
- **A dynamic number of parallel queries → `useQueries`.** A fixed pair is just two `useQuery` calls; a list of ids you don't know at compile time cannot be, because hooks can't run in a loop.
- **Pagination and filter switches → `placeholderData: keepPreviousData`**, and dim the list on `isPlaceholderData`. Without it every page change flashes the empty state.
- `initialData` is cached as if it were fetched and ages by `staleTime`; `placeholderData` is never written to the cache. Reach for `placeholderData` unless you genuinely have the complete, authoritative object.
- **Never mirror query data into `useState`, and never fetch inside `useEffect`.** The cache is the state. An effect that copies `data` into state is the derived-state bug wearing a data-layer costume.

## States

- `isPending` — no data yet (v5 name; `isLoading` is `isPending && isFetching`, and is not what you want for a disabled query).
- `isFetching` — a request is in flight, including a background refetch over data you already show. Use it for a subtle indicator, never for the main skeleton.
- `data` is `undefined` while pending — type-narrow on the state, don't `data!` or `data?.x ?? fallback` your way past it.
- Loading, empty and error are three different renders. A list that returns `null` on an empty array is a bug; empty needs its own copy.
- Use `throwOnError` plus an error boundary for "this screen cannot render without it"; handle `isError` inline for a region the page survives without.

## Mutations

- Mutation hooks live in the **feature** that performs the action and invalidate the **entity** keys that action affects — features may import entities, never the reverse.
- **Invalidate in `onSuccess`, as narrowly as the change allows.** Editing one item invalidates that item's key plus the lists that contain it; it does not sweep the entity. Sweep with `keys.all()` on create and delete, where you can't know which lists changed.
- `setQueryData` instead of an invalidation **only when the server returned the full updated object**. Writing a partial or client-guessed shape into the cache is how a screen starts showing a field the API never sent.
- **Optimistic updates are for cheap, reversible, high-frequency actions** — a toggle, a reorder, a like. Not for a create with server-generated fields, and not for anything the user must trust as committed. The full `onMutate`/`onError`/`onSettled` shape, including cancelling in-flight refetches and the rollback context, is in [references/mutation-recipes.md](references/mutation-recipes.md).
- Cache work, navigation, toasts and storage writes go in `onSuccess`/`onError` on the hook — not in the component's submit handler, and never in an effect watching `isSuccess`.
- Disable the submit control on `isPending`. Don't swap the label for the word "Loading".

## Prefetching

Prefetch on intent — `onMouseEnter` and `onFocus` on the trigger — for the one or two navigations the user is visibly about to make. `queryClient.prefetchQuery(entityQueries.byId(id))` reuses the same options object, so the key can't drift from the real query. Pair it with the lazy-route preload from the `react` skill: the chunk and its data should be in flight together. Don't prefetch a whole list on mount — that's just fetching, later.

## Never

- Guess a response shape. It comes from the module's types, which come from the contract.
- Call `invalidateQueries()` with no argument — that refetches the entire app.
- Put `queryClient.setQueryData` in a component body or an effect.
- Add a `useEffect` to run a refetch that `enabled` or a key change already does.
- Reach for `refetch()` where invalidation is correct. `refetch()` ignores the rest of the cache and every other observer of that key.

## References

| Writing | Read |
|---|---|
| dependent, parallel, derived, paginated or infinite reads | [references/query-recipes.md](references/query-recipes.md) |
| optimistic updates, targeted cache writes, cross-component mutation state | [references/mutation-recipes.md](references/mutation-recipes.md) |

Anything neither file covers: fetch current upstream docs via the `context7` MCP server (`/tanstack/query`) rather than guessing — v4 answers are still the top search result and v5 renamed a lot.
