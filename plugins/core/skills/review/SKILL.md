---
name: review
description: Reviews the current diff against the plan's acceptance criteria, the API contract and the project's conventions. Reports findings; applies fixes only when asked. Use before opening a PR or merging, or when the user asks to review changes.
---

# Review

Scope is **the diff**, not the modules it touches. Do not read whole files where a hunk answers the question.

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

**Defects worth the reader's time**:
- effects doing derived state or event side effects — derive in render, act in the handler
- a linear scan inside a loop; nested loops in render; index keys on dynamic lists
- memoization whose dependencies change every render — dead cache
- state that could be computed; an optional-chain silencing a crash instead of fixing it
- UI states the plan requires but that aren't implemented
- guessed values where a contract, token or constant exists; `any`

**Skip entirely** — whatever lint and formatting already guarantee. Re-checking them is wasted output.

## 3 — Verify

Run the project's typecheck. Nothing heavier.

## 4 — Report

Findings ordered by severity, each as `file:line` — the claim — why it matters. No emoji, no praise, no restating what the code does. Acceptance criteria as a `[x]`/`[ ]` list. If nothing is wrong, say so in one line.

Apply fixes only when the user asks, or when a finding is mechanical and unambiguous — and say which you applied.
