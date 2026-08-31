# claude-kit

Plugins for [Claude Code](https://claude.com/claude-code). They add slash commands that turn a described feature into finished code: one command plans it, one writes it, one reviews the result.

## What it does

Say you need comments on articles. You start with:

```
/core:analyze add comments to articles
```

Claude asks you a handful of questions, one at a time, each with a recommended answer: what to call this, which endpoints it uses (a Swagger URL and a list like `GET /articles/{id}/comments`), is there a Figma frame, what the UI is, what the loading and empty and error states look like, who's allowed to delete a comment, and what counts as done. It doesn't ask things it can find out itself, so questions about your existing modules or installed components don't come up.

Then it writes two files:

- `.planning/comments/contract.md` — the request and response shapes for the endpoints you named, pulled out of your OpenAPI spec with `$ref`s resolved and required, optional and enum values marked.
- `.planning/comments/PLAN.md` — which modules to create and in what order, the files in each, the types, the queries and what they invalidate, the form schemas, the components and their states, the i18n keys, and the acceptance criteria.

Read that plan. It's a normal markdown file, so fix whatever is wrong before any code exists. Then:

```
/core:implement
```

It works through the plan in order: constants, types from the contract, the HTTP calls, queries and mutations, validation schemas, components with every state the plan listed, exports, and routes last. It follows your project's conventions by reading `CLAUDE.md` and one existing module of the same kind. When it's done it runs your typecheck and tells you what it built, what it skipped and why, and anything you now need to install.

```
/core:review
```

Reads the diff against the acceptance criteria and the contract, and reports what doesn't match. It only changes code if you ask it to.

All of this happens in your session, so you can interrupt, correct and redirect at any point. Two things run separately, because both involve reading a lot you don't want left in your context:

- `@core:bug-fixer` — give it a bug, it reproduces it, finds the cause and fixes it with the smallest change.
- `@react-ui:theme-sync` — give it a Figma file, it maps the variables onto your shadcn tokens and writes both the light and dark palettes, then tells you what had no match.

## Install

```bash
/plugin marketplace add vadimgaidai/claude-kit
/plugin install core@vadimgaidai        # the workflow above
/plugin install react-ui@vadimgaidai    # shadcn/ui, Tailwind, forms
/plugin install fsd@vadimgaidai         # Feature-Sliced Design
```

`core` is the only one you need. It makes no assumptions about your file layout, so it works in a project you didn't set up: the plan records which existing module the new code should resemble, and the implementer uses that as its reference. The other two add real conventions for React UI work and for Feature-Sliced Design.

Commands are prefixed with the plugin name, so `/core:analyze` won't collide with an `analyze` skill you already have.

## What's in each plugin

**core**

| Command | What it does |
|---|---|
| `/core:analyze` | Questions, then `PLAN.md` and a trimmed API contract |
| `/core:implement` | Builds everything in the plan |
| `/core:review` | Checks the diff against the plan and the contract |
| `/core:api-contract` | Trims a Swagger or OpenAPI spec to the endpoints you name, on its own |
| `@core:bug-fixer` | Reproduces and fixes one bug |
| a hook | Runs Prettier on every file written |

**react-ui**

| Skill | What it covers |
|---|---|
| `react` | React 19 and the Compiler: what effects are for, when memoization still helps, `lazy` and Suspense |
| `shadcn-ui` | Semantic tokens instead of raw colors, extending primitives through `ComponentProps`, spacing and icons that survive dark mode |
| `react-hook-form-zod` | Where schemas live, the `z.input === z.output` rule, the usual resolver errors |
| `@react-ui:theme-sync` | Figma variables to shadcn tokens, light and dark |

**fsd**

| Component | What it does |
|---|---|
| `feature-sliced-design` | Layers, import direction, module anatomy, and example code for each kind of module |
| `scaffold.sh` | Creates a module skeleton, checks kebab-case, won't touch an existing module |
| three hooks | Reject a file placed outside a layer, a filename that isn't kebab-case, and an import from the `@/shared/ui` barrel |

The skills in `react-ui` and `fsd` load themselves when they're relevant to what you're writing, so you don't need to invoke them by name.

Import direction is described by the `fsd` skill but not enforced by a hook, so an entity importing from a feature gets caught in review rather than at write time.

## Setting it up for a repo

Put the marketplace in the repo's `.claude/settings.json` so everyone who clones it gets the same setup:

```json
{
  "extraKnownMarketplaces": {
    "vadimgaidai": { "source": { "source": "github", "repo": "vadimgaidai/claude-kit" } }
  },
  "enabledPlugins": ["core@vadimgaidai", "react-ui@vadimgaidai", "fsd@vadimgaidai"]
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

```bash
claude --plugin-dir ./plugins/core --plugin-dir ./plugins/react-ui --plugin-dir ./plugins/fsd
claude plugin validate ./plugins/core
/reload-plugins
```

## License

MIT.
