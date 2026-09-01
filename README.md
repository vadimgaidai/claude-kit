# claude-kit

Plugins for [Claude Code](https://claude.com/claude-code). They add slash commands that turn a described feature into finished code: one command plans it, one writes it, one reviews the result.

## What it does

Say you need comments on articles. You start with:

```
/feature-workflow:analyze add comments to articles
```

Claude asks you a handful of questions, one at a time, each with a recommended answer: what to call this, which endpoints it uses (a Swagger URL and a list like `GET /articles/{id}/comments`), is there a Figma frame, what the UI is, what the loading and empty and error states look like, who's allowed to delete a comment, and what counts as done. It doesn't ask things it can find out itself, so questions about your existing modules or installed components don't come up.

Then it writes two files:

- `.planning/comments/contract.md` — the request and response shapes for the endpoints you named, pulled out of your OpenAPI spec with `$ref`s resolved and required, optional and enum values marked.
- `.planning/comments/PLAN.md` — which modules to create and in what order, the files in each, the types, the queries and what they invalidate, the form schemas, the components and their states, the i18n keys, and the acceptance criteria.

Read that plan. It's a normal markdown file, so fix whatever is wrong before any code exists. Then:

```
/feature-workflow:implement
```

It works through the plan in order: constants, types from the contract, the HTTP calls, queries and mutations, validation schemas, components with every state the plan listed, exports, and routes last. It follows your project's conventions by reading `CLAUDE.md` and one existing module of the same kind. When it's done it runs your typecheck and tells you what it built, what it skipped and why, and anything you now need to install.

```
/feature-workflow:review
```

Reads the diff against the acceptance criteria and the contract, and reports what doesn't match. It only changes code if you ask it to.

All of this happens in your session, so you can interrupt, correct and redirect at any point. Two things run separately, because both involve reading a lot you don't want left in your context:

- `@feature-workflow:bug-fixer` — give it a bug, it reproduces it, finds the cause and fixes it with the smallest change.
- `@react-shadcn-ui:theme-sync` — give it a Figma file, it maps the variables onto your shadcn tokens and writes both the light and dark palettes, then tells you what had no match.

## Install

```bash
/plugin marketplace add vadimgaidai/claude-kit
/plugin install feature-workflow@vadimgaidai       # the workflow above
/plugin install react-shadcn-ui@vadimgaidai        # React, shadcn/ui, Tailwind, TanStack Query, forms
/plugin install feature-sliced-design@vadimgaidai  # FSD structure
```

`feature-workflow` is the only one you need. It makes no assumptions about your file layout, so it works in a project you didn't set up: the plan records which existing module the new code should resemble, and the implementer uses that as its reference. The other two add real conventions for React UI work and for Feature-Sliced Design.

Commands are prefixed with the plugin name, so `/feature-workflow:analyze` won't collide with an `analyze` skill you already have.

## What's in each plugin

**feature-workflow**

| Command | What it does |
|---|---|
| `/feature-workflow:analyze` | Questions, then `PLAN.md` and a trimmed API contract |
| `/feature-workflow:implement` | Builds everything in the plan |
| `/feature-workflow:review` | Checks the diff against the plan and the contract; takes `correctness` / `contract` / `consistency` / `perf` to narrow the report |
| `/feature-workflow:api-contract` | Trims a Swagger or OpenAPI spec to the endpoints you name, on its own |
| `@feature-workflow:bug-fixer` | Reproduces and fixes one bug |
| a hook | Runs Prettier on every file written |

**react-shadcn-ui**

| Skill | What it covers |
|---|---|
| `react` | React 19 and the Compiler: where state belongs, what effects are for, when memoization still helps, refs and context, `lazy`, Suspense and error boundaries, Actions and `use` |
| `tanstack-query` | What the shared `QueryClient` already decided, what belongs in a query key, `enabled` / `select` / `useQueries` / `keepPreviousData`, and how a mutation touches the cache |
| `shadcn-ui` | Semantic tokens instead of raw colors, extending primitives through `ComponentProps`, spacing and icons that survive dark mode |
| `react-hook-form-zod` | Where schemas live, the `z.input === z.output` rule, the usual resolver errors |
| `@react-shadcn-ui:theme-sync` | Figma variables to shadcn tokens, light and dark |

**feature-sliced-design**

| Component | What it does |
|---|---|
| `structure` | Layers, import direction, module anatomy, and example code for each kind of module |
| `scaffold.sh` | Creates a module skeleton, checks kebab-case, won't touch an existing module |
| three hooks | Reject a file placed outside a layer, a filename that isn't kebab-case, and an import from the `@/shared/ui` barrel |

The skills in `react-shadcn-ui` and `feature-sliced-design` load themselves when they're relevant to what you're writing, so you don't need to invoke them by name.

Import direction is described by the `structure` skill but not enforced by a hook, so an entity importing from a feature gets caught in review rather than at write time.

## Keeping the context small

The three commands are built to run in **separate sessions**. The files between them are the handoff — that is the whole reason the plan and the contract are written to disk instead of being carried in the conversation.

| Practice | Why |
|---|---|
| Start `implement` in a fresh session, not the one that planned | The plan is the handoff. A session that just spent twenty questions deciding what to build carries all of that reasoning into the build, where only the plan matters. |
| Review in a fresh session too | `review` reads the diff. The session that wrote the code is its worst judge — it already believes the code matches the plan, because it believed that while writing it. |
| Point at the plan by path; don't paste it | `implement` opens `.planning/[name]/PLAN.md` itself and reads the parts it needs. Pasting it spends the tokens twice and pins the whole thing in context. |
| One `.planning/[name]/` folder per unit of work | `analyze` writes one plan covering every module of the request. Scattering a request across per-module folders leaves no single authoritative brief, and `implement` has nothing to build from. |
| Let a skill load itself | Skills are chosen from their description and loaded on demand. Pasting a convention into the prompt spends exactly the tokens that mechanism exists to save. |
| Keep `bug-fixer` and `theme-sync` as subagents | Both read far more than they report — a reproduction, a Figma file. The finding comes back to you; the reading stays with them. |
| One concern per session | A bug fix folded into a feature build produces a diff where nothing says which change answers which intent — and `review` can only judge it as one thing. |

## Requirements

The hooks shell out to a couple of things that are usually already there: `jq` for the three `feature-sliced-design` validators, and `node` for the Prettier hook. Without `jq` the validators exit quietly instead of blocking a bad write, so the checks look like they're running when they aren't.

## Setting it up for a repo

Put the marketplace in the repo's `.claude/settings.json` so everyone who clones it gets the same setup:

```json
{
  "extraKnownMarketplaces": {
    "vadimgaidai": { "source": { "source": "github", "repo": "vadimgaidai/claude-kit" } }
  },
  "enabledPlugins": {
    "feature-workflow@vadimgaidai": true,
    "react-shadcn-ui@vadimgaidai": true,
    "feature-sliced-design@vadimgaidai": true
  }
}
```

This registers the marketplace and records which plugins the project expects. It doesn't install them, so each person still runs `/plugin install` once.

[react-shadcn-ts-template](https://github.com/vadimgaidai/react-shadcn-ts-template) is a working example of a repo set up this way.

## Third-party skills

This repo contains only original work. Install other people's skills from their own repositories, so they stay attributed and keep updating from source:

```bash
npx skills@latest add shadcn/ui -s shadcn -y
```

## Development

Iterate against the working tree, without installing:

```bash
claude --plugin-dir ./plugins/react-shadcn-ui
/reload-plugins        # re-read the directories after an edit
```

**Bump the version or the change never ships.** `claude plugin update` compares `version` against the installed copy — unchanged, it answers "already at the latest version" and copies nothing, ignoring commits entirely. Bump it in both `plugins/<name>/.claude-plugin/plugin.json` and the marketplace entry; `claude plugin tag` refuses a release where the two disagree.

So a push alone changes nothing for installed copies: the marketplace clone updates, the plugin cache doesn't. `/reload-plugins` answering `0 skills` after you pushed a new skill means the cache never moved — check the version, not the code.

`claude plugin validate` reads manifests only, never `SKILL.md` — nothing catches a dead `references/*.md` link or bad frontmatter until the skill needs it. `claude plugin eval` (cases under `evals/`) is the real check; `claude plugin details <plugin>@<owner>` confirms what loaded and what it costs per session.

## License

MIT.
