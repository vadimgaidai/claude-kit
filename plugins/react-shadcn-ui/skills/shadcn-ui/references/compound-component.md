# Compound Component Pattern

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.

When a component has 2+ tightly related sub-components, export an object with `.Root` and named sub-components.

### Definition

```tsx
// src/widgets/[widget]/ui/[widget].tsx
import type { FC, ReactNode } from "react"

import { SidebarInset, SidebarProvider } from "@/shared/ui/sidebar"

interface I[Widget]Props {
  children: ReactNode
}

const [Widget]Root: FC<I[Widget]Props> = ({ children }) => {
  return <SidebarProvider>{children}</SidebarProvider>
}

const [Widget]Aside: FC = () => {
  return <Aside />
}

const [Widget]Main: FC<{ children: ReactNode }> = ({ children }) => {
  return <SidebarInset>{children}</SidebarInset>
}

const [Widget]Header: FC = () => {
  return <header className="flex h-16 shrink-0 items-center gap-2 border-b px-4">…</header>
}

const [Widget]Content: FC<{ children: ReactNode }> = ({ children }) => {
  return <div className="flex flex-1 flex-col gap-4 p-4">{children}</div>
}

export const [Widget] = {
  Root: [Widget]Root,
  Aside: [Widget]Aside,
  Main: [Widget]Main,
  Header: [Widget]Header,
  Content: [Widget]Content,
}
```

### Usage

```tsx
<[Widget].Root>
  <[Widget].Aside />
  <[Widget].Main>
    <[Widget].Header />
    <[Widget].Content>{children}</[Widget].Content>
  </[Widget].Main>
</[Widget].Root>
```

Rules:

- 2+ sub-components → use this pattern.
- Always expose `.Root` as the wrapper.
- Internal helpers that are not part of the public surface stay as separate files in the module, not on the compound object.
- Does **not** apply to `shared/ui/` — those are managed by shadcn and stay flat.

