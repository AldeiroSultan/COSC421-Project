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

MF and TI count up separately (MF-0001, MF-0002 and TI-0001, TI-0002). Check the open and merged pull requests for the next free number before you start, so two people do not pick the same one.

## Branch names

`<prefix>-<number>`

Examples:

- `MF-0002`
- `TI-0001`

## Commit messages

One line, starts with the number, then a short description that starts with a verb.

```
MF-0002 | Add corridor polygons for the Red Sea
TI-0001 | Fix country name split for three part names
```

## Pull requests

Title uses the same format as the commit message:

```
MF-0001 | Building a skeleton
```

Body:

```
## What changed
- 

## Why
- 

## How to check
- 

## Notes
- 
```

Before merging:

- One teammate reads it and approves it.
- Nothing from `data/raw/` is included. Raw data is rebuilt with `R/01_download_data.R`.
- Pull the latest `staging` first: `git pull origin staging`.