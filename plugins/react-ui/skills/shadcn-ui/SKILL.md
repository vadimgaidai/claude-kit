---
name: shadcn-ui
description: shadcn/ui + Tailwind conventions — semantic tokens instead of raw colors, extending primitives via ComponentProps, compound components, icon and spacing rules that survive dark mode. Use when building or fixing UI on shadcn/Tailwind, wrapping a primitive, or deciding how to style a component.
---

# shadcn/ui + Tailwind

## Use a primitive before writing one

1. Does an installed primitive already cover this? Use it directly (`@/shared/ui/[name]` or wherever the project keeps them) — import the module, not a barrel.
2. Not installed? Search the registry with the `shadcn` MCP server and add it with the CLI. Don't hand-roll a Dialog.
3. Wrapping a primitive? Extend its prop type via `ComponentProps<typeof X>` and forward `...rest` — see [references/extending-components.md](references/extending-components.md).
4. Two or more tightly coupled sub-components? Compound Component Pattern with a `.Root` — see [references/compound-component.md](references/compound-component.md).
5. Otherwise one exported component per file, props as an interface.

## Styling

- **Semantic tokens only** — `bg-background`, `text-foreground`, `border-border`, `text-muted-foreground`. Never a raw hex, never an arbitrary value where a token exists.
- **No `dark:` overrides in components.** Dark mode is a token-layer concern; a `dark:` in a component means the token set is wrong. Fix the tokens (see the `theme-sync` agent), not the component.
- **`size-*` when width equals height** — `size-4`, not `h-4 w-4`.
- **`gap-*` over `space-y/x-*`** — space utilities break on wrapping and on flex direction changes.
- `className` on an exported component is for **layout positioning only** (margins, grid placement). Anything else belongs inside the component or in a variant.
- Spacing and sizes come from the Tailwind scale. A raw px value is a signal the design has no matching token — surface that rather than hardcoding it.

## Icons

- `lucide-react`. Inside a Button, mark placement with `data-icon="inline-start"` / `data-icon="inline-end"` and let the Button own the sizing — no `size-*` on the icon there.
- A standalone icon gets an explicit `size-*` and, when it carries meaning, an accessible label.

## Component shape

- Extract a sub-component once JSX passes ~80 lines, or when a chunk owns its own state.
- Extract a helper when logic is reused or branches more than once — never an `if/else` chain inside JSX.
- One file does one thing: fetch, map, or render. Growing state moves into a `use-*` hook.
- Loading, empty and error are real states, not afterthoughts. A list that renders nothing on empty is a bug.

The reference files use placeholders — `[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers. Real infrastructure (`httpClient`, primitives under `@/shared/ui/`) keeps its real name.

## Never

- Copy a primitive's source to tweak one style — extend it.
- Reach for an arbitrary Tailwind value (`w-[327px]`) when a scale step or token fits.
- Ship a component that only looks right in one theme.
