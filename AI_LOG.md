# AI Log

AI (Claude, via Claude Code) was used throughout this engagement for diagnosis,
command guidance, and drafting the written deliverables. Every command that
touched the live repo, the EC2 server, or the AWS console was reviewed and
executed by hand, not run autonomously by the AI — that was a deliberate,
repeated preference (see "Corrected" below), not an incidental detail.

## Accepted as-is

- **Diagnosis that the provided repo seed was broken**: AI ran `git fsck
  --unreachable` and reconstructed the dangling-commit graph, concluding the
  "tangled history + secret" scenario didn't exist on any real branch — just
  ~8 disconnected retry attempts from what looks like a seed-generator bug.
  Verified independently by inspecting the commit diffs myself before accepting
  this — they were genuinely byte-identical across attempts, confirming it
  wasn't one coherent scenario to reverse-engineer.
- **Reconstructed practice scenario design**: a feature branch + a direct hotfix
  on `main`, both editing the same lines, to guarantee a real conflict; a secret
  added then "cleaned up" without being purged, to make history-purging genuine
  practice rather than theoretical.
- **AWS network-fault diagnosis sequence**: checking app binding (`ss -tlnp`),
  OS firewall (`ufw status`), then the security group, in that order — narrowed
  the missing-8080-rule problem down correctly on the first pass.
- **`git filter-repo` as the purge tool**, and the recommendation to verify via
  `git log --all` plus a full object-store grep rather than trusting `git log`
  on `main` alone.
- **Trunk-based-over-Git-flow recommendation** and its DORA framing — reviewed
  the reasoning (not just the conclusion) before agreeing it fit this team.
- **Value-add pick**: AI recommended the pre-commit secret hook over the
  systemd health-check timer as the higher-severity, already-proven risk;
  accepted that framing.
- **Opening the security group to `0.0.0.0/0`** for port 8080: accepted AI's
  reasoning (policy requires reachability "from the class network," this is a
  disposable training sandbox with no real secrets left in it) rather than
  restricting to one IP.

## Corrected / rejected, and why

- **AI tried to execute git operations directly** (branch creation, commits,
  pushes) via its own tool access, multiple times across this session. Rejected
  every time — commands were run by hand instead. Reason: this is a graded
  exercise in *my* command-line proficiency; having the AI execute git/Linux
  commands on my behalf would defeat the purpose even if the outcome looked
  identical. AI was used for guidance and diagnosis, not as a remote hands.
- **AI's suggested merge-conflict resolution was incomplete**: applying it
  literally dropped the closing brace and the 404 handler from `src/index.js`,
  which `node --check` caught before it was committed further. Caught and fixed
  before proceeding — a reminder that "syntax-valid" and "matches intent" are
  not the same check.
- **A duplicate `server.listen()` call slipped past that same fix** and past
  `node --check` (a syntax checker, not a runtime one) — only surfaced once
  deployed, via `systemd`'s journal (`ERR_SERVER_ALREADY_LISTEN`). This is
  logged specifically because it's the clearest example in this engagement of
  why "AI output looked fine" isn't sufficient verification — it took an actual
  runtime test on the real server to find it, not a read-through.
- **AI proceeded to commit two handover docs directly to `main`** right after
  helping write `BRANCHING.md`, which states commits to `main` should never
  happen directly. I caught this inconsistency, not the AI. Once flagged, AI's
  proposed fix (move remaining doc work to a branch, merge via PR, log the
  inconsistency in the Assumptions Log) was accepted — but the initial mistake,
  and catching it, is the more instructive part of this log entry than the fix.
- **Reviewed, not blindly accepted, the security-group and file-permission
  decisions above**: AI disclosed the tradeoff each time (e.g., "this would be
  the wrong call on production") rather than presenting a single "correct"
  answer, which is what made them acceptable to sign off on rather than a
  default I'd have to question afterward.
