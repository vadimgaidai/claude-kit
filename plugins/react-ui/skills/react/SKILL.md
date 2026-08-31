---
name: react
description: React 19 and React Compiler rules — where state belongs, when memoization is warranted, what effects are actually for, and how to split code with lazy + Suspense. Use when writing or reviewing React components, adding a route/modal/heavy widget, chasing a re-render problem, or reaching for useEffect/useMemo/useCallback.
---

# React 19

## Effects

An effect synchronizes with something outside React. That is the whole list.

- **Derived state is computed in render**, not stored in state and synced by an effect.
- **Event-driven side effects go in the handler.** If it happens because the user clicked, it does not belong in an effect.
- An effect that only sets state from props is always wrong — delete it and compute the value.
- Reach for a `key` to reset state on identity change, before reaching for an effect.

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
- **Pair every Suspense boundary with an error boundary.** A chunk fetch fails on a flaky network or after a deploy; without one, the whole app goes blank. The error boundary's retry should be able to re-attempt the import.
- With Suspense-enabled data fetching (`useSuspenseQuery` and friends), the same boundary covers both the code and its data — don't also thread `isLoading` through the component.
- Preload on intent for things the user is visibly about to open: start the import on hover or focus of the trigger, so the chunk is in flight before the click.
- `useTransition` around a navigation that swaps a lazy route keeps the current screen visible instead of flashing the fallback.

## React 19 specifics

- No `forwardRef` — `ref` is a normal prop.
- `useTransition` for state updates that can lag behind input; `useDeferredValue` for expensive derived views.
- Don't reintroduce patterns the Compiler already handles (blanket `memo` on every leaf).

## Reviewing

The defects worth reporting, in order of how often they actually hurt: an effect doing derived state; a linear scan inside a loop; a memo whose deps churn; state that should have been computed; an index key on a dynamic list; a route, modal or heavy widget imported eagerly; a Suspense boundary with no error boundary beside it.
