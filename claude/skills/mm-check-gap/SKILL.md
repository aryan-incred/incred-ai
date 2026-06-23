---
name: mm-check-gap
description: |
  Explains a GAP-REPORT.md in plain English and tells the PM exactly what to fix, with specific edit instructions. Invoke this skill whenever a PM asks about a gap report, wants to know what's blocking Phase 2, says "what does the gap report mean?", "what do I need to fix?", "why did the story fail?", "what's blocking this story?", or "help me understand this gap". Offers to apply fixes with approval gates. Never pushes anything without confirmation.
command: mm-check-gap
trigger: |
  - "gap report", "what does the gap mean", "what does the gap report say"
  - "what do I need to fix", "what's missing", "why did validation fail"
  - "what's blocking", "what's blocking phase 2", "story failed"
  - "help me understand", "explain the gaps"
  - PM encounters a GAP-REPORT.md and wants to understand it
  - Claude detects a gap report explanation context in conversation
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
Role adjusts greeting only — it **never blocks anyone from checking or fixing gaps**.

**All choices and approvals use numbered options.** Never present a gate as `(yes / no)`. Standard formats:
- Apply fix offer: `[1] Apply fixes one by one  [2] Just explain — I'll fix manually  [3] Skip`
- Per-fix gate: `[1] Apply this fix  [2] Edit it first  [3] Skip this gap`

---

## What This Does

Reads the GAP-REPORT.md alongside the story file, translates each gap into plain English with specific fix instructions. The PM walks away knowing exactly what to change and where. Offers to apply fixes one at a time with approval gates.

## Step 1: Find the Gap Report

Resolve from context or argument:
- Feature branch: `MM/Epic_Stories/[Epic_ID]_[Title]/GAP-REPORT.md`
- Main: same path
- If not found: ask PM to paste the gap report content

```bash
git fetch origin
git checkout feature/[Epic_ID]_[Story_ID] 2>/dev/null || git checkout main
```

Read both:
1. `GAP-REPORT.md` — the gaps
2. `[Story_ID].md` — the current story (for specific fix instructions)

## Step 2: Explain Each Gap

```
═══════════════════════════════════════════════════════
GAP REPORT — [Story_ID]
[N] items blocking Phase 2
═══════════════════════════════════════════════════════

─────────────────────────────────────────────────────
GAP 1: [Criterion in plain English — no jargon]
─────────────────────────────────────────────────────
What this means:
  [Plain English explanation]

What's currently in the story:
  "[quote the relevant existing text, or 'nothing']"

What needs to change:
  In `## [Section Name]`, change:
  BEFORE: "[current text]"
  AFTER:  "[exactly what to write]"

Time to fix: ~[N] mins

─────────────────────────────────────────────────────
[repeat for each gap]

═══════════════════════════════════════════════════════
PRIORITY:
  Blocking Phase 2:  Gaps [N, N] — fix these first
  Nice to have:      [N] if any

AFTER FIXING:
  1. Commit changes to the feature branch
  2. Push to feature/[Epic_ID]_[Story_ID]
  3. Re-run: /mm-analyze [Epic_ID] [Story_ID]
═══════════════════════════════════════════════════════
```

## Step 3: Offer to Fix

After presenting:
```
  [1] Apply fixes one by one     [2] Just explain — I'll fix manually     [3] Skip
```

On [1]: fix one gap at a time with an approval gate:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Fix Gap [N]: [criterion name]

In [Story_ID].md, [Section Name]:

BEFORE:
  [current text]

AFTER:
  [proposed fix]

  [1] Apply this fix     [2] Edit it first     [3] Skip this gap
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Never batch-apply. Never push automatically — remind to commit and re-run `/mm-analyze` after all fixes are applied.
