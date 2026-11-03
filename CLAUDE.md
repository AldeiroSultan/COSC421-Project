# CLAUDE.md

Project: COSC 421 submarine cable resilience study (R, igraph, sf). Team: Su Myat Thwe, John Kwon, Sultan Aldeiro.
We compare targeted failure (remove the most central countries) with corridor failure (remove every cable through an area) on the global submarine cable network.

Read `README.md` for the folder layout, `docs/task_board.md` for every task with its ID and spec, `docs/team_plan.md` for the schedule, and `docs/git_conventions.md` for the naming rules.

## When the user gives a branch number

The user will write something like `MF-0005`, `do MF-0005`, `MF-0010 corridor polygons` or `TI-0001 fix country names`. MF means Main Feature (new work), TI means Task Improvement (change to something that exists) and DC means Documentation (changes to docs, README or CLAUDE.md only, no code).

If the ID is listed in `docs/task_board.md`, that section is the task. Use the branch name from the overview table, follow the "What to do" steps, write the exact columns in the "Shared file formats" table, and check the "Done when" line before committing. Look at the "Needs" line: if a task it needs is not merged into `staging` yet, tell the user, and offer to write the code against a few rows of made up input that is not committed. IDs on the board are reserved, so do not give a new TI or MF task one of those numbers.

Claude edits files. The person runs Git. Some teammates do not know Git or VS Code, so use plain words and short steps, and put every command in a code block they can copy. Commands are typed in the VS Code terminal (menu Terminal, then New Terminal). Never run `git add`, `commit`, `push`, `pull`, `checkout`, `merge`, `rebase` or `reset`, and never run `gh`. Read only commands such as `git status`, `git branch --show-current`, `git log` and `git diff` are fine.

Do the following in order.

1. Check the branch. Run `git status`. If there are uncommitted changes that are not part of this task, stop and ask. Then run `git branch --show-current`. If it already prints the ID, say so and go on. Otherwise ask "Have you switched to a new branch for <ID>?" and show:

````
```
git checkout staging
git pull origin staging
git checkout -b <ID>
```
````

   Then say: "Run these one at a time. If you still have changes from your last task, push that one first with the commit steps I gave you, then run these. Tell me when it is done." Wait for the answer before going on.
2. Make sure the number is free. If the ID is not on the task board (a new TI or DC task), check `git branch -a` and `git log --oneline --all`. If the number is already used, tell the user and stop. If no short description was given, ask what the task should do.
3. Do the work. Only touch the files that task needs.
4. Reply in the format below. Start with one or two sentences on what you did.

Commit block:

````
```
git branch --show-current
git add -A
git commit -m "<ID> | <Verb and short description>" -m "<Two or three plain sentences on what was added and why.>"
git push -u origin <ID>
```
````

Under it say: "The first line should print `<ID>`. If it prints something else, stop and tell me." Inside the commit message do not use backticks, double quotes, dollar signs or exclamation marks, because the terminal reads them as commands.

PR title, in its own code block: `<ID> | <Verb and short description>`

PR description, in its own code block:

````
```
## What changed
This is <ID> from docs/task_board.md. <One or two sentences on why it is needed.>

* <file>: <what it does>
* <file>: <what it does>
* <What is not in this PR, or what it unlocks>

## Research question
Covers <research question or part of the project>. It unlocks <IDs that need this one>.

## How to test by hand

1. <step>
2. <step>
3. <what the result should look like>

## Notes
<Choices you made, anything left for a later PR, anything odd. Write None if there is nothing.>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```
````

Write the description from what you actually did, not from the plan. For a DC task, replace "Research question" with "Docs only, no code changes" and make the test step "Open the files and check they read correctly". For a TI task, say what was wrong and what is better now.

Then tell the person how to open the PR, in plain words: after the push, GitHub shows a yellow "Compare & pull request" banner, so click it, set base to `staging` (not `main`), paste the title and the description, click Create pull request, and ask one teammate to look it over.

Only add a "To tell the others" note if the change affects someone else's script, such as a new column or a changed file name. Name the person and say what they need to know.

End with: "Run the test steps and send me the result or any error. Your next one is <next ID> <title>." The next one is the next task on the board with the same owner that is not merged yet.

## Git rules

- Never commit or push straight to `main` or `staging`.
- Branch names are the ID only, for example `MF-0007`.
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