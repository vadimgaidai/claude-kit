---
name: review
description: Reviews the current diff against the plan's acceptance criteria, the API contract and the project's conventions. Takes an optional focus argument (`correctness`, `contract`, `consistency`, `perf`, comma-separated) to narrow the report. Reports findings; applies fixes only when asked. Use before opening a PR or merging, or when the user asks to review changes.
---

# Review

Scope is **the diff**, not the modules it touches. Do not read whole files where a hunk answers the question.

## 0 — Focus

An argument, when given, names the passes to run — `correctness`, `contract`, `consistency`, `perf` — separated by commas or spaces (`/feature-workflow:review contract,perf`). Anything unrecognized, or no argument at all, runs all four.

A focused run is a **shorter report over the same hunks**, never a wider read. Scope stays the diff, section 1 still runs, and the passes you skipped go unmentioned rather than being reported as clean.

`security` is deliberately not a pass here: Claude Code ships `/security-review` over the same diff, and a half-version of it inside a conventions review would be worse than either.

## 1 — Scope

```bash
git status --short
git diff $(git merge-base HEAD "$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|origin/||' || echo main)")..HEAD
```

Include unstaged and untracked files. If a `.planning/*/PLAN.md` covers this work, read it and its `contract.md`; otherwise review against the project's conventions alone.

## 2 — Passes

**Correctness** — does it do what the plan says? Every acceptance criterion gets a verdict backed by `file:line`, not a summary.

**Contract** — every type and payload against `.planning/*/contract.md`: required vs optional, enums, nullability. A field that is not in the contract is a bug, not a nicety.

**Consistency** — each changed file against the sibling module it should resemble, and against any structure skill that governs it. Name what you compared against.

**Performance** — render and data-layer cost, on the evidence in the diff. Not a profiling exercise: only the shapes below.

**Defects worth the reader's time**, tagged with the pass that owns each one — a focused run reports only its own tags:
- `correctness` — effects doing derived state, an event side effect, or a fetch
- `perf` — a linear scan inside a loop; nested loops in render; memoization whose dependencies change every render (dead cache)
- `correctness` — an index key on a list that can reorder, filter or grow
- `correctness` — a query key hand-written at a call site instead of built by the entity's key factory, or a `queryFn` passed as a bare reference (which silently disables `exhaustive-deps`). Do **not** re-audit key completeness — that rule already errors on it.
- `correctness` — a mutation that invalidates nothing, or sweeps the whole entity for a single-item edit
- `contract` — a mutation writing a client-assembled object into the cache instead of the server's response
- `consistency` — a local `onError` re-handling what the shared query/mutation cache already handles, or a QueryClient default restated per query
- `correctness` — state that could be computed; an optional-chain silencing a crash instead of fixing it
- `correctness` — UI states the plan requires but that aren't implemented
- `contract` — guessed values where a contract, token or constant exists; `any`

**Skip entirely** — whatever lint and formatting already guarantee. Where `@tanstack/eslint-plugin-query` is enabled that includes query-key completeness, so never report "this variable is missing from the key": the rule already errored on it, or the `queryFn` is a bare reference, which is the finding worth reporting instead. Re-checking a machine check is wasted output.

## 3 — Verify

Run the project's typecheck. Nothing heavier.

## 4 — Report

Findings ordered by severity, each as `file:line` — the claim — why it matters. No emoji, no praise, no restating what the code does. Acceptance criteria as a `[x]`/`[ ]` list — on a focused run that omits `correctness`, skip the list rather than guessing at it. If nothing is wrong, say so in one line, naming which passes ran.

Apply fixes only when the user asks, or when a finding is mechanical and unambiguous — and say which you applied.
