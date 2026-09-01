---
name: react
description: React 19 and React Compiler rules — where state belongs, when memoization is warranted, what effects are actually for, refs and context, error boundaries, and how to split code with lazy + Suspense. Use when writing or reviewing React components, adding a route/modal/heavy widget, chasing a re-render problem, or reaching for useEffect/useMemo/useCallback/useRef/useContext.
---

# React 19

## Where state belongs

Most re-render problems are placement problems, and no amount of memoization fixes one.

- **Push state down.** State used by one subtree lives in that subtree. A dialog's open flag hoisted to the page re-renders the page on every toggle.
- **Lift only to the closest common ancestor** of the components that actually read it — not to the nearest context, and not to a store.
- **Server data is not state.** It lives in the query cache. Copying `data` into `useState` gives you two sources of truth that drift; see the `tanstack-query` skill.
- **URL state is not state either.** Filters, tabs, pagination and the open entity belong in the query string when the user would expect back, refresh and a shared link to work.
- **Anything computable from props or existing state is not state.** Compute it in render.
- **Group state that always changes together** into one object or a reducer; split state that changes independently. Two flags updated in the same handler are one piece of state.
- A `useState` whose value never triggers a render — an id, a timer handle, the previous value — is a `ref`, not state.

## Effects

An effect synchronizes with something outside React. That is the whole list.

- **Derived state is computed in render**, not stored in state and synced by an effect.
- **Event-driven side effects go in the handler.** If it happens because the user clicked, it does not belong in an effect.
- An effect that only sets state from props is always wrong — delete it and compute the value.
- Reach for a `key` to reset state on identity change, before reaching for an effect.
- Data fetching is not a use case for an effect in this stack — the query cache owns it.
- Every effect that subscribes, opens or schedules returns a cleanup. An effect with no cleanup and no external target is usually misplaced logic.

## Memoization

The React Compiler removes the reflex, not the responsibility.

- Memoize when the work is genuinely expensive **and** its inputs are stable. Both, not either.
- Dependencies that change every render mean a dead cache — you pay the comparison and never hit. Drop it.
- Fix the algorithm before caching the result. A `useMemo` around an O(n²) loop is still O(n²).
- Do not wrap a cheap expression in `useMemo`, and do not memoize a component whose props are new objects each render.

## Rendering

- No `find`/`filter` inside `map`, no nested loops in render — build a lookup map once.
- No `key={index}` on a list that can reorder, filter or grow.
- Hoist static JSX and static objects above the component.
- Never define a component inside another component's render — it remounts its whole subtree every time.
- `useState` initializers that do real work take the lazy form: `useState(() => expensive())`.
- Prefer functional `setState` when the next value depends on the previous one.

## Refs and escape hatches

- A ref holds a value that must survive re-renders without causing them: a DOM node, a timeout handle, a "has this already run" flag, the latest value read by a stable callback.
- **Never read or write `ref.current` during render.** Render must be pure; refs are for handlers, effects and cleanup.
- `ref` is a plain prop in React 19 — no `forwardRef`. A ref callback may return a cleanup function, which replaces the old "called with null" dance.
- Reach for the DOM only for things React does not model: focus, scroll position, measurement, media playback, a third-party library's mount node. Anything expressible as state is state.

## Context

- Context is for values that are genuinely ambient and rarely change — theme, locale, the current session, a form's `FormProvider`. It is not a state manager and not a way to avoid passing two props.
- **Every consumer re-renders when the value changes.** Split a context that mixes a stable value with a churning one, or you have wired the churn into every subtree that only wanted the stable half.
- Before adding one, try composition: passing JSX as `children` or a prop usually removes the drilling that motivated the context.
- React 19 renders the context itself as the provider — `<ThemeContext value={theme}>`, no `.Provider`. `use(Context)` reads it and, unlike `useContext`, may be called conditionally.

## Code splitting

Default to lazy for anything the first paint does not need. A route the user may never visit, or a dialog they may never open, has no business in the initial bundle.

**Always lazy:**

- **Pages / routes.** Every route-level component loads through `lazy()` (or the router's own lazy route option). This is the split with the highest payoff — one route's dependencies stop being everyone's download.
- **Modals, dialogs, drawers, sheets, popovers with real content.** They render on an interaction that may never happen. Split the *content*, not the trigger: the button stays eager, what it opens is lazy.
- **Heavy third-party widgets** — charts, rich-text and code editors, maps, date pickers, PDF and media viewers, drag-and-drop. Import them at the point of use.
- **Anything behind a tab, an accordion panel, a wizard step, or a permission check** that most sessions don't reach.

**Never lazy:** anything above the fold on the first screen, or a component small enough that the request costs more than the bytes. Lazy-loading those only adds a network waterfall.

## Suspense boundaries

- Wrap each lazy tree in `<Suspense>` with a fallback that has the **shape** of the content — a skeleton at the right size. A spinner in place of a page is a layout shift waiting to happen.
- Place boundaries where a partial page is still useful: one per route, plus one around each independently-loading region. A single boundary at the root turns every lazy chunk into a full-page blank.
- With Suspense-enabled data fetching (`useSuspenseQuery` and friends), the same boundary covers both the code and its data — don't also thread `isLoading` through the component.
- Preload on intent for things the user is visibly about to open: start the import on hover or focus of the trigger, so the chunk is in flight before the click. Prefetch its data on the same event.
- `useTransition` around a navigation that swaps a lazy route keeps the current screen visible instead of flashing the fallback.

## Error boundaries

- **Every Suspense boundary has an error boundary beside it.** A chunk fetch fails on a flaky network and after every deploy; without one, the whole app goes blank on a stale hashed filename.
- Boundaries go where a recovery is meaningful: one at the app root as a last resort, one per route, one around any region that can fail alone. A single root boundary turns one broken widget into a broken app.
- The fallback offers a way out — retry, go back, reload — and retrying must reset the boundary so the failed import or query is re-attempted, not just re-rendered.
- They catch errors thrown while rendering, not in event handlers, timeouts or rejected promises you never awaited. Handle those where they happen.

## Actions, transitions and `use`

Shapes and full examples: [references/actions.md](references/actions.md).

- `useTransition` marks an update as interruptible so the current UI stays interactive; its async form owns the pending flag for the whole action, so you stop hand-rolling `setIsLoading` around non-form async work — a navigation, a tab that mounts a lazy panel, a filter that swaps an expensive view.
- `useOptimistic` shows the expected result while the action is in flight and reverts on its own if it fails — the right tool when the optimistic value is local. When the value lives in the query cache, do it there instead.
- **`useActionState`, `<form action={...}>` and `useFormStatus` have no place in a project on React Hook Form + Zod** — not even for a one-field form. RHF + `zodResolver` owns every submit path, its pending flag and its error surface; and in a client-rendered SPA there is no server action for `action` to call. See [references/actions.md](references/actions.md) for what breaks if you mix them.
- `use(promise)` reads a promise during render and suspends; `use(Context)` reads context conditionally. `use` is not a general data-fetching hook — the promise must come from a cache or a suspense-aware library, never from a call made in render.
- `useDeferredValue` for an expensive derived view that may lag behind input, with an initial value on first render where one helps.

## React 19 specifics

- No `forwardRef` — `ref` is a normal prop.
- `<title>`, `<meta>` and `<link>` render anywhere and hoist to `<head>`.
- Don't reintroduce patterns the Compiler already handles (blanket `memo` on every leaf).

## Reviewing

The defects worth reporting, in order of how often they actually hurt: state held above the only subtree that reads it, or duplicating server data the cache already owns; an effect doing derived state, an event side effect, or a fetch; a linear scan inside a loop; a memo whose deps churn; an index key on a dynamic list; a context whose value churns on every render; a route, modal or heavy widget imported eagerly; a Suspense boundary with no error boundary beside it; a ref read during render.
