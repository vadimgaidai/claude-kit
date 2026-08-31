---
name: implement
description: Implements a planned unit of work end-to-end in one pass — types, data layer, schemas, UI, wiring — from `.planning/[name]/PLAN.md`. Use when the user wants to build, implement, or execute a plan, feature, module or issue. Runs in the main session; do not fan out to subagents.
---

# Implement

You implement a whole unit of work in one pass: every layer of every module in the plan, in build order, in this session.

**Do not delegate layers to subagents.** Types, data layer and UI share one contract and one set of conventions; splitting them across agents means re-reading all of it per agent, which costs far more than it saves.

## Inputs

- `.planning/[name]/PLAN.md` — the whole brief. Missing? Ask the user to run `/core:analyze`, or take a direct brief for a small change.
- `.planning/[name]/contract.md` — **authoritative for every request/response shape.** Read it; never re-fetch the raw OpenAPI, never invent a field it does not list.
- `.planning/[name]/DESIGN.md` when the plan names a design. A value flagged "no match" is a real gap: surface it, don't invent one.

## Learn the conventions before writing

In this order, cheapest first:

1. The project's `CLAUDE.md` and `.claude/rules/` — project facts and machine-enforced rules.
2. Any structure or library skill that applies (`feature-sliced-design`, `react-hook-form-zod`, `shadcn-ui`, `tanstack-query`…). Load the one you need, not all of them.
3. **The sibling module the plan names** — one existing module of the same kind, read once. It is the tone reference: file layout, naming, export style, error handling.

Read the one thing that matches what you are about to write. Never read a whole conventions library up front.

## Order (per module, in the plan's build order)

1. Constants and enumerations.
2. Types — derived from `contract.md` exactly: required vs optional, enums, formats, nullability.
3. HTTP layer — one function per endpoint, typed both ways, using the project's existing client.
4. Data layer — queries / mutations, wired to the cache keys the plan names.
5. Validation schemas (forms).
6. UI — every state the plan lists (loading / empty / error) and every role rule. Localized text where the project is localized.
7. Public exports / barrels.
8. Routes and pages last, once the modules they mount exist.

If the contract disagrees with the plan's prose, **the contract wins** — say so, then follow it.

## Rules

- Domain types, lookup maps and magic constants belong in the module's model layer, not inline in components. Only a component's own props type stays local.
- A file does one thing (fetch / map / render). Extract a sub-component when JSX grows past ~80 lines, a hook when state grows, a helper when logic branches.
- No `any`. No values guessed where a contract, token or existing constant exists.
- Don't restate what machine checks already enforce — formatters and linters own formatting and naming. Never add a lint-disable to get past one.

## Verify

Run the project's typecheck. Do not run a full build or lint unless the project has no other check — pre-commit hooks and CI own those.

## Output

Files created/edited, anything newly required (a package to install, a UI primitive to add), and anything in the plan you did **not** build, with the reason. Then: "Next: `/core:review`."
