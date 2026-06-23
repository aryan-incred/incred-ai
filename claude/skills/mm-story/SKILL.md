---
name: mm-story
description: |
  Creates, extends, or edits Money Movement (MM) epics and stories following InCred's standards. Use this skill whenever the user asks to write a story, create an epic, add a new story to an existing epic, edit or update an existing story, draft requirements, or start a new MM feature — even if they just say "let's write up the story for X", "add a story to Epic 5", or "update story 3A". MM-specific wrapper around /epic-stories: enforces MM domain prefix, pre-loads MM Knowledge_Base and PRFAQs context, saves to the correct MM directory, and hands off to /mm-analyze when done. Use this BEFORE /mm-analyze — story creation comes first.
command: mm-story
trigger: |
  - User asks to write, create, add, or edit an MM epic or story
  - User wants to spec out a new MM feature or requirement
  - User says "add a story to existing epic" or "update this story"
  - User needs to create or modify a story before or after the SDLC pipeline
  Note: This skill runs BEFORE /mm-analyze for new stories. For edits to stories already in /mm-analyze, use /mm-analyze --revise instead.
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
- Triage confirm: `[1] Apply all  [2] Edit the plan  [3] Cancel`

---

## Overview

**Pre-Phase 1** of InCred MM's SDLC pipeline — story creation and editing comes before validation.

This skill supports three modes:
- **NEW EPIC** — create a full epic + stories from scratch
- **ADD STORY** — add a new story to an existing epic
- **EDIT STORY** — modify an existing story that hasn't entered the SDLC pipeline yet

The full story-writing intelligence lives in `/epic-stories`. This skill adds the MM-specific layer: domain guard, Knowledge_Base grounding, correct save paths, and SDLC handoff.

> **Important distinction:** Use `mm-story --edit` for stories that haven't been validated yet (pre-Phase 1). For stories already in the pipeline with an open PR, use `/mm-analyze --revise` instead — that reads PR review comments and updates the story in context.

**Monorepo:** `/Users/aryankumarmaurya/Incred-Engineers/InCred-Product-PRFAQ-Epic-Stories-Artefacts-MonoRepo/`

**Invocation:**
- `/mm-story` — new epic from scratch (prompts for feature)
- `/mm-story MM-Epic-5 payment reconciliation` — new epic with topic
- `/mm-story --add MM-Epic-5` — add a new story to existing epic
- `/mm-story --edit MM-Epic-5-Story-3A` — edit an existing story

---

## STEP 0: DOMAIN GUARD

Confirm we're working on MM before anything else.

If the user provides an Epic ID or Story ID with a non-MM prefix (e.g., `LAP-Epic-3`, `UBL-Epic-1`):

```
❌ WRONG SKILL — Domain mismatch

You passed: [provided ID]
This skill:  mm-story (Money Movement team only)

MM IDs follow the pattern: MM-Epic-[N] / MM-Epic-[N]-Story-[X]

No files were read. Nothing was created.
```

If no domain prefix is given, proceed — this skill assumes MM context.

---

## STEP 1: DETECT MODE

Determine which mode to run based on flags and what exists in the monorepo.

**Mode detection (in order):**

| Signal | Mode |
|--------|------|
| `--add MM-Epic-[N]` flag | ADD STORY to existing epic |
| `--edit MM-Epic-[N]-Story-[X]` flag | EDIT existing story |
| No flag, epic ID given, epic file exists | Ask: "Add a story or edit an existing one?" |
| No flag, no existing epic | NEW EPIC |

Print the detected mode before proceeding:
```
📝 Mode: NEW EPIC    — creating MM-Epic-[N] from scratch
➕ Mode: ADD STORY   — adding to MM-Epic-[N] (currently [N] stories)
✏️  Mode: EDIT STORY  — editing MM-Epic-[N]-Story-[X]
```

---

## STEP 2: PULL LATEST MONOREPO

```bash
cd /Users/aryankumarmaurya/Incred-Engineers/InCred-Product-PRFAQ-Epic-Stories-Artefacts-MonoRepo
git checkout main && git pull origin main
```

---

## STEP 2: LOAD MM CONTEXT

Before writing a single story, ground yourself in MM's existing knowledge. This is what separates an MM-aware spec from a generic one.

**Read in order:**
1. `MM/Knowledge_Base/` — legacy service maps, shared utilities, existing capabilities. This is the MM "Grounding Gate" — cite facts from here as `Knowledge_Base/[file] § [section]`
2. `MM/PRFAQs/` — any existing PRFAQ that this epic traces back to
3. Check `MM/Epic_Stories/` for the next available Epic number (to assign `MM-Epic-[N]`)

**MM-specific naming:**
- Epic ID format: `MM-Epic-[N]` (e.g., `MM-Epic-6`)
- Story ID format: `MM-Epic-[N]-Story-[X]` (e.g., `MM-Epic-6-Story-1`, `MM-Epic-6-Story-2A`)
- Save path: `MM/Epic_Stories/MM-Epic-[N]_[ShortTitle]/MM-Epic-[N]-[ShortTitle].md`

---

## STEP 3A: NEW EPIC MODE — Run /epic-stories with MM context

Now invoke `/epic-stories` with the MM context pre-loaded. Pass the following as working context to the `/epic-stories` workflow:

```
Domain: Money Movement (MM)
Team: InCred MM team
Knowledge Base: MM/Knowledge_Base/ (grounded — cite as KB-file § section)
PRFAQs: MM/PRFAQs/
Epic ID prefix: MM-Epic-[N]
Story ID format: MM-Epic-[N]-Story-[X or XA/XB]
Save path: MM/Epic_Stories/MM-Epic-[N]_[ShortTitle]/
Linear hierarchy: Initiative → MM Sub-Initiative → Project (this epic) → Issues (stories)

MM-specific constraints:
- Services are microservices, shared utilities, or legacy ERPNext/Frappe components
- Payment flows must reference p95 latency targets in Implementation Notes
- Any story touching KYC, AML/STR, payment limits, or reconciliation must note compliance flag
- Story points: 1-3 max, <48h per story, 8-10 stories per epic (InCred standard)
```

Follow the full `/epic-stories` workflow from Phase 0 through Phase 6:
- Phase 0: Scope Guard (right-size the epic)
- Leverage Check (what does MM's system already know?)
- Phase 1: Socratic Discovery (one question at a time)
- Phase 2: Draft Epic Header → wait for approval
- Phase 3: Draft Stories one by one → wait for approval after each
- Phase 4: Save to `MM/Epic_Stories/MM-Epic-[N]_[ShortTitle]/`
- Phase 5: Auto-Review Loop (3-agent parallel review)
- Phase 6: Linear Placement Gate + Push

The `/epic-stories` workflow handles all of this — follow it completely. Do not skip the review loop or the Linear placement gate.

---

## STEP 3B: ADD STORY MODE

Adding a story to an existing epic is scoped work — you're not rewriting the whole epic, just extending it with one new atomic story that fits the epic's existing scope.

**Read the existing epic file first:**
```bash
cat MM/Epic_Stories/[Epic_ID]_[Title]/[Epic_ID]-[ShortTitle].md
```

Extract from the existing epic:
- Current story count and last Story ID (to assign the next one)
- Epic scope (IN SCOPE / OUT OF SCOPE sections) — the new story must fit within IN SCOPE
- Epic sizing (if already at 8-10 stories → propose sub-epic instead)
- Existing story IDs to avoid duplication

**Epic health check before adding:**
```
Epic MM-Epic-[N] currently has [N] stories ([total] pts).
[If N = 8-10]: This epic is at capacity. New story should go in sub-epic MM-Epic-[N.1].
[If N < 8]:    Adding Story-[next] — fits within epic capacity.
```

**Write the new story following /epic-stories Phase 3 format:**
- Assign next Story ID: `MM-Epic-[N]-Story-[next]` (or XA/XB if splitting)
- Ask the same clarifying questions as /epic-stories Phase 1 (one at a time)
- Write ACs, Implementation Notes, Testing Strategy, Definition of Done
- Flag compliance areas if applicable (see MM Compliance Flags section)

**Append to the existing epic file** — do not rewrite the whole file:
```bash
# Append new story section to existing epic file
# Show the new story content to user first for approval
```

Show the full new story content and wait for approval before writing to the file.

After appending, re-run the auto-review (Phase 5 from /epic-stories) on the new story only — not the full epic — to keep tokens light.

---

## STEP 3C: EDIT STORY MODE

Editing a story is targeted — change only what the user specifies, preserve everything else.

> **Before editing:** Check whether this story has already entered the SDLC pipeline (does a feature branch exist? is there an open PR?). If yes, use `/mm-analyze --revise` instead — that mode reads PR review comments and updates in the correct pipeline context.

```bash
# Check for existing feature branch
git branch -a | grep feature/[Epic_ID]_[Story_ID]
```

If branch exists → stop and redirect:
```
⚠️  This story is already in the SDLC pipeline (branch exists).

Use /mm-analyze --revise [Epic_ID] [Story_ID] instead.
That skill reads PR review comments and updates the story
in the correct pipeline context with proper approval gates.
```

If no branch → proceed with edit.

**Read the existing story:**
```bash
cat MM/Epic_Stories/[Epic_ID]_[Title]/[Story_ID].md
```

**Ask the user what to change** — be specific:
```
I've read MM-Epic-[N]-Story-[X]. What would you like to change?

Current sections:
  1. User Story (As/I want/So that)
  2. Acceptance Criteria ([N] ACs)
  3. Implementation Notes
  4. Testing Strategy
  5. Definition of Done

Tell me what to update, or paste the new content.
```

Wait for the user's input. Apply only the changes requested. Do not rewrite unrelated sections.

**Show a diff-style preview before saving:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Story Edit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Story: [Story_ID]
Changes:

  BEFORE: [original text]
  AFTER:  [new text]

  [for each changed section]

  [1] Save these changes     [2] Reject — start over     [3] Change something specific
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Only write to file after explicit "yes".

After saving, run the /epic-stories review agents (Phase 5) on the changed story to catch any issues the edit introduced.

---

## STEP 4: HANDOFF

After save + review, present the SDLC handoff — do not auto-invoke anything:

**NEW EPIC or ADD STORY:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ MM STORY COMPLETE — [NEW EPIC | STORY ADDED]

Epic:    MM-Epic-[N] — [title]
Stories: [N] stories ([total] pts) | Last added: [Story_ID]
Saved:   MM/Epic_Stories/MM-Epic-[N]_[ShortTitle]/
Review:  [Health score]

NEXT: SDLC PIPELINE PHASE 1
When ready to validate, run one story at a time:

  /mm-analyze MM-Epic-[N] MM-Epic-[N]-Story-[X]

Phase 1 validates completeness before any technical
planning begins. Run for each story independently.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**EDIT STORY (pre-pipeline):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ STORY UPDATED — [Story_ID]

Changes: [summary of what changed]
Saved:   MM/Epic_Stories/[Epic_ID]_[Title]/[Story_ID].md
Review:  [Health score on changed story]

If this story hasn't been analyzed yet:
  /mm-analyze [Epic_ID] [Story_ID]

If already in pipeline with open PR:
  /mm-analyze --revise [Epic_ID] [Story_ID]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## MM Sizing Quick Reference

| Points | Time | When to use |
|--------|------|-------------|
| 1pt | ~2–4 hrs | Single endpoint, single DocType, single calculation |
| 2pts | ~1 day | Preferred max for most stories |
| 3pts | ~1.5 days | Hard ceiling — split into XA/XB if larger |

**Epic limit:** 8–10 stories. If more are needed → create sub-epic `MM-Epic-[N.M]`.

**Split trigger:** If a story exceeds 2pts or has multiple independent deliverables → split into Story XA and Story XB before finalising.

---

## MM Compliance Flags (add to story if applicable)

If any story touches these areas, note a compliance flag in Implementation Notes:

| Area | Flag |
|------|------|
| KYC / V-CIP | `COMPLIANCE: KYC — check Central-Infosec-Policies OBS` |
| AML / STR | `COMPLIANCE: AML — check OBS-relevant entries` |
| Payment limits / thresholds | `COMPLIANCE: RBI payment limits — verify current thresholds` |
| Data residency / encryption | `COMPLIANCE: Data — check infosec policy` |
| API security / access control | `COMPLIANCE: API security — check OBS` |

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Knowledge_Base empty or missing | Note "MM KB not yet built" — stay in business terms, use `RESOLVE-IN-PLAN:` markers |
| No existing PRFAQs | Proceed without PRFAQ reference — note it in epic header |
| Epic number conflict | Check `MM/Epic_Stories/` directory and pick next available N |
| /epic-stories not available | Run the full epic-stories workflow inline using the template in this skill |
