# Actions, Transitions and `use`

> Canonical code shape. Replace the placeholders (`[Entity]`, `I[Entity]`) with real names.

## `useTransition` — async actions without a manual pending flag

```tsx
const [isPending, startTransition] = useTransition()

const handleSubmit = () => {
  startTransition(async () => {
    await submit(payload)
    // State updates after the await are still inside the transition.
  })
}

return <Button onClick={handleSubmit} disabled={isPending}>Save</Button>
```

`isPending` stays `true` for the whole async body, so a hand-rolled `const [isLoading, setIsLoading] = useState(false)` around a submit is redundant. Errors are not caught for you — `try`/`catch` inside the transition, or let an error boundary take it.

Around a navigation, a transition keeps the outgoing screen on-screen instead of flashing a Suspense fallback:

```tsx
startTransition(() => navigate(paths.[entity].details(id)))
```

**In a project using React Hook Form,** `formState.isSubmitting` and the mutation's `isPending` already cover form submits. Reach for `useTransition` for non-form async work — a navigation, a tab switch that mounts a lazy panel, a filter that swaps an expensive view.

## `useOptimistic` — local optimistic value

```tsx
const [optimisticItems, addOptimisticItem] = useOptimistic(
  items,
  (current: I[Entity][], pending: I[Entity]) => [...current, pending]
)

const handleAdd = (draft: I[Entity]) => {
  startTransition(async () => {
    addOptimisticItem(draft)
    await create(draft)
  })
}
```

- `addOptimistic` may only be called inside a transition or an action. Outside one, React warns and the value snaps back immediately.
- The optimistic value reverts on its own when the action settles — there is no rollback to write. That is the whole advantage over doing it by hand.
- The base value must be the real one. Feeding it state you already mutated optimistically gives you a double-applied update.

**Choose one layer.** If the value comes from the query cache, do the optimistic update in the mutation's `onMutate` (see the `tanstack-query` skill) and leave `useOptimistic` alone. Using both on the same value produces two competing rollbacks.

## `useActionState` / `<form action>` / `useFormStatus` — not in this stack

Skip them. This is not a style preference, it is that they occupy a slot React Hook Form already fills:

- **The submit path.** `<form action={formAction}>` and `<form onSubmit={handleSubmit(...)}>` are two handlers for one event. Wire both and whichever React invokes first wins — in practice the action runs, `handleSubmit` never does, and the Zod schema silently never validates. There is no configuration that makes them cooperate.
- **The pending flag.** `useActionState`'s third return value and `useFormStatus().pending` duplicate `formState.isSubmitting` and the mutation's `isPending`, which the form already has in scope.
- **The error surface.** The action's returned state duplicates `formState.errors`, which is already driven by the resolver and already rendered through `FieldDescription`.
- **The server action.** The `action` prop exists to post to one. A client-rendered SPA has none; here it degrades to a callback with extra ceremony and no client validation.

So there is no "small form" exception — a newsletter input or a one-field filter still goes through `useForm` + `zodResolver` with its schema in `model/schemas.ts`, because a second form pattern costs every future reader a decision. See the `react-hook-form-zod` skill for the shape.

What React 19 *does* add to a form in this stack: `useTransition` for the non-form async work around it (a navigation after success), and `useOptimistic` for a local optimistic value — both above.

## `use`

```tsx
// Context — may be called conditionally, unlike useContext.
const theme = use(ThemeContext)

// Promise — suspends until it resolves. The promise must be created outside render.
const message = use(messagePromise)
```

The promise has to be stable across renders: created by a cache, a suspense-aware library, or passed down as a prop. `use(fetch(url))` in a component body creates a new promise every render and suspends forever.

In this stack the promise form is rarely the right tool — `useSuspenseQuery` gives you the same suspension with caching, deduplication and invalidation. Reach for `use(Context)` freely; reach for `use(promise)` only when there is a real promise you already own.
