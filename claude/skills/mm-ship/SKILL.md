---
name: mm-ship
description: |
  Promotes a Money Movement (MM) story through environment gates as Phases 5, 6, and 7 of InCred's SDLC pipeline. Use this skill whenever the user asks to ship, promote, deploy, or move a story to QA, runway, or prod — even if they just say "ship it" or "push to QA". Supports --qa, --runway, --prod flags for explicit targeting. Requires Phase 4 (mm-tdd) BUILD-EVIDENCE.md to exist. PR flow: impl-branch → qa-env (Phase 5), qa-env → runway (Phase 6), runway → prod (Phase 7). Per-service branch names loaded from Knowledge_Base/services.md. Conflict check runs before every PR — asks to refresh if target env is behind upper env, never refreshes automatically. Tech Lead + Primary Owner are always-on reviewers. Never auto-promotes between environments.
command: mm-ship
trigger: |
  - User says "ship", "deploy", "promote", "push to QA/runway/prod"
  - User asks to start Phase 5, 6, or 7
  - /mm-ship --qa, /mm-ship --runway, /mm-ship --prod
  - Claude detects MM environment promotion context after Phase 4 is complete
  Note: Never auto-invoked. User must explicitly trigger after Phase 4 completes.
kind: skill
visibility: project
---

## INTERACTION PROTOCOL

**Identify the caller (run once at start):**
```bash
git config user.email
```
Look up the email in `MM/Knowledge_Base/personas.md`. If found, greet by first name and store USER_NAME / USER_ROLE. If not found, present once:
```
I don't recognise [email] in personas.md. Who are you?
  [1] PM / Product Manager    [2] Developer
  [3] Tech Lead               [4] QA Engineer
  [5] Skip — continue anonymously
```
Role adjusts greeting and log author only — it **never blocks anyone from running any phase**.

**All choices and approvals use numbered options.** Never present a gate as `(yes / no)`. Standard formats:
- Approve / reject: `[1] Approve — proceed  [2] Reject — stop  [3] Comment first`
- Phase gate: `[1] Start Phase N  [2] Review more  [3] Stop here`
- Notification: `[1] Send now  [2] Skip  [3] Edit first`
- Branch action: `[1] Refresh  [2] Skip — PR anyway  [3] Cancel`
- Triage confirm: `[1] Apply all  [2] Edit the plan  [3] Cancel`

---

## Overview

**Phases 5, 6 & 7** of InCred MM's 8-phase SDLC pipeline.

**PR flow — branch names loaded per-service from Knowledge_Base/services.md:**

| Phase | From | To | Evidence in PR | Slack |
|-------|------|----|---------------|-------|
| 5 — QA `--qa` | `[impl-branch]` | `[qa-env]` (per service) | BUILD-EVIDENCE summary + link | `#mm-dev-qa` → @Ansuman |
| 6 — Runway `--runway` | `[qa-env]` | `[runway-branch]` (per service) | QA-EVIDENCE summary + link | `#mm-dev-qa` → @Ansuman |
| 7 — Prod `--prod` | `[runway-branch]` | `prod` (default, override per service) | BUILD + QA-EVIDENCE both | `#mm-dev-pm` → @Tech Lead @PM @Ansuman |

**Always-on PR reviewers (every environment):** Tech Lead + Primary Owner
**Prod adds:** one additional developer (always ask — never assume)

**Hard rules:**
1. Human approval before every push and PR creation
2. Never skip environments — Phase 5 → 6 → 7 in order
3. Conflict check before every PR — show options, wait for human choice
4. `git push --delete` and `git reset --hard` require explicit human approval gate before execution
5. Never auto-invoke Phase 8 (`/mm-telemetry`)

---

## STEP 0: DOMAIN GUARD

Valid prefix: `MM-` only. Reject any other domain prefix with no side effects.

---

## STEP 1: LOAD SERVICE CONFIG

```bash
cd /Users/aryankumarmaurya/Incred-Engineers/InCred-Product-PRFAQ-Epic-Stories-Artefacts-MonoRepo
git checkout main && git pull origin main
```

Read:
1. `MM/Knowledge_Base/services.md` — per-service branch config (QA envs, runway branch, prod branch), primary owner name
2. `MM/Knowledge_Base/personas.md` — resolve primary owner + Tech Lead Slack handles and emails
3. `MM/Epic_Stories/[Epic_ID]_[Title]/PLAN.md` — impl branch name, services in scope, p95 targets
4. `MM/Epic_Stories/[Epic_ID]_[Title]/BUILD-EVIDENCE.md` — test summary for PR description
5. `MM/Epic_Stories/[Epic_ID]_[Title]/QA-EVIDENCE.md` (if exists) — for runway/prod PR descriptions

**Detect target environment from flags or context:**
- `--qa` → Phase 5: impl-branch → qa-env
- `--runway` → Phase 6: qa-env → runway-branch
- `--prod` → Phase 7: runway-branch → prod
- No flag → check QA-EVIDENCE.md to determine next unshipped environment

**For each service in PLAN.md Section 2, resolve from services.md:**
```
Service: [name]
  impl-branch: [prefix]/[Epic_ID]_[Story_ID]     ← from PLAN.md Implementation Info
  QA envs:     [preprod, qa-mm, qa-1, ...]        ← from services.md
  Runway:      [staging / runway / release]        ← from services.md (varies per service)
  Prod:        prod                               ← default; check services.md for override
```

If multiple QA envs available and none specified → ask:
```
Which QA environment for [service-name]?
Available: [list from services.md]
```

Print:
```
📦 Promoting: [Story_ID] → [TARGET_ENV]
   Services: [N] | Primary owner: [Name] | Tech Lead: Sunil Kumar
   Branch config loaded from services.md ✅
   Prior envs passed: [none | qa ✅ | qa ✅ runway ✅]
```

---

## STEP 2: PULL LATEST + CONFLICT CHECK

Pull both source and target branches before checking for conflicts:

```bash
git fetch origin
git pull origin [source-branch]
git pull origin [target-branch]
```

**Conflict check — is the target env behind its upper env?**

| Phase | Source | Target | Check: is target behind? | Upper env |
|-------|--------|--------|--------------------------|-----------|
| 5 — QA | impl-branch | qa-env | `git log [qa-env]..[runway-branch] --oneline` | runway-branch |
| 6 — Runway | qa-env | runway-branch | `git log [runway-branch]..[prod] --oneline` | prod |
| 7 — Prod | runway-branch | prod | No check needed | — |

If target is behind upper env:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  BRANCH CONFLICT — [target-branch] is [N] commits behind [upper-env]

Other developers may have changes on this branch.
Refreshing will recreate [target-branch] from [upper-env].

Options:
  1. Refresh [target-branch]
     (creates backup [target-branch]-bkp-[dd-mm-yyyy], recreates from [upper-env])
  2. Skip refresh — create PR anyway (merge conflicts likely)
  3. Cancel — coordinate with team first

Choose (1 / 2 / 3):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If refresh selected (option 1):**

Show full plan and wait for explicit "yes" before any execution:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Branch Refresh

This will:
  Step 1: Create backup
    git checkout [target-branch]
    git checkout -b [target-branch]-bkp-[dd-mm-yyyy]
    git push origin [target-branch]-bkp-[dd-mm-yyyy]

  Step 2: Recreate [target-branch] from [upper-env]
    git push origin --delete [target-branch]
    git checkout [upper-env]
    git pull origin [upper-env]
    git checkout -b [target-branch]
    git push origin [target-branch]

⚠️  Step 2 deletes [target-branch] remotely.
    Backup will be at: [target-branch]-bkp-[dd-mm-yyyy]

  [1] Execute refresh        [2] Cancel — don't refresh
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Execute each step sequentially. Confirm backup push succeeded before proceeding to deletion.

---

## STEP 3: BUILD PR DESCRIPTION

**Phase 5 (QA) PR description includes:**
```markdown
## [Story_ID] → [qa-env]

### Services
[list from PLAN.md Section 2]

### Interface Changes
[summary from PLAN.md Section 2]

### Build Evidence
Tests: [N] unit ✅ | [N] integration ✅ | [N] regression ✅
p95: [all targets met ✅ | [scenario] at [N]ms ⚠️]
[Link to BUILD-EVIDENCE.md]
```

**Phase 6 (Runway) PR description includes:**
```markdown
## [Story_ID] → runway

### QA Evidence
[qa-env] ✅ passed [timestamp]
Smoke: [N] tests ✅ | p95: [all met ✅]
[Link to QA-EVIDENCE.md]
```

**Phase 7 (Prod) PR description includes both:**
```markdown
## [Story_ID] → prod

### Build Evidence
[BUILD-EVIDENCE summary + link]

### QA Evidence
qa: [env-name] ✅ | runway ✅
[QA-EVIDENCE summary + link]
```

---

## STEP 4: HUMAN APPROVAL GATE — Before PR creation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Create PR for [TARGET_ENV]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
From:  [source-branch]
To:    [target-branch]
Title: [[Story_ID]] [story summary] → [target-env]

[PR body preview as above]

Reviewers (always):
  • Sunil Kumar (@sunil.kumar) — Tech Lead
  • [Primary Owner name] (@[handle]) — Primary Owner

[Prod only — ask:]
  Additional developer reviewer needed for prod.
  Who should review? (Aryan Maurya / Akash Gupta / Jonathan D'mello / Ankaj Kumar)

  [1] Create PR             [2] Cancel — I'll raise it manually     [3] Edit PR body first
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## STEP 5: CREATE PR VIA GITHUB CONNECTOR

After "yes" → create PR via GitHub connector with title, body, reviewers, and labels.

---

## STEP 6: SLACK NOTIFICATION

Ask before sending, using numbered options:
```
Send Slack notification to [channel] tagging [names]?
  [1] Send now     [2] Skip     [3] Edit message first
```

**Phase 5 — QA:**
```
Channel: #mm-dev-qa
Tag: @mohanta.mishra
Content:
  🧪 QA PR ready — [Story_ID]
  PR #[N]: [impl-branch] → [qa-env] | [link]
  
  Build Evidence: [N] tests ✅ | p95 [status] | [link]
  
  Please review and run QA gate.
```

**Phase 6 — Runway:**
```
Channel: #mm-dev-qa
Tag: @mohanta.mishra
Content:
  🛫 Runway PR ready — [Story_ID]
  PR #[N]: [qa-env] → [runway-branch] | [link]
  
  QA Evidence: [qa-env] ✅ [timestamp] | Smoke [N] ✅ | p95 [status] | [link]
  
  Please review for runway promotion.
```

**Phase 7 — Prod:**
```
Channel: #mm-dev-pm
Tag: @sunil.kumar @[pm-handle] @mohanta.mishra
Content:
  🚀 Prod PR ready — [Story_ID]
  PR #[N]: [runway-branch] → prod | [link]
  
  Build Evidence: [N] tests ✅ | p95 [status] | [link]
  QA Evidence: qa ✅ | runway ✅ | [link]
  
  Requires Tech Lead + PM approval before merge.
```

---

## STEP 7: DELEGATE TO @qa-gatekeeper (after PR merges + deployment)

- **QA:** Full regression + integration + p95 vs PLAN.md targets. Test command: `npm run test` (or per services.md override)
- **Runway:** Smoke + performance under load + p95 vs QA baseline
- **Prod:** Smoke + post-deploy p95 monitoring for [N] minutes

---

## STEP 8: HUMAN APPROVAL GATE — Before writing QA-EVIDENCE.md

Show `@qa-gatekeeper` results. If gate FAILS → block, show failures, user decides whether to fix or rollback.

---

## STEP 9: UPDATE QA-EVIDENCE.md

Append environment results. Show approval gate, push to PM monorepo after "yes".

---

## STEP 10: SIGN-OFF TREE

```
═══════════════════════════════════════════════════════════════════
MM SHIP — [TARGET_ENV] ✅
═══════════════════════════════════════════════════════════════════
Story:          [Story_ID]
Environment:    [TARGET_ENV]
PR:             #[N] merged
Branch config:  [source] → [target] (from services.md ✅)
Reviewers:      Sunil Kumar ✅ | [Primary Owner] ✅ [| Additional dev ✅ if prod]
Slack:          [channel] ✅

──────────────────────────────────────────────────────────────────
ENVIRONMENT PROGRESS
──────────────────────────────────────────────────────────────────
  qa:      [✅ [env-name] | ⏳ pending]
  runway:  [✅ | ⏳ pending]
  prod:    [✅ | ⏳ pending]

──────────────────────────────────────────────────────────────────
NEXT
──────────────────────────────────────────────────────────────────
  qa passed → runway:   /mm-ship --runway [Epic_ID] [Story_ID]
  runway passed → prod: /mm-ship --prod [Epic_ID] [Story_ID]
  prod passed:          /mm-telemetry [Epic_ID] [Story_ID]
═══════════════════════════════════════════════════════════════════
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| BUILD-EVIDENCE.md missing | Stop — run `/mm-tdd` Phase 4 first |
| services.md missing branch config | Ask developer, offer to add to services.md |
| Environment out of order | Block — show correct sequence and flags |
| Target branch behind upper env | Show conflict options — never auto-refresh |
| Destructive git op needed | Show explicit approval gate before execution |
| Deployment fails | Show output, offer retry or investigate |
| @qa-gatekeeper unavailable | Inline test run with same pass criteria |
| p95 exceeded | Block promotion, flag explicitly — never silently pass |
| User declines any gate | Ask what to change, re-present |
