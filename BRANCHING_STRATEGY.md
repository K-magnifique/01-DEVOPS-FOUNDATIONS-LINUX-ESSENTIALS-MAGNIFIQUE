# Branching Strategy Recommendation: Trunk-Based

**Recommendation: trunk-based development, not Git flow.**

## Why, based on what actually happened here

The incident wasn't caused by picking the wrong tool — it was caused by two
changes (a `DB_HOST` hotfix and a status-filter feature) living on separate
branches for long enough that neither author knew about the other's edits to the
same lines until merge time. A secret also sat quietly in one of those branches
long enough to get "cleaned up" in a follow-up commit instead of never being
committed at all — the branch existed long enough for that mistake to happen and
go unnoticed.

Git flow would make this *worse* for a team this size: it adds `develop`,
`release/*`, and `hotfix/*` as permanent, long-lived branches on top of feature
branches, which means more places for parallel, unreviewed-until-merge work to
diverge, and more merge events where a conflict like this one can surface late
instead of early. Git flow earns its overhead when you're maintaining multiple
released versions in production at once (e.g. supporting v1.x and v2.x
simultaneously) — Kente Retail is a single continuously-deployed service with one
production version. There's no release train here to justify it.

## What trunk-based looks like for this team

- One long-lived branch: `main`. Everything else is short-lived (hours, not
  weeks) and named `feature/*` or `hotfix/*` per `BRANCHING.md`.
- Branches merge back via PR within a day or two of being opened, not once a
  feature is "fully done" — small, frequent merges instead of big-bang ones.
- Anything not ready to ship yet goes behind a feature flag rather than living
  on an unmerged branch — the status-filter work would have merged same-day
  even if incomplete, instead of sitting apart from the hotfix.
- Hotfixes still go through a branch + PR (per `BRANCHING.md`), but because
  `main` is the only long-lived branch, a hotfix and any in-flight feature work
  are both visibly close to `main` at all times — conflicts get caught by CI on
  the PR, not discovered days later at merge time.

## DORA connection

This directly improves the metrics that matter for a startup shipping
continuously: smaller, more frequent merges raise **deployment frequency** and
lower **change failure rate** (less can go wrong in a small diff than a
multi-day-divergent one), and catching conflicts/secrets within a day of them
being introduced — instead of at an eventual merge — sharply reduces **MTTR**
for exactly this kind of incident.
