# Documentation index

Everything that explains how this project is built and why. Start with the plan, then read the
lesson pages in order.

| Page | What it is for |
| --- | --- |
| [PROJECT_PLAN.md](PROJECT_PLAN.md) | The whole project: scenario, architecture, stack, tools and permissions, 14 lessons, evaluation plan. |
| [DATA_MODEL.md](DATA_MODEL.md) | The database as a diagram, why each table looks the way it does, and where its data comes from. |
| [lessons/01-data-model-and-import.md](lessons/01-data-model-and-import.md) | Lesson 1: progress checklist, decisions, what broke and measured results. |

## Conventions

- **One page per lesson** in `lessons/`, named `NN-short-topic.md`. Each has the same parts:
  status, what was built, decisions and why, what broke, and proof.
- **Facts only.** Numbers in these pages come from a real run. If something has not been run yet,
  the page says "expected".
- **The code is the source of truth.** If a page and the code disagree, fix the page.
