# Submarine Cable Resilience (COSC 421 Project)

Team: Su Myat Thwe, John Kwon, Sultan Aldeiro

We measure how different kinds of real world events affect countries' access to the global internet by comparing:

1. Targeted failure: remove the most central countries one at a time (recalculating betweenness after each removal).
2. Corridor failure: remove every cable that passes through one area (Red Sea, near Taiwan, near Tonga).

We also look for countries that lose access in more than one scenario, validate the Red Sea scenario against the 2024 cuts, and test which new cable connections keep the most countries connected.

## Folder layout

```
C421_Project/
  README.md
  .gitignore
  C421_Project.Rproj
  R/                 analysis scripts, run in numbered order
  data/raw/          downloaded files (not committed)
  data/processed/    cleaned tables and saved graph objects
  results/           output tables (csv)
  figures/           plots for the report
  docs/              team plan and data notes
  reports/           milestone and final report (added in week 2)
```

## How to run

1. Open `C421_Project.Rproj` in RStudio.
2. Run `R/00_setup.R` once to install and load packages.
3. Run the scripts in order: `01_download_data.R`, `02_clean_data.R`, `03_build_network.R`, `04_baseline_metrics.R`, `05_targeted_failure.R`.

Each script reads the output of the one before it, so a script should never need a file that a later script creates.

## Git workflow

- `main` always holds working code. Do not commit straight to it.
- Every task has an ID in `docs/task_board.md`. Make a branch off `staging` named by that ID and open a pull request into `staging`. Full rules are in `docs/git_conventions.md`.
- Have one teammate look the pull request over before merging.
- Pull before you start working: `git pull origin staging`.
- Raw data is not committed. Anyone can rebuild it by running `01_download_data.R`.

## Who owns what

See `docs/task_board.md` for every task, its owner and week, and `docs/team_plan.md` for the two week schedule.
