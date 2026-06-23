---
name: mm-review-story
description: |
  Runs the Sr. PM Sign-Off Checklist on an MM story and surfaces specific, actionable gaps. Invoke this skill whenever a PM asks to review a story, check if a story is complete, see if it's ready for Phase 1, or wants feedback on a story — even casual phrases like "is this story ready?", "review story 3A", "does this pass the checklist?", or "what's missing from this story?". Read-only — never modifies the story.
command: mm-review-story
trigger: |
  - "review this story", "review story", "check this story"
  - "is this story ready", "is this complete", "does this pass"
  - "what's missing", "what needs to be fixed", "check the checklist"
  - "ready for phase 1", "ready for analysis"
  - PM asks for feedback on a story file
  - Claude detects a story review context in conversation
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
Role adjusts greeting only — **anyone on the MM team can review any story**.

**All choices use numbered options.** Never end a prompt with `(yes / no)`. Standard formats:
- Fix offer: `[1] Apply fixes one by one  [2] Just review — I'll fix manually  [3] Skip`
- Per-fix gate: `[1] Apply this fix  [2] Edit it first  [3] Skip this gap`

---

## What This Does

Reads the story file and runs all 6 Sr. PM Sign-Off criteria. Gives specific, actionable findings — not generic feedback. Works for both pre-pipeline stories and stories already on a feature branch PR.

## Step 1: Find the Story

Resolve from context or prompt:
- `MM/Epic_Stories/[Epic_ID]_*/[Story_ID].md`

Pull latest:
```bash
git checkout main && git pull origin main
```

If a feature branch exists, check it out to read the latest version.

## Step 2: Run the Checklist

| # | Criterion | Pass condition |
|---|-----------|----------------|
| 1 | "So What?" Test | Business value in ≤2 sentences, no technical detail |
| 2 | Story Atomicity | Completable in <48h |
| 3 | Vertical Slice | No dependency on an unshipped parallel epic |
| 4 | AI Prompt Readiness | `## AI Acceleration Strategy` with real sample data |
| 5 | No Hidden Context | No unexplained acronyms or system names |
| 6 | Demo Gate Defined | Named person + specific dataset + number-based pass criterion |

## Step 3: Output

```
═══════════════════════════════════════════════════════
MM STORY REVIEW — [Story_ID]
═══════════════════════════════════════════════════════

SR. PM SIGN-OFF CHECKLIST:
  ✅/❌ "So What?" Test      — [finding]
  ✅/❌ Story Atomicity       — [finding]
  ✅/❌ Vertical Slice        — [finding]
  ✅/❌ AI Prompt Readiness   — [finding]
  ✅/❌ No Hidden Context     — [finding]
  ✅/❌ Demo Gate Defined     — [finding]

VERDICT: [PASS — ready for /mm-analyze | FAIL — [N] gaps]

[If FAIL:]
WHAT TO FIX:
  1. [Criterion]: [specific missing item]
     Fix: Add [exact section] with [specific content needed]

NEXT:
  [PASS]:  /mm-analyze MM-Epic-[N] MM-Epic-[N]-Story-[X]
  [FAIL]:  Fix items above, then re-run this review
═══════════════════════════════════════════════════════
```

## Step 4: Offer to Fix

After presenting gaps, offer with numbered options:
```
  [1] Apply fixes one by one     [2] Just review — I'll fix manually     [3] Skip
```

On [1]: apply one at a time, each with its own numbered approval gate before saving.
