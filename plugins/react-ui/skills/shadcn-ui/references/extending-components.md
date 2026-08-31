# Extending Base Components

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.

When you build on top of a shadcn (or any base) component, **inherit its props** rather than redeclaring HTML attributes or variants.

### shadcn `Button` — the base

```tsx
// src/shared/ui/button.tsx
function Button({
  className,
  variant = "default",
  size = "default",
  asChild = false,
  ...props
}: React.ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & {
    asChild?: boolean
  }) {
  // ...
}
```

### A domain-specific wrapper (`SubmitButton`)

```tsx
// features/[feature]/ui/submit-button.tsx
import type { ComponentProps, FC } from "react"
import { Loader2 } from "lucide-react"

import { Button } from "@/shared/ui/button"
import { cn } from "@/shared/lib"

interface ISubmitButtonProps extends ComponentProps<typeof Button> {
  isPending?: boolean
}

export const SubmitButton: FC<ISubmitButtonProps> = ({
  isPending,
  disabled,
  className,
  children,
  ...rest
}) => {
  return (
    <Button
      type="submit"
      disabled={disabled || isPending}
      className={cn("relative", className)}
      {...rest}
    >
      {isPending ? <Loader2 className="size-4 animate-spin" /> : children}
    </Button>
  )
}
```

What this gets us for free:

- All HTML `<button>` attributes (`onClick`, `aria-*`, `data-*`, `form`, `name`, `value`, …)
- All shadcn variants (`variant`, `size`, `asChild`) via `VariantProps`
- `className` merging via `cn()`
- `disabled` works correctly because we spread `...rest` *after* our own override only where needed

Rules:

- Use `ComponentProps<typeof Button>` (or the exported `ButtonProps`) — never copy-paste props.
- Forward `...rest` to the base component.
- Don't re-declare variant props — re-export base variants if a consumer needs them.
- Wrappers tied to a domain go inside the matching feature/entity/widget `ui/` folder, never in `shared/ui/`.

### Another example — Input with leading icon

```tsx
// features/[feature]/ui/search-input.tsx
import type { ComponentProps, FC, ReactNode } from "react"

import { Input } from "@/shared/ui/input"
import { cn } from "@/shared/lib"

interface ISearchInputProps extends ComponentProps<typeof Input> {
  icon: ReactNode
}

export const SearchInput: FC<ISearchInputProps> = ({ icon, className, ...rest }) => {
  return (
    <div className="relative">
      <span className="absolute top-1/2 left-2 -translate-y-1/2 text-muted-foreground">{icon}</span>
      <Input className={cn("pl-8", className)} {...rest} />
    </div>
  )
}
```

