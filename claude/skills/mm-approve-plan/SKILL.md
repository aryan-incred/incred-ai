---
name: mm-approve-plan
description: |
  Reviews and approves PLAN.md sections on GitHub PRs for MM stories. Invoke this skill whenever a PM wants to approve the business scope, a Tech Lead wants to approve the technical approach, someone asks to sign off on a plan, or any stakeholder says "approve this", "I'm happy with the plan", "looks good, approve it", "sign off on Section 2", or "request changes on the plan". Always confirms who to assign as reviewers — multiple people per role are supported. Never posts to GitHub without explicit confirmation.
command: mm-approve-plan
trigger: |
  - "approve this plan", "approve the PLAN.md", "sign off on the plan"
  - "approve Section 1", "approve Section 2", "approve the technical approach"
  - "I'm happy with this", "looks good, approve it", "LGTM"
  - "request changes", "I have concerns about the plan"
  - PM or Tech Lead wants to post a formal review on a PLAN.md PR
  - Claude detects approval or review intent on a PLAN.md artifact
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
Role adjusts greeting only — it **never blocks anyone from approving or reviewing**.

**All choices and approvals use numbered options.** Never present a gate as `(yes / no)`. Standard formats:
- Section approve: `[1] Approve  [2] Request changes  [3] Cancel`
- Post to GitHub: `[1] Post review now  [2] Edit comment first  [3] Cancel`
- Notification: `[1] Send now  [2] Skip  [3] Edit first`

---

## What This Does

Reads the PLAN.md on the feature branch PR, presents a clear summary of the relevant section, and posts a formal GitHub PR review after explicit confirmation. PM approves Section 1. Tech Lead approves Section 2. Both must approve before Phase 3 unlocks.

## Step 1: Find the PR

Use GitHub connector to find the open PR:
```
Find PR for branch: feature/[Epic_ID]_[Story_ID]
```

If no PR found → instruct user to run `/mm-blueprint` first.

## Step 2: Determine Section

Ask if not clear from context:
```
Which section are you reviewing?
  1 — PM Business Scope (ACs, out-of-scope, demo gate)
  2 — Technical/Code Changes (services, interfaces, files)
  both — all sections
```

## Step 3: Present Summary

**Section 1 (PM):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLAN.md SECTION 1 — BUSINESS SCOPE  |  PR #[N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Story Summary:    [1 sentence]
ACs (binding):    [N] — [list]
Out of Scope:     [list]
Demo Gate:        [validators] | [dataset] | [pass criterion]

  ✅/❌ ACs match original story
  ✅/❌ Out-of-scope is explicit
  ✅/❌ Demo Gate: named person + specific dataset + number

Overall: [READY TO APPROVE | CONCERNS below]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [1] Approve Section 1     [2] Request changes     [3] Cancel
```

**Section 2 (Tech Lead):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLAN.md SECTION 2 — TECHNICAL APPROACH  |  PR #[N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Services in scope:   [list]
Interface changes:   [N] — [summary]
Call chain:          [upstream → service → downstream]
Files to change:     [N] — [Create/Modify/Delete]
Complexity:          [Low/Medium/High]
Compliance flag:     [YES — OBS-XX | NO]

  ✅/❌ All consumers of changed interfaces listed
  ✅/❌ Call chain complete
  ✅/❌ File list specific (actual paths)
  ✅/❌ Complexity matches change surface
  ✅/❌ OBS reference present (if regulated)

Overall: [READY TO APPROVE | CONCERNS below]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [1] Approve Section 2     [2] Request changes     [3] Cancel
```

## Step 4: Post Review

Only after **[1] Approve**:

**Approving:**
- Post APPROVED review via GitHub connector
- Ask: "Who should I notify on Slack? List names — multiple people per role are fine."
- Send Slack notification to named people only

**Requesting changes:**
- Ask: "What specific changes are needed?"
- Post CHANGES_REQUESTED with those comments
- Ask: "Who should be notified on Slack?"

**Reviewer assignment:** If adding reviewers to the PR, always ask: "Are there other reviewers to add? Please list their GitHub handles — multiple people can hold the same role."

## Gate Reminder

Both PM (Section 1) and Tech Lead (Section 2) must approve before the PR can merge. GitHub branch protection enforces this. Phase 3 only starts after merge.
