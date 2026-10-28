# Team plan: two weeks

Dates assume we start Tue Oct 27 and finish Mon Nov 9. The milestone report is due Nov 6, so week 1 output has to be usable by then.

Roles: **John** = data and corridors, **Su** = network metrics and protection, **Sultan** = failure simulations and Git setup.

## Week 1 (Oct 27 to Nov 2): get the baseline working

| Task | File | Owner | Done when |
|---|---|---|---|
| Create GitHub repo, add teammates, protect `main` | repo settings | Sultan | Everyone can push a branch |
| Package setup | `R/00_setup.R` | Sultan | Runs on all three laptops |
| Download raw data | `R/01_download_data.R` | John | `data/raw/` fills up |
| Clean data, decide how to treat territories | `R/02_clean_data.R`, `docs/data_notes.md` | John | Two clean csv files in `data/processed/` |
| Build country network | `R/03_build_network.R` | Su | `network.rds` saved, node and edge counts printed |
| Baseline metrics and random network comparison | `R/04_baseline_metrics.R` | Su | Answers research question 1 |
| Targeted failure | `R/05_targeted_failure.R` | Sultan | Giant component curve saved |

## Week 2 (Nov 3 to Nov 9): corridors, validation, report

| Task | File | Owner |
|---|---|---|
| Milestone report (Nov 6) | `reports/milestone.Rmd` | All |
| Draw corridor polygons (Red Sea, near Taiwan, near Tonga) | `R/06_corridors.R` | John |
| Corridor failure simulation | `R/07_corridor_failure.R` | Sultan |
| Articulation points and cut off countries across scenarios | `R/08_articulation_points.R` | Su |
| Validate Red Sea results against 2024 cuts (Cloudflare Radar, IODA) | `R/09_validation_red_sea.R` | John |
| Test new cable connections | `R/10_protection.R` | Su |
| Figures for the report | `figures/` | John, Sultan |
| Final report and video | `reports/` | All |

Week 2 files are not created yet. Add them as each person starts.

Each row above is split into numbered tasks in `docs/task_board.md`. To start one, type its ID (for example `MF-0005`) into Claude Code in this repo.

## Rules

- One branch per task, named by its ID from `docs/task_board.md`. Open a pull request into `staging` (see `docs/git_conventions.md`).
- Pull before you start: `git pull origin staging`.
- Do not commit `data/raw/`. Re-run `01_download_data.R` instead.
- If a script needs a column that another script does not produce yet, message the owner of that script before changing it.
- Update the Done column or leave a note in your pull request so we can see where things stand.
