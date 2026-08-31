# claude-kit

Claude Code plugins by [@vadimgaidai](https://github.com/vadimgaidai).

A feature goes from a sentence to reviewed code in three steps — plan, implement, review — and the whole thing runs in **one context**. That constraint is the point of this repo, not a detail of it: the previous version of this workflow split the same job across six specialised subagents and spent ~445k tokens producing ~840 lines of code. Collapsing it into a single pass, and moving everything a script can guarantee out of the prompt, is what the plugins below encode.

## Install

```bash
/plugin marketplace add vadimgaidai/claude-kit
/plugin install core@vadimgaidai
```

Then add what the project actually is:

```bash
/plugin install react-ui@vadimgaidai   # shadcn/ui + Tailwind
/plugin install fsd@vadimgaidai        # Feature-Sliced Design
```

Skills are namespaced by plugin: `/core:analyze`, `/core:implement`, `/core:review`.

To register the marketplace for everyone who clones a repo, add it to that repo's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "vadimgaidai": { "source": { "source": "github", "repo": "vadimgaidai/claude-kit" } }
  },
  "enabledPlugins": ["core@vadimgaidai", "react-ui@vadimgaidai", "fsd@vadimgaidai"]
}
```

Collaborators still run `claude plugin install` once; the settings entry registers the marketplace and declares which plugins the project expects.

## One plan, one pass

```
/core:analyze     →  .planning/[name]/PLAN.md  (+ contract.md, scaffolded folders)
/core:implement   →  every module of that plan, in one pass
/core:review      →  the diff, against the plan and the contract
```

`/core:analyze` interviews you in the main session — one question at a time, recommendation first — and writes **one** plan for the whole request. Not a spec per module: the implementer should open one document, not eleven.

`/core:implement` then builds every layer of every module without handing off. Types, data layer and UI share one contract and one set of conventions; giving each layer its own subagent means paying to rebuild that shared context on every hand-off, which is where the 445k went.

Subagents are used in exactly two places, both where an isolated context genuinely pays for itself: `@theme-sync`, because Figma MCP payloads are enormous and only a short token map needs to come back, and `@bug-fixer`, because a bug hunt should not pollute the session that follows it.

`/core:analyze` is a skill rather than an agent for a mundane reason: interactive questions don't surface from subagents.

## Three plugins, because projects differ

The split exists so the same workflow survives contact with a codebase that shares none of your conventions.

| You are working on | Install |
|---|---|
| any TypeScript project, including one you didn't set up | `core` |
| a React app on shadcn/ui + Tailwind | `core` + `react-ui` |
| a project that follows Feature-Sliced Design | `core` + `react-ui` + `fsd` |

`core` holds no opinion about file layout. `/core:analyze` records **which existing module the work mirrors**, and `/core:implement` reads that one module as its shape reference. Install an architecture plugin and that opinion arrives; don't, and the nearest sibling in the repo supplies it.

### `core` — the workflow

| Component | What it does |
|---|---|
| `/core:analyze` | Q&A → one `PLAN.md` + a sliced API contract + scaffolded folders |
| `/core:implement` | Implements the plan end-to-end in one pass |
| `/core:review` | Reviews the diff against acceptance criteria, the contract, and the module it should resemble |
| `api-contract` | Slices an OpenAPI/Swagger contract down to the endpoints one feature needs |
| `@bug-fixer` | Reproduces, localizes and fixes one bug with the smallest diff |
| hook | Prettier on every write |

### `react-ui` — shadcn/ui, Tailwind, forms

| Component | What it does |
|---|---|
| `react` | React 19 + Compiler: what effects are for, when memoization is warranted, `lazy` + Suspense boundaries, render-path defects |
| `shadcn-ui` | Semantic tokens over raw colors, extending primitives via `ComponentProps`, compound components, icon and spacing rules that survive dark mode |
| `react-hook-form-zod` | Schema placement, the `z.input === z.output` rule, `Field`/`FieldGroup` layout, resolver pitfalls |
| `@theme-sync` | Maps a Figma file's variables onto the shadcn token set — light **and** dark — or writes a screen's token map to `DESIGN.md` |

### `fsd` — Feature-Sliced Design

| Component | What it does |
|---|---|
| `feature-sliced-design` | Layers, import direction, module anatomy, the model split, and canonical code shapes in `references/` |
| `scaffold.sh` | Deterministic module skeletons — kebab-case validated, refuses to overwrite |
| hooks | Block a write that violates import direction, file naming, or barrel-import rules |

## What the tooling does instead of the model

Every one of these replaced something a model used to be asked to do on every run.

| Instead of | The kit does | Measured |
|---|---|---|
| reading a whole OpenAPI contract, then guessing the gaps | `contract-slice.mjs` emits only the endpoints you asked for, `$ref`s inlined, required/optional/enums explicit | Petstore: 17106 → 2857 characters for 3 endpoints, at zero model cost |
| a subagent that created empty module folders | `scaffold.sh` | ~36k tokens per module → 0 |
| prompting for formatting and naming, then reviewing them | a PostToolUse Prettier hook and PreToolUse validators that block a bad write | formatting and boundary checks leave the prompt entirely |
| loading a rules library on every agent start | short skills that load on demand, each pointing at the **one** reference file that matches | one reviewer's skill bundle alone was ~26k tokens per run |

## Rules this kit follows

Each of these is a mistake the earlier version made, written down so it doesn't come back.

- **No per-layer fan-out.** A subagent earns its keep when it isolates a large or noisy context, not when it re-reads the same contract a fourth time.
- **One artifact per request.** One `PLAN.md`, not a spec per module plus an API doc plus a design doc plus issue files.
- **Skills stay under ~4k characters.** Depth goes in `references/`, in a bundled script, or in upstream docs fetched through `context7` — never a 40k monolith that loads in full every time.
- **Read one example, not the library.** Every skill routes to a single matching file.
- **Nothing gets copied into your project.** Scripts live inside the skill that owns them and are invoked through `${CLAUDE_PLUGIN_ROOT}`. If a README tells you to `cp` files out of a clone, the delivery mechanism is wrong.
- **Never fork someone else's skill into this namespace.** Third-party skills are installed from their own upstream, so they update from source and stay attributed.
- **The contract wins.** When a plan's prose disagrees with the sliced contract, the contract is right and the disagreement gets reported.
- **Typecheck is the verification command.** Full builds and lint runs belong to pre-commit hooks and CI.

## Third-party skills

This repo contains only original work. Install other people's skills from their own repositories:

```bash
npx skills@latest add shadcn/ui -s shadcn -y
```

## Development

```bash
claude --plugin-dir ./plugins/core --plugin-dir ./plugins/react-ui --plugin-dir ./plugins/fsd
claude plugin validate ./plugins/core
/reload-plugins
```

## License

MIT.
