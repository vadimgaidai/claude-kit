---
name: react-hook-form-zod
description: Repo-specific React Hook Form + Zod patterns — schema in model/schemas.ts, zodResolver, Field/FieldGroup layout, z.input === z.output rule. Use when building or fixing forms, validation schemas, resolver type errors, or multi-step/field-array forms.
---

# React Hook Form + Zod — repo quick reference

How forms are built **in my projects**. Canonical schema shape: [references/schemas.md](references/schemas.md). For anything this file does not cover, fetch the current upstream docs via the `context7` MCP server (`/react-hook-form/react-hook-form`, `/colinhacks/zod`) rather than guessing.

## Where things live

- Schema + inferred type → `model/schemas.ts` (FSD projects) or a `schemas.ts` colocated with the form (non-FSD projects): `export const fooSchema = z.object({...})` + `export type TFooFormValues = z.infer<typeof fooSchema>`. Never inline schemas in components or the API layer.
- Form component → `ui/[name]-form.tsx` (FSD) / `[name]-form.tsx`, one form per file. Submit target is a mutation hook from the module's mutations file.

## The form recipe

```tsx
const form = useForm<TFooFormValues>({
  resolver: zodResolver(fooSchema),
  defaultValues: { email: "", password: "" }, // ALWAYS provide — avoids uncontrolled→controlled warnings
})
```

- Layout: `FieldGroup` + `Field` + `FieldLabel` + `FieldDescription` — never raw `div`s, never legacy `Form`/`FormField`/`FormItem`. Array rows (tags, photo URLs) are still `Field`s.
- `register` for plain inputs; `Controller` for Select/Combobox/DatePicker.
- Errors via `FieldDescription` driven by `errors.[field]?.message`. Let RHF + Zod validate — no manual `onChange` validation.
- Submit button: `disabled={isSubmitting || mutation.isPending}` + `Spinner` with `data-icon="inline-start"` — never just swap the label.
- Numbers from inputs: `z.coerce.number()`.
- Multi-step → step components sharing state via `FormProvider`.

The reference files use placeholders — `[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers. Real infrastructure (`httpClient`, primitives under `@/shared/ui/`) keeps its real name.

## Never do

- **Never let `z.input` diverge from `z.output`** — no `z.preprocess` / `.transform` in a form schema. It desyncs `zodResolver` from `useForm`/`Control` and the file stops compiling. A form schema round-trips the form's own values; normalize "empty but present" values in `onSubmit` when building the payload, not in the schema.
- Never introduce a schema pattern with no precedent in [references/schemas.md](references/schemas.md) or in the repo.
- Never duplicate an inferred type as a hand-written interface — `z.infer` is the source of truth.

