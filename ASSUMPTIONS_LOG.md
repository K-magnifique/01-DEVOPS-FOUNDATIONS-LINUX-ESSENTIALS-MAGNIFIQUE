# Assumptions Log — "The Handover"

## 1. Scoping the audit / what "handover-ready" means here

The brief deliberately leaves "tell me what's actually wrong" and "handover-ready"
undefined. I scoped this as:

- **Repo**: a clean, single-line `main` with all feature work merged, no unresolved
  conflicts, and no secret recoverable from history by any means (not just absent
  from the latest commit) — verified by searching every object in the store, not
  just `git log`.
- **Server**: fully compliant with every item in `server-baseline-policy.md`
  (directory permissions/ownership, users/groups, hostname, network reachability),
  with the app actually running as a managed service rather than a foreground
  process, since a handover should survive the next person's SSH session ending.
- **Documentation**: enough for a new hire to understand *why* things are the way
  they are (branching convention, onboarding doc), not just a snapshot of *what*
  the current state is.
- Out of scope, per the brief §5: TLS/certificates, log rotation, backup policy.
  Noted below where relevant, not fixed.

## 2. The seed data was broken — and how that was handled

The provided zip's Git history did **not** contain the tangled-branch/secret
scenario the brief describes. `git fsck --unreachable` on the as-delivered
`base-repo/` turned up ~20 dangling commits — but reconstructing the graph showed
they were ~8 disconnected, near-identical retry attempts (e.g. multiple
`"Add local config (contains a secret, buried in history)"` commits, each a few
seconds apart, all branching off the same tip, none merged or reachable from any
branch). `main` itself was a plain, already-clean 3-commit history. This reads as
a seed-generator bug — it appears to have retried building the scenario and never
committed a final version to a real branch before the zip was packaged.

The instructor was not reachable to supply a corrected seed. Rather than wait or
guess which of the ~8 disconnected attempts was "the" intended one, I
**reconstructed an equivalent scenario myself**, on the existing scaffold:

- A `feature/order-status-filter` branch adding a real feature (status-filter
  query param on `GET /api/orders`) and a genuinely buried secret
  (`config/local.env`, added then "cleaned up" in a later commit without being
  purged from history).
- A hotfix commit directly on `main` (`DB_HOST` availability check) touching the
  same lines in `src/index.js` and `README.md`, guaranteeing a real merge conflict.

This substitution is the single biggest assumption in this submission — the merge
conflict, the secret, and the fix are all real and were resolved for real, but the
starting mess was self-authored rather than instructor-seeded. Everything from
that point on (conflict resolution, `git filter-repo` purge, verification) was done
against this reconstructed state using the same tools/process the original
exercise expects.

The lab also had no separate per-learner Git-hosting or Linux sandbox actually
provisioned for me (the brief describes both as pre-supplied). I created my own
GitHub repository and provisioned a fresh AWS EC2 instance from the course-provided
sandbox account to stand in for both.

## 3. Clarifying questions I'd ask the CTO in a real engagement

- Is this repo/server the actual intended handover artifact, or did something get
  lost in how it was packaged/provisioned for me? (In this lab, that answer turned
  out to be "packaging was broken" — but I'd never assume that on a real client
  engagement without asking first.)
- Is a written audit + a live demo sufficient for "handover-ready," or do you want
  a runbook the next hire can execute unsupervised?
- Should the sandbox EC2 instance stay running after this engagement for future
  reference/grading, or is a one-time demonstration enough before it's torn down
  (cost/lifecycle question)?
- Is Node 18 vs 20 a meaningful constraint for you, or was `>=18` in `package.json`
  just a floor with no real upper-bound concern?
- Do you want the `DB_HOST` check wired to a real database, or is stubbing it
  (503 when unset) acceptable for now, given there's no real datastore in this
  sandbox?

## 4. Other gaps found and how they were handled

- **Found & fixed**: during manual conflict resolution I introduced a syntax error
  (missing closing brace + dropped 404 handler) — caught with `node --check` before
  committing further.
- **Found & fixed**: a duplicate `server.listen()` call also introduced during
  conflict resolution, which only surfaced at runtime (`ERR_SERVER_ALREADY_LISTEN`
  in `systemd`'s journal) since `node --check` only validates syntax, not runtime
  behavior. Fixed at the source (local repo → push → `git pull` on the server),
  not by hand-editing the deployed copy, to keep git as the source of truth.
- **Found & fixed**: applying the policy's `750` permission literally, recursively,
  to every file (including plain text files) sets the executable bit on files git
  tracks as `100644`, which git reports as a "local modification" and blocks
  `git pull`. Resolved by setting `core.fileMode false` on the deployed clone,
  documented here since it's a non-obvious interaction between a security policy
  and git's tracking model, not a real content change.
- **Found & fixed**: the EC2 security group had no inbound rule for port 8080 at
  all (only SSH/22) — this was the seeded-equivalent "network issue blocking the
  release." Fixed by adding a rule for TCP 8080; verified with `curl` from
  *outside* the server (not just `localhost`) after the fix.
- **Deliberate, not fixed**: opened the 8080 rule to `0.0.0.0/0` rather than a
  single IP, because the policy requires reachability "from the class network,"
  not just from my own machine, and this is a temporary training sandbox with no
  real data in it (the secret purged earlier was a fabricated placeholder value,
  not a real credential — no rotation was necessary). This would be the wrong call
  on a real production security group.
- **Deliberate, not fixed**: `/api/orders` returns `503` unless `DB_HOST` is set —
  left as-is rather than stood up against a fake database, since there's no real
  datastore in this sandbox and faking one would misrepresent the audit.
- **Noted, not fixed** (explicitly out of scope per brief §5): no TLS, no log
  rotation, no backup policy configured on the EC2 instance. Flagging these as
  real gaps for a production deployment, not addressed here.
