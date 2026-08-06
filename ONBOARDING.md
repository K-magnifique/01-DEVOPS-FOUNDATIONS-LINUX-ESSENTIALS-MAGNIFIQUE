# Onboarding: How We Work

Welcome to Kente Retail engineering. This page explains the mental model behind how
we build and ship, using what actually happened right before you joined as the
running example — it's more useful than a textbook definition.

## The DevOps lifecycle, in plain terms

Software here moves through: **Plan → Code → Build → Test → Release → Deploy →
Operate → Monitor**, and back to Plan based on what Monitor turns up. It's a loop,
not a one-way pipeline — the point is that what you learn in production feeds the
next thing you plan.

Concretely, in the incident you're inheriting context on: **Code** (the
status-filter feature and the DB-availability hotfix) happened on separate
branches without enough **Build/Test** overlap to catch that they touched the same
lines. **Release** was blocked as a result. And **Monitor** was the missing piece
that let a security-group gap sit unnoticed until someone actually tried to reach
the app externally — nothing was watching for that until this audit.

## CALMS — the pillars behind the practices

- **Culture**: shared ownership of the whole lifecycle, not "dev writes it, ops
  runs it." The previous engineer leaving with zero handover notes was a culture
  gap, not a tooling one — no amount of Git hygiene fixes that on its own.
- **Automation**: the order-service now runs as a `systemd` unit (auto-restart,
  survives disconnection) instead of a manually-run process someone has to
  remember to restart.
- **Lean**: small, frequent changes over big-batch ones — see
  `BRANCHING_STRATEGY.md` for why trunk-based fits this team specifically.
- **Measurement**: we track DORA metrics (below) rather than just "did it ship,"
  because "it shipped" doesn't tell you whether it shipped safely or fast.
- **Sharing**: this doc, `BRANCHING.md`, and `ASSUMPTIONS_LOG.md` exist so the
  next handover isn't a repeat of this one.

  ## The value-add we built: a pre-commit secret hook

Beyond the audit itself, we built and merged a `git` pre-commit hook
(`.githooks/pre-commit`, wired up automatically via `npm install`'s
`postinstall` script) that scans staged changes for secret-shaped content
(`PASSWORD=`, `API_KEY=`, AWS-style keys, private-key blocks) and known
secret-bearing filenames (`*.env`, `*.pem`, `*.key`), blocking the commit
before it happens.

This directly targets the root cause of the worst finding in this audit: a
secret sat in `config/local.env` long enough to be committed, then "cleaned
up" in a later commit without ever being purged from history — requiring a
full `git filter-repo` rewrite and a forced push to actually fix. A hook that
blocks the *first* commit is strictly cheaper than any after-the-fact history
rewrite: no force-push, no coordinating with anyone who already pulled the bad
commit, no window where the secret was exposed at all. Tested directly before
merging — a staged `API_KEY=...` value was blocked with a clear error message,
and legitimate commits pass through unaffected.


## This incident, in DORA terms

**MTTR (Mean Time to Restore)** is the clearest fit: the release was blocked from
the moment the conflict/secret/server gaps were discovered until all three were
actually fixed and verified. That entire window *is* the MTTR for this incident.
It was long largely because the underlying problems (a stale branch, a buried
secret, an unaudited server) had been accumulating silently for a while before
anyone looked — the fix itself, once started, took hours, but the detection lag
before that is what really drove MTTR up.

**Deployment frequency** is the related lever: if the feature and hotfix branches
had merged within a day of being opened (trunk-based, per the strategy doc)
instead of diverging for longer, this conflict would have surfaced immediately,
in a small diff, instead of accumulating into a blocked release. Shipping more
often, in smaller pieces, is what keeps MTTR low the *next* time — it's not a
vanity metric, it's the mechanism.
