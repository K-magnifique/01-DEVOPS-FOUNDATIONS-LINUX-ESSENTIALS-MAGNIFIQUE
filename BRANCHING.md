# Branching Convention

## What went wrong here

The `DB_HOST` availability check was committed **directly to `main`** while
`feature/order-status-filter` was still in flight, both editing the same lines in
`src/index.js` and `README.md`. Neither branch was wrong on its own — the problem
was that a fix landed on `main` with no visibility into what the in-flight feature
branch was also touching, so the conflict wasn't discovered until merge time,
by which point resolving it required understanding two independent changes at
once instead of one.

## Rules going forward

1. **No direct commits to `main`** — including hotfixes. Everything goes through
   a branch, even if it's fast-tracked and merged within minutes. A hotfix branch
   still gets reviewed and still shows up as a PR, so anyone with a branch open
   against the same files finds out before merge time, not during it.
2. **Branch naming**: `feature/<short-description>` for feature work,
   `hotfix/<short-description>` for urgent production fixes. Both are branches,
   never direct pushes to `main`.
3. **Merge via PR, `--no-ff`**: every merge into `main` goes through a pull
   request and produces an explicit merge commit (no fast-forwards, no squash).
   This keeps a visible record of *when* a branch integrated, which is what let
   us diagnose this incident from the log in the first place.
4. **Rebase your own branch on `main` before opening a PR** if `main` has moved —
   catch conflicts locally, on your own branch, rather than at merge time.
5. **Delete branches after merge.** A merged branch has no reason to keep
   existing; stale branches are exactly what made the original handover
   ("tangled branch history") hard to reason about.
6. **Never commit secrets, ever, even temporarily.** Add sensitive filenames
   (`*.env`, `config/local.*`) to `.gitignore` *before* they can be created, not
   after. See the value-add proposal for a pre-commit hook that enforces this
   automatically rather than relying on discipline alone.
