# FSD — Module Anatomy

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.

A **module** is a self-contained piece of business logic on one of the FSD layers (`entities`, `features`, `widgets`, `pages`). Every module has the same skeleton:

```
[module]/
├── api/         # HTTP calls + query/mutation hooks
├── hooks/       # use-*.ts hooks composed from api/model
├── model/       # types.ts, constants.ts, schemas.ts (domain only)
├── ui/          # React components (optional)
└── index.ts     # public barrel — only file outside code may import
```

Layer-specific differences:

- **Entity** has `api/[name].queries.ts` (read-side) — no mutations.
- **Feature** has `api/[name].mutations.ts` (write-side) — no queryOptions.
- **Widget** usually has only `ui/` + `model/` + `config/`.
- **Page** is just one component file.

Layer dependency direction (a higher layer may import a lower one, never the reverse):

```
app → pages → widgets → features → entities → shared
```

