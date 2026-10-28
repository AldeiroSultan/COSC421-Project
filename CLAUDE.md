# CLAUDE.md

Project: COSC 421 submarine cable resilience study (R, igraph, sf). Team: Su Myat Thwe, John Kwon, Sultan Aldeiro.
We compare targeted failure (remove the most central countries) with corridor failure (remove every cable through an area) on the global submarine cable network.

Read `README.md` for the folder layout, `docs/team_plan.md` for who owns which script, and `docs/git_conventions.md` for the naming rules.

## When the user gives a branch number

The user will paste something like `MF-0003 corridor polygons` or `TI-0001 fix country names`. MF means Main Feature (new work) and TI means Task Improvement (change to something that exists). Do the following in order.

1. Run `git status`. If there are uncommitted changes that are not part of this task, stop and ask.
2. Run `git checkout staging` and `git pull origin staging`.
3. Make sure the number is free. Check `git branch -a`, `git log --oneline --all` and, if `gh` is installed, `gh pr list --state all`. If the number is already used, tell the user and stop.
4. If no short description was given, ask for one. Then create the branch: `git checkout -b <ID>-<short-description>`, for example `MF-0003-corridor-polygons`.
5. Do the work the user asked for. Only touch the files that task needs.
6. Commit with one line in this format: `<ID> | <Verb and short description>`, for example `MF-0003 | Add corridor polygons for the Red Sea`. Make a separate commit for each logical change.
7. Push with `git push -u origin <branch>`.
8. Open a pull request into `staging`, never `main`. Title: `<ID> | <Short description>`. If `gh` is installed, use `gh pr create --base staging`. If not, print the title and body so the user can paste them.

PR body format:

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

## Git rules

- Never commit or push straight to `main` or `staging`.
- Never force push and never merge your own pull request.
- Never commit anything in `data/raw/`. Raw data is rebuilt by `R/01_download_data.R`.
- Do not rewrite or reorganize files that were not part of the task.

## Code rules

- Scripts live in `R/` and run in numbered order. A script reads the output of earlier scripts and never needs a file that a later script creates.
- Start every script with `source("R/00_setup.R")`. It loads the packages and defines `dir_raw`, `dir_processed`, `dir_results` and `dir_figures`.
- Use `here()` or those folder variables for paths. No absolute paths.
- Keep multi-edges in the graph (two cables between the same countries are two edges). Keep the `cable_id` on each edge, because corridor failure removes edges by cable.
- Tables go in `results/` as csv. Plots go in `figures/` as png.
- Keep the existing structure of a script. When asked for a change, change only what was asked.

## Writing style

Use plain wording in comments, commit messages and PR text. Do not use em dashes. Keep it short.