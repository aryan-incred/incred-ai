---
name: mm-telemetry
description: |
  Generates Phase 8 telemetry for a shipped Money Movement (MM) story — posts a Slack success summary, updates the standalone HTML metrics dashboard, and triggers GitNexus + gbrain re-index for the next cycle. Use this skill whenever the user asks to wrap up a story, generate metrics, update the dashboard, post the Slack summary, or complete Phase 8. Requires all 3 environments (qa/runway/prod) to have passed in QA-EVIDENCE.md. Never auto-invoked — user must explicitly trigger after prod deploy.
command: mm-telemetry
trigger: |
  - User says "wrap up", "complete the story", "post metrics", "update dashboard", "Phase 8"
  - User asks to post the Slack success summary after prod deploy
  - User wants to re-index GitNexus or gbrain after a story ships
  - Claude detects MM Phase 8 context after prod promotion is confirmed
  Note: Never auto-invoked. User must explicitly trigger after /mm-ship prod completes.
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
- Notification: `[1] Send now  [2] Skip  [3] Edit first`
- Triage confirm: `[1] Apply all  [2] Edit the plan  [3] Cancel`

---

## Overview

**Phase 8** of InCred MM's 8-phase SDLC pipeline — the closing loop.

This skill fires after a story has been fully promoted to production. It does three things:
1. **Slack summary** — posts a structured success post to the MM channel via `@mm-release-herald`
2. **HTML dashboard update** — appends this story's metrics to the standalone fulfillment dashboard
3. **Re-index** — triggers GitNexus + gbrain re-index so the next story starts with fresh context

The dashboard and Slack post exist to make the team's throughput visible — token cost, engineering hours saved, and cyclomatic efficiency scores create a feedback loop that informs future story sizing and AI acceleration strategy.

**Non-negotiable rules:**
1. Human approval before Slack post is sent
2. Human approval before dashboard HTML is updated/committed
3. Never run if QA-EVIDENCE.md shows any environment failed

**Invocation:**
- `/mm-telemetry MM-Epic-5 MM-Epic-5-Story-3A`
- `/mm-telemetry` (prompts for IDs)

---

## Prerequisites

## STEP 0: DOMAIN GUARD — Run before anything else

This skill is exclusively for the **Money Movement (MM)** team. Check the domain prefix before reading any artifacts or posting to Slack.

**Valid prefix:** `MM-` only.

If the Epic_ID or Story_ID starts with any other prefix (e.g., `LAP-`, `UBL-`, `TREASURY-`) — stop immediately:

```
❌ WRONG SKILL — Domain mismatch

You passed: [provided ID]
This skill:  mm-telemetry (Money Movement team only)

MM IDs follow the pattern: MM-Epic-[N] / MM-Epic-[N]-Story-[X]

No Slack messages were sent. No dashboard was updated. Nothing was changed.
```

Do not proceed past this point for non-MM IDs.

---

## Prerequisites

Verify before proceeding:
1. `QA-EVIDENCE.md` exists and shows all 3 environments passed (qa ✅ runway ✅ prod ✅)
2. `BUILD-EVIDENCE.md` exists with full test summary
3. `PLAN.md` exists (source of AC count, service count, complexity)

If any environment is not yet passed → stop, show which environment is missing, instruct user to run `/mm-ship` first.

---

## STEP 1: COLLECT METRICS

Read all evidence files and compute the metrics package:

```bash
cd /Users/aryankumarmaurya/Incred-Engineers/InCred-Product-PRFAQ-Epic-Stories-Artefacts-MonoRepo
git checkout main && git pull origin main
```

Read:
- `MM/Epic_Stories/[Epic_ID]_[Title]/PLAN.md`
- `MM/Epic_Stories/[Epic_ID]_[Title]/BUILD-EVIDENCE.md`
- `MM/Epic_Stories/[Epic_ID]_[Title]/QA-EVIDENCE.md`

Compute:

```
METRICS PACKAGE — [Story_ID]

Story:              [Story_ID] — [title]
Epic:               [Epic_ID]
Requirement Type:   [CLASSIFICATION]
Services Shipped:   [N]
ACs Delivered:      [N]
Complexity:         [Low/Medium/High]

Test Coverage:
  Unit:             [N] tests
  Integration:      [N] tests
  Regression:       [N] tests
  All passing:      ✅

Environment Timeline:
  qa passed:        [timestamp]
  runway passed:    [timestamp]
  prod deployed:    [timestamp]
  Total cycle time: [N] hours from Phase 1 start to prod

p95 Latency (prod):
  [scenario]:       [N]ms vs <[N]ms target

Token Usage (estimate from session):
  Phase 1-2 (PM):   ~[N]k tokens
  Phase 3-4 (Dev):  ~[N]k tokens
  Phase 5-7 (QA):   ~[N]k tokens
  Total:            ~[N]k tokens

Estimated Engineering Hours Saved: [N] hrs
  (baseline: manual story → ~[N]hrs, AI-assisted: ~[N]hrs)
```

---

## STEP 2: DELEGATE SLACK POST TO @mm-release-herald

Spawn `@mm-release-herald` to compose and post the Slack summary.

Show the draft Slack message for human approval before sending:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Post to Slack
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Channel: #mm-releases (or configured MM channel)

[Show full Slack message draft from @mm-release-herald]

  [1] Send now     [2] Skip     [3] Edit message first
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After confirmation, send via Slack MCP.

---

## STEP 3: UPDATE HTML DASHBOARD

Generate or update `MM/Artefacts/mm-fulfillment-dashboard.html` — a self-contained standalone HTML file (no external dependencies) that tracks the team's pipeline metrics across all shipped stories.

The dashboard has two views:
1. **Story Timeline** — each shipped story as a row: story ID, type, services, AC count, cycle time, token cost, hours saved
2. **Aggregate Metrics** — running totals: total stories shipped, total ACs delivered, total tokens used, total hours saved, average cycle time

Show approval gate before writing and committing:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Update Dashboard
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: MM/Artefacts/mm-fulfillment-dashboard.html

New row being added:
  Story:       [Story_ID]
  Type:        [CLASSIFICATION]
  ACs:         [N]
  Cycle time:  [N] hrs
  Tokens:      ~[N]k
  Hours saved: ~[N] hrs

  [1] Update dashboard     [2] Skip     [3] Review new row first
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After confirmation, commit and push to main:
```bash
git add MM/Artefacts/mm-fulfillment-dashboard.html
git commit -m "chore: update fulfillment dashboard — [Story_ID] shipped to prod"
git push origin main
```

---

## STEP 4: TRIGGER RE-INDEX

Re-index GitNexus and gbrain so the next story starts with a fresh, accurate code map:

```bash
# GitNexus re-index (updates AST map after code changes)
gitnexus group-sync

# gbrain re-index (updates semantic index for MM Knowledge_Base + PRFAQs)
gbrain index MM/Knowledge_Base/ MM/PRFAQs/
```

If either tool is unavailable, note it and advise the user to run manually before starting the next story.

---

## STEP 5: SIGN-OFF TREE

```
═══════════════════════════════════════════════════════════════════
MM TELEMETRY — PHASE 8 COMPLETE
═══════════════════════════════════════════════════════════════════
Story:              [Story_ID]
Epic:               [Epic_ID]
Prod deployed:      [timestamp]

──────────────────────────────────────────────────────────────────
METRICS SUMMARY
──────────────────────────────────────────────────────────────────
  ACs delivered:       [N]
  Services shipped:    [N]
  Total tests:         [N] (all passing)
  Cycle time:          [N] hrs (Phase 1 → prod)
  Token usage:         ~[N]k tokens
  Hours saved:         ~[N] hrs

──────────────────────────────────────────────────────────────────
PHASE 8 CHECKLIST
──────────────────────────────────────────────────────────────────
  Slack summary:       [✅ posted | ❌ failed]
  Dashboard updated:   [✅ committed | ❌ failed]
  GitNexus re-index:   [✅ complete | ⚠️ unavailable — run manually]
  gbrain re-index:     [✅ complete | ⚠️ unavailable — run manually]

──────────────────────────────────────────────────────────────────
WHAT HAPPENS NEXT
──────────────────────────────────────────────────────────────────
  Story [Story_ID] is fully shipped. ✅
  Pipeline is ready for the next story in [Epic_ID].

  View dashboard: MM/Artefacts/mm-fulfillment-dashboard.html
═══════════════════════════════════════════════════════════════════
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| QA-EVIDENCE.md shows environment not passed | Stop — instruct user to complete /mm-ship first |
| Slack MCP unavailable | Show Slack message in terminal, instruct user to post manually |
| Dashboard file missing | Create it fresh with this story as the first row |
| GitNexus/gbrain unavailable | Note in output, advise manual re-index before next story |
| User declines approval gate | Ask what to change, re-present |
