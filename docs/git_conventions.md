# Git conventions

How we name branches, commits and pull requests.

## Branches

- `main` holds working code only. Nobody commits straight to it.
- `staging` is where finished work is combined and checked. Work branches come off `staging` and go back into it with a pull request.
- When `staging` runs cleanly from top to bottom, it gets merged into `main` with its own pull request (for example before the milestone and before the final submission).

## Naming

Every piece of work gets a prefix and a four digit number.

| Prefix | Stands for | Use it for |
|---|---|---|
| MF | Main Feature | Something new, like a new script or analysis step |
| TI | Task Improvement | A change to something that already exists, like a fix, a cleanup or a better plot |
| DC | Documentation | Changes to docs, README or CLAUDE.md only, with no code changes |

MF, TI and DC count up separately (MF-0001, MF-0002 and TI-0001, TI-0002 and DC-0001, DC-0002). Check the open and merged pull requests for the next free number before you start, so two people do not pick the same one.

## Branch names

`<prefix>-<number>`

Examples:

- `MF-0002`
- `TI-0001`
- `DC-0001`

## Starting a task

Run these in the VS Code terminal (menu Terminal, then New Terminal), one at a time:

```
git checkout staging
git pull origin staging
git checkout -b MF-0007
```

If you still have changes from your last task, push that one first.

## Commit messages

Two parts. The first is the ID, a bar and a short title that starts with a verb. The second is two or three plain sentences on what was added and why.

```
git branch --show-current
git add -A
git commit -m "MF-0007 | Add targeted failure simulation" -m "Filled in the removal loop in 05_targeted_failure.R. Betweenness is recalculated after every removal, and one row per step is saved to results/targeted_failure.csv."
git push -u origin MF-0007
```

Do not put backticks, double quotes, dollar signs or exclamation marks inside the message. The terminal reads them as commands.

## Pull requests

Title uses the same format as the commit message:

```
MF-0001 | Building a skeleton
```

Body:

```
## What changed
This is MF-0007 from docs/task_board.md. <why it is needed>

* <file>: <what it does>

## Research question
Covers <research question>. It unlocks <IDs>.

## How to test by hand

1. <step>
2. <step>

## Notes
<choices, things left for later, or None>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Before merging:

- One teammate reads it and approves it.
- Nothing from `data/raw/` is included. Raw data is rebuilt with `R/01_download_data.R`.
- Pull the latest `staging` first: `git pull origin staging`.

## Using Claude

Type a task ID, for example `do MF-0007`, into Claude Code. It checks your branch, does the work listed for that ID in `docs/task_board.md`, and gives you the commit block and the PR text to paste. It does not run Git for you.
