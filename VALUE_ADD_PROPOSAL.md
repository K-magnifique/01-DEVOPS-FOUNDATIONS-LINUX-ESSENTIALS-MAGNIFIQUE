# Value-Add Proposal — Two Pitches

## Pitch 1: Pre-commit hook blocking committed secrets

**What**: a git hook that scans staged changes for likely secrets (env-style
`KEY=value` patterns, common credential/token shapes) and blocks the commit if
one is found, with an override for genuine false positives.

**Why**: this is the most direct fix for the exact incident just resolved — a
secret sat in `config/local.env`, got committed, and then had to be surgically
purged from history with `git filter-repo` after the fact. A pre-commit hook
would have stopped that commit from ever happening, which is strictly cheaper
than any history-rewrite after the fact (no force-push, no coordinating with
anyone who already pulled the bad commit, no window where the secret was
exposed at all).

**Feasibility**: low effort, no new infrastructure. Distributed via a tracked
`.githooks/` directory + `git config core.hooksPath .githooks`, so every fresh
clone gets it automatically without a manual setup step anyone can skip.

**ROI**: prevents a repeat of the single most severe finding in this audit, for
a few hours of setup and effectively zero ongoing cost.

## Pitch 2: systemd timer for service health checks

**What**: a `systemd` `.timer` unit that periodically curls the order-service's
`/health` endpoint and logs/restarts on failure, independent of `systemd`'s own
`Restart=on-failure` (which only catches the process dying, not it hanging while
still "running").

**Why**: the service is now managed by `systemd` (this audit's own work), but
nothing currently checks that it's actually *responding*, only that the process
exists. A process can hang without exiting.

**Feasibility**: low effort, builds directly on the `kente-order-service.service`
unit already in place — just a companion `.timer` + a small check script.

**ROI**: catches a category of failure (hung-but-alive) that plain process
supervision misses, directly extending infrastructure that already exists rather
than introducing something new.

## Recommendation

Both are cheap and directly address a real gap from this engagement. Pitch 1
addresses the higher-severity, already-proven risk (a real secret was actually
exposed in history); Pitch 2 hardens something already built. Proposing Pitch 1
as the one to build, since prevention of a recurrence of the worst finding in
this audit outweighs hardening a system that's already passing its checks —
happy to build Pitch 2 instead if the CTO weighs it differently.
