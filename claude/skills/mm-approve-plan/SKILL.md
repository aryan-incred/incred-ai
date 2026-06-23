---
name: mm-approve-plan
description: |
  Reviews and approves PLAN.md sections on GitHub PRs for MM stories. Use --pm for PM reviewing Section 1 (business scope), --tech for Tech Lead reviewing Section 2 (technical approach). Invoke whenever a PM or Tech Lead wants to approve, request changes, or review the plan — even casual phrases like "I'm happy with it", "LGTM", "looks good", "I have concerns". Never posts to GitHub without explicit confirmation. Self-learns user preferences to reduce repeated friction.
command: mm-approve-plan
trigger: |
  - "approve this plan", "approve Section 1", "approve Section 2"
  - "I'm happy with this", "LGTM", "looks good, approve it"
  - "request changes", "I have concerns about the plan"
  - PM or Tech Lead wants to post a formal review on a PLAN.md PR
kind: skill
visibility: project
---

## Memory

Follows shared memory protocol: `~/.claude/skills/shared/memory-protocol.md`

Memory location: `~/.claude/skills/mm-approve-plan/memory/`

Run M0 → M2 at start. Run M3 → M5 at end.

---

## Interaction Protocol

**Identify caller** (M0):
```bash
git config user.email
```
Look up in `MM/Knowledge_Base/personas.md`. Greet by name if found.

**All choices use numbered options.**

---

## Flag Routing

| Invocation | Mode |
|-----------|------|
| `/mm-approve-plan --pm [Epic_ID] [Story_ID]` | PM reviews Section 1 (business scope) |
| `/mm-approve-plan --tech [Epic_ID] [Story_ID]` | Tech Lead reviews Section 2 (technical approach) |
| `/mm-approve-plan [Epic_ID] [Story_ID]` | Auto-detect from caller's role in personas.md |

**Auto-detect role** (when no flag): read `MM/Knowledge_Base/personas.md` for caller's role:
- PM / Product Manager → `--pm` mode
- Tech Lead / Engineering Manager → `--tech` mode
- Unknown → ask:
  ```
  Which section are you reviewing?
    [1] Section 1 — PM Business Scope (I'm a PM)
    [2] Section 2 — Technical Approach (I'm a Tech Lead)
  ```

---

## STEP 0: DOMAIN GUARD

Valid prefix: `MM-` only. Stop for any other domain.

---

## STEP 1: FIND THE PR

```bash
cd "$(git rev-parse --show-toplevel)"
git fetch origin
```

Find open PR for `feature/[Epic_ID]_[Story_ID]` via GitHub MCP.

If no PR found:
```
No open PR found for feature/[Epic_ID]_[Story_ID].
The developer needs to run /mm-blueprint first to generate PLAN.md and raise the PR.
```

Read `PLAN.md` from the PR branch.

---

## MODE: --pm (Section 1 — PM Business Scope)

Present a clear summary of what the PM is approving:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLAN.md SECTION 1 — BUSINESS SCOPE  |  PR #[N]
Story: [Story_ID]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Story Summary:  [1 sentence]
ACs (binding):  [N] — [numbered list]
Out of Scope:   [list]
Edge Cases:     [list]
Demo Gate:      [validators] | [dataset] | [pass criterion]

CHECK:
  ✅/❌ ACs match original story
  ✅/❌ Out-of-scope is explicitly listed
  ✅/❌ Demo Gate: named person + specific dataset + number

OVERALL: [READY TO APPROVE | CONCERNS — see below]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [1] Approve Section 1
  [2] Request changes — I'll describe what to fix
  [3] Cancel
```

---

## MODE: --tech (Section 2 — Technical Approach)

Present a clear summary of what the Tech Lead is approving:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLAN.md SECTION 2 — TECHNICAL APPROACH  |  PR #[N]
Story: [Story_ID]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Services in scope:   [list with change type]
Interface changes:   [N] — [endpoint → consumers affected]
Call chain:          [upstream → service → downstream]
Files to change:     [N] — [Create/Modify/Delete list]
Complexity:          [Low/Medium/High]
Compliance flag:     [YES — OBS-XX | NO]

CHECK:
  ✅/❌ All consumers of changed interfaces listed
  ✅/❌ Call chain complete (no missing hops)
  ✅/❌ File paths specific (not "relevant files")
  ✅/❌ Complexity matches change surface
  ✅/❌ OBS reference present (if MIGRATION or regulated area)

OVERALL: [READY TO APPROVE | CONCERNS — see below]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [1] Approve Section 2
  [2] Request changes — I'll describe what to fix
  [3] Cancel
```

---

## STEP 2: POST REVIEW TO GITHUB

**On [1] Approve:**

Show exactly what will be posted before sending:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Post GitHub Review
PR: #[N] | Action: APPROVE

Comment to post:
"Section [1|2] approved ✅
[One sentence summary of what was reviewed]
[Any notes or conditions if applicable]"

  [1] Post approval now    [2] Edit comment first    [3] Cancel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After posting, ask about Slack notification:
```
Notify anyone on Slack?
  [1] Yes — I'll name them    [2] Skip
```
Send only to people explicitly named. Never assume recipients.

**On [2] Request changes:**

Ask what specifically needs to change:
```
What changes are needed? (describe in plain English)
→
```

Show the review comment before posting:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Post GitHub Review
PR: #[N] | Action: REQUEST CHANGES

Comment to post:
"Section [1|2] — changes requested:
[user's description formatted clearly]"

  [1] Post this    [2] Edit first    [3] Cancel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## STEP 3: GATE STATUS

After posting, print current gate status so everyone knows what's left:

```
PR #[N] — feature/[Epic_ID]_[Story_ID] → main

  Section 1 (PM):        [✅ Approved by [name] | ⏳ Pending | ❌ Changes requested]
  Section 2 (Tech Lead): [✅ Approved by [name] | ⏳ Pending | ❌ Changes requested]

  [If both approved]:
    Both sections approved. PR is ready to merge.
    After merge → developer runs /mm-tdd to begin Phase 3.

  [If pending or changes requested]:
    Merge is blocked until both approve.
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| No open PR | Tell user to run /mm-blueprint first |
| PLAN.md not found on PR branch | Tell user PLAN.md hasn't been generated yet |
| GitHub MCP unavailable | Show review summary in terminal, instruct user to post manually |
| Role not in personas.md | Ask which section they're reviewing |
| User declines posting | Note their concerns, offer to help draft the comment |
