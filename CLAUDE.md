# AI Support Engineer

A Rails 8 AI support agent, built lesson by lesson as the course "Production AI with Rails".
Full plan: `docs/PROJECT_PLAN.md` (read it for scope, lessons, data and tools). This file only
holds the working conventions.

## Working mode

- **Learning project.** Mohammad writes the app code and the tests. Do not write those files
  for him: describe what is needed and why, show at most a 2 to 5 line reference snippet,
  then review what he wrote. One small piece at a time (one class, one method).
- Setup and docs files (README, `docs/`, `.gitignore`, `example_data/`) can be written directly.
- Follow the global git rules: he runs git himself, so suggest commit messages (lowercase,
  single line) rather than committing; work on branches; remind at checkpoints.
- GitHub is the source of truth. A GitHub Action mirrors every push to GitLab, so merge and push
  on GitHub only (see `.github/workflows/mirror.yml`).
- **Gem-gap log.** When we hand-write something generic that a gem could do, or a search shows a gem
  already covers it, add an entry with the date checked to the "Gem-gap log" in `~/.claude/IDEAS.md`.
  Search RubyGems and GitHub first, log "already covered" results too, and only build a gem after a
  second real use.

## Design principle: the inside should be as beautiful as the outside

The internals matter as much as the behavior, like the inside of well-made hardware. Anyone
opening the repo should understand it in minutes. In practice:

- **One job per file, and the name says it.** A class named for what it does (`GetOrder`,
  `PolicySearch`), not a vague bucket (`Helper`, `Manager`, `Utils`).
- **The directory tree tells the story.** Group by role, not by type of file. A stranger
  should guess where a thing lives. When in doubt, add a folder with a one-line README
  rather than a long mixed folder.
- **Small and readable over clever.** Short methods, plain Ruby, no abstraction until the
  second real use. Tools are plain Ruby classes; the agent and MCP only wrap them.
- **Consistent naming and shape.** Every tool looks like every other tool. Same layout,
  same method names, same error style.
- **No dead code, no leftovers.** Delete unused files, scaffolding and commented-out code
  as it appears. Keep generated Rails noise out unless it is used.
- **Comments explain why, not what.** Code that needs a comment on what it does should be
  renamed or split instead.
- **Docs stay current.** Update the README and `docs/` as structure changes, and keep each
  directory's purpose obvious.
- **Tidy before you commit.** Run `bin/rubocop` and keep it clean.

### Intended layout (proposal, adjust as lessons land)

```
app/
  models/        data (Customer, Order, ...), thin
  tools/         plain Ruby tools the agent and MCP both wrap (read vs write kept visibly apart)
  agents/        the agent loop, router and prompts
  rag/           chunking, embeddings, retrieval
  controllers/, views/   chat and approval screens (Hotwire)
lib/tasks/       data import and seed tasks
data/            local dataset files (git-ignored)
example_data/    header-only copies of the dataset files (tracked)
docs/            plan, concepts, lesson write-ups
```

## Data

- Datasets live in `data/` (git-ignored): `data/olist/` (original Kaggle file names) and
  `data/bitext/customer_support.csv`. Never commit them or a database built from them.
- Olist is CC BY-NC-SA 4.0, Bitext is CDLA-Sharing-1.0. Keep the attribution in the README.
- Olist ids are 32-char hex strings: use integer primary keys plus an `olist_*_id` column.
- The category translation CSV has a BOM: read it with `encoding: "bom|utf-8"`.
- Fixed random seed (`Faker::Config.random = Random.new(42)`) so everyone gets the same data.

## Writing style

No em dashes, no Claude/Anthropic attribution anywhere (docs, comments, files, commits).
