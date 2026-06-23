---
name: mm-blueprint
description: |
  Generates the technical blueprint (PLAN.md) for a validated Money Movement (MM) story as Phase 2 of InCred's SDLC pipeline. Use this skill whenever the user asks to blueprint a story, generate a plan, start Phase 2, or plan the technical approach for an MM epic/story — even if they don't say "blueprint" explicitly. Requires Phase 1 (mm-analyze) to have passed first. Supports revision mode (auto-detected or via --revise flag) to update PLAN.md based on GitHub PR review comments. Human approval is required before every git push, PR creation, and phase transition. Code writing is hard-blocked until the PR is approved by both PM and Tech Manager.
command: mm-blueprint
trigger: |
  - User explicitly asks to blueprint, plan, or generate a PLAN.md for an MM story
  - User says "start Phase 2" or "generate the technical plan"
  - User asks to revise the plan based on PR feedback
  - Claude detects MM blueprinting context during conversation
  Note: This skill is never auto-invoked after Phase 1. The user must explicitly trigger it.
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

**Phase 2** of InCred MM's 8-phase SDLC pipeline.

This skill reads the validated story from the feature branch, traces code impact using GitNexus, and generates a `PLAN.md` contract with three sections. The PLAN.md lives on the feature branch alongside the story spec — both travel in the same PR to main.

**Two non-negotiable rules:**
1. **Human approval before every push** — always show what's being pushed and wait for explicit confirmation
2. **Human approval before PR creation** — show the full PR title and body preview, wait for confirmation
3. **Never auto-invoke Phase 3** — present `/mm-tdd` as an option only after the PR merges; the user must trigger it explicitly

The reason for this gate: in a multi-service architecture, an under-specified technical plan causes scope creep mid-implementation, broken service contracts, and expensive backtracking. The PLAN.md is the binding contract that prevents all of that — so it must be human-reviewed before any code is written.

**Monorepo local path:** `/Users/aryankumarmaurya/Incred-Engineers/InCred-Product-PRFAQ-Epic-Stories-Artefacts-MonoRepo/`

**Invocation:**
- Normal mode: `/mm-blueprint MM-Epic-5 MM-Epic-5-Story-3A`
- Revision mode (manual): `/mm-blueprint --revise MM-Epic-5 MM-Epic-5-Story-3A`
- Revision mode (auto): skill detects open PR with unresolved PLAN.md comments
- Without params: `/mm-blueprint` (prompts interactively)

---

## STEP 0: DOMAIN GUARD — Run before anything else

This skill is exclusively for the **Money Movement (MM)** team. Check the domain prefix before touching git, files, or branches.

**Valid prefix:** `MM-` only.

If the Epic_ID or Story_ID starts with any other prefix (e.g., `LAP-`, `UBL-`, `TREASURY-`) — stop immediately:

```
❌ WRONG SKILL — Domain mismatch

You passed: [provided ID]
This skill:  mm-blueprint (Money Movement team only)

MM IDs follow the pattern: MM-Epic-[N] / MM-Epic-[N]-Story-[X]

No files were read. No branches were created. Nothing was changed.
```

Do not proceed past this point for non-MM IDs.

---

## Prerequisites

Verify before proceeding:
1. Phase 1 (`/mm-analyze`) has passed for this story
2. Feature branch `feature/[Epic_ID]_[Story_ID]` exists
3. Story file is present at `MM/Epic_Stories/[Epic_ID]_[Title]/[Story_ID].md`

If the feature branch doesn't exist → instruct user to run `/mm-analyze` first and stop.

---

## STEP 1: LOAD CONTEXT & DETECT MODE

Check out the feature branch:

```bash
cd /Users/aryankumarmaurya/Incred-Engineers/InCred-Product-PRFAQ-Epic-Stories-Artefacts-MonoRepo
git checkout feature/[Epic_ID]_[Story_ID]
git pull origin feature/[Epic_ID]_[Story_ID] 2>/dev/null || true
```

**Mode Detection (in order of precedence):**
1. `--revise` flag provided → **revision mode**
2. No flag → check for open PR on this branch via GitHub MCP:
   ```
   gh pr list --head feature/[Epic_ID]_[Story_ID] --state open
   ```
   - Open PR with unresolved PLAN.md review comments → **revision mode**
   - No open PR or no PLAN.md comments → **normal mode**
3. GitHub MCP unavailable → default to **normal mode**, note check skipped

Print:
```
🔍 Mode: NORMAL  — generating new PLAN.md
🔄 Mode: REVISION — open PR #[N] with [N] unresolved PLAN.md comments
```

**Read in order:**
1. `MM/Epic_Stories/[Epic_ID]_[Title]/[Story_ID].md` — validated story + ACs
2. `MM/Knowledge_Base/services.md` — service config: QA envs, branch conventions, primary owners
3. `MM/Knowledge_Base/personas.md` — resolve primary owner details from name
4. `MM/PRFAQs/` — Working Backwards context if epic has a PRFAQ
5. `templates/EPIC-STORY-TEMPLATE.md` — story structure reference

**Ask before generating PLAN.md:**
```
What is the base branch for implementation?
This is the branch mm-tdd will pull and branch from.
(e.g. main, develop, staging — check with your Tech Lead if unsure)
```

Wait for answer before proceeding. This becomes the `Base Branch` in PLAN.md and is used by mm-tdd to create the correct implementation branch.

**Extract from story:**
- All Acceptance Criteria
- AI Acceleration Strategy section (golden data + edge cases)
- Demo Gate (validators, dataset, pass criteria)
- Explicit service dependencies

---

## STEP 2: TRACE CODE IMPACT WITH GITNEXUS  *(normal mode only)*

GitNexus provides AST-level dependency tracing — it answers which services, interfaces, and call chains this story touches. This prevents missing downstream breakage in Section 2.

```
gitnexus impact [service-name] --story [Story_ID]
```

Capture:
- **Affected services** — microservices in scope
- **Interface changes** — API contracts changing and their consumers
- **Call chains** — upstream callers and downstream dependencies
- **Reusable modules** — existing utilities to leverage
- **Complexity estimate** — cyclomatic complexity of the change surface

If GitNexus is unavailable → note in PLAN.md Section 2 and request Tech Lead to complete manually before approval.

Check architecture reference for unfamiliar service ownership:
`https://github.com/Incred-Engineers/architecture`

---

## STEP 3A: GENERATE PLAN.md  *(normal mode)*

**Before generating — resolve test command:**

Check `package.json` in the code repo:
```bash
cat [repo-path]/package.json | grep -A2 '"scripts"'
```

| Situation | Action |
|-----------|--------|
| `"test": "..."` found in scripts | Default to `npm run test` — confirm with developer: *"I'll use `npm run test` — correct?"* |
| `package.json` exists but no test script | Ask: *"No test script found in package.json. What command runs the tests? (e.g. `npm run test:unit`, `jest`, or 'no tests yet')"* |
| No `package.json` found | Ask: *"Couldn't find package.json. What's the test command for this service? Or are tests not yet written for this codebase?"* |
| Developer says "no tests yet" | Record as `Test Command: TBD — no tests exist yet` in PLAN.md. mm-tdd will ask again at Phase 3 and offer to scaffold tests from scratch. |

Generate `MM/Epic_Stories/[Epic_ID]_[Title]/PLAN.md` with these three sections. Be specific enough that a developer not in this conversation can implement from this document without ambiguity.

```markdown
# PLAN.md — [Story_ID]
Epic: [Epic_ID]
Branch: feature/[Epic_ID]_[Story_ID]
Generated: [ISO 8601 timestamp]
Status: PENDING APPROVAL

---

## SECTION 1: PM BUSINESS SCOPE

### Story Summary
[One paragraph: what this story delivers, for whom, and why it matters now]

### Acceptance Criteria (Binding)
1. [AC 1 — verbatim from story]
2. [AC 2]
...

### Out of Scope
- [Explicit exclusions to prevent scope creep]
- [Things a developer might reasonably attempt that are NOT part of this story]

### Business Edge Cases
- [Edge case 1 with expected behaviour]
- [Edge case 2 with expected behaviour]

### Demo Gate
- **Validators:** [Named people from story]
- **Dataset:** [Specific dataset to use]
- **Pass Criteria:** [Quantitative — numbers, not "looks good"]

---

## SECTION 2: TECHNICAL/CODE CHANGES

### Services in Scope
| Service | Type | Change Type |
|---------|------|-------------|
| [service-name] | [Microservice/Shared Util/Legacy] | [Add/Modify/Delete] |

### Interface Changes
| Interface | Current Behaviour | New Behaviour | Consumers Affected |
|-----------|------------------|---------------|-------------------|
| [API/event/contract] | [current] | [new] | [service list] |

### Call Chain Impact (GitNexus)
[upstream-caller] → [service-being-changed] → [downstream-dependency]
[Describe what breaks or needs updating in the chain]

### Reusable Modules
- [Module/utility to use — avoids rebuilding]
- [Shared utility with import path]

### Files to Create / Modify / Delete
| Action | File Path | Reason |
|--------|-----------|--------|
| CREATE | [path] | [why] |
| MODIFY | [path] | [what changes] |
| DELETE | [path] | [why safe to remove] |

### Complexity Notes
- Cyclomatic complexity: [Low/Medium/High]
- [Gotchas, legacy constraints, non-obvious decisions]
- [Compliance flag if MIGRATION: OBS-XX from Central-Infosec-Policies]

---

## SECTION 3: MULTI-SERVICE QA SCENARIOS

### Unit Test Scenarios
| Scenario | Input | Expected Output | Edge Case? |
|----------|-------|-----------------|------------|
| [name] | [input] | [output] | [Y/N] |

### Integration Test Scenarios
| Scenario | Services Involved | Expected Behaviour | p95 Latency Target |
|----------|------------------|-------------------|-------------------|
| [name] | [service-a → service-b] | [behaviour] | [<Xms] |

### Regression Scenarios
[Existing behaviours that must not break — becomes regression suite in Phase 6]
- [behaviour 1]
- [behaviour 2]

### Golden Data for AI-Assisted Testing
[Verbatim from story's AI Acceleration Strategy — sample data and boundary
conditions developers will feed to Claude during Phase 3]

---

## IMPLEMENTATION INFO

Base Branch:    [confirmed by developer — e.g. main, develop, staging]
Branch Prefix:  [derived from requirement type — feat/fix/refactor/chore — confirm with developer]
Impl Branch:    [prefix]/[Epic_ID]_[Story_ID]
Test Command:   [confirmed — npm run test default, or as resolved]
QA Envs:        [from Knowledge_Base/services.md per service]
Primary Owner:  [name only — full details in Knowledge_Base/personas.md]

Branch prefix derivation (auto-suggest, developer confirms):
  NEW FEATURE / ENHANCEMENT / UPDATE      → feat/
  BUG FIX                                 → fix/
  REFACTOR                                → refactor/
  MIGRATION                               → chore/ (ask if feat/ is preferred)
  Custom                                  → developer specifies

---

## APPROVAL GATE

This PLAN.md must be approved by **both** reviewers before Phase 3 (TDD code
generation) begins. Merge is blocked by GitHub branch protection.

| Reviewer | Role | Status |
|----------|------|--------|
| [Sr. PM name] | Business scope sign-off (Section 1) | ⏳ Pending |
| [Tech Manager name] | Technical approach sign-off (Section 2) | ⏳ Pending |
```

---

## STEP 3B: UPDATE PLAN.md  *(revision mode)*

Fetch unresolved PR review comments via GitHub MCP, scoped to `PLAN.md`:
```
gh pr view [PR_NUMBER] --comments
```

Classify and show triage before touching any file:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — PLAN.md Revision Triage
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PR #[N] — [N] unresolved comments on PLAN.md

  #1 [Tech Manager]: "payment-router also calls settlement-service — add to call chain"
     → Section 2: Add settlement-service to call chain impact
     → Re-run GitNexus for updated trace? YES

  #2 [Sr. PM]: "Out of Scope list is missing batch processing"
     → Section 1: Add batch processing to Out of Scope

  #3 [Tech Manager]: "p95 target for integration test is unrealistic at <50ms, use <200ms"
     → Section 3: Update p95 latency target for [scenario name]

  [1] Apply all changes     [2] Edit the plan     [3] Cancel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Wait for explicit confirmation before modifying PLAN.md. If GitNexus re-run is needed, run it before updating Section 2.

---

## STEP 4: HUMAN APPROVAL GATE — Before push

Show full PLAN.md content (or diff in revision mode) and wait:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Push to feature branch
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Branch:  feature/[Epic_ID]_[Story_ID]
File:    MM/Epic_Stories/[Epic_ID]_[Title]/PLAN.md

[Show full PLAN.md content OR diff if revision]

  [1] Approve — push now     [2] Reject — stop     [3] Comment first — I'll adjust
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After confirmation:
```bash
git add MM/Epic_Stories/[Epic_ID]_[Title]/PLAN.md
git commit -m "docs: blueprint PLAN.md for [Story_ID]"
# revision: "docs: revise PLAN.md for [Story_ID] per PR #[N] feedback"
git push origin feature/[Epic_ID]_[Story_ID]
```

---

## STEP 5: HUMAN APPROVAL GATE — Before PR creation  *(normal mode only)*

Show the full PR preview and wait:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Create Pull Request
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
From:    feature/[Epic_ID]_[Story_ID]
To:      main

Title:   [Story_ID]: [one-line story summary]

Body:
  ## Story
  [Story_ID] — [title]

  ## What's in this PR
  - Validated story spec (Phase 1)
  - Technical blueprint PLAN.md (Phase 2)
    - Section 1: PM Business Scope ([N] ACs, [N] edge cases)
    - Section 2: Technical Changes ([N] services, [N] interfaces)
    - Section 3: QA Scenarios ([N] unit, [N] integration, [N] regression)

  ## Reviewers
  - Sr. PM: please review Section 1 (PM Business Scope)
  - Tech Manager: please review Section 2 (Technical/Code Changes)

  ## Gate
  Phase 3 (TDD code generation) is blocked until both approve and this PR merges.

Reviewers to assign: [Sr. PM name], [Tech Manager name]

  [1] Create PR             [2] Cancel — I'll raise it manually     [3] Edit PR body first
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After confirmation:
```bash
gh pr create \
  --title "[Story_ID]: [story summary]" \
  --body "[body from above]" \
  --reviewer "[sr-pm-github-handle],[tech-manager-github-handle]"
```

In **revision mode**: re-request review on the existing PR instead of creating a new one.

---

## STEP 6: SIGN-OFF TREE + PHASE GATE

```
═══════════════════════════════════════════════════════════════════
MM BLUEPRINT — SIGN-OFF TREE
═══════════════════════════════════════════════════════════════════
Mode:                 [NORMAL | REVISION — PR #N]
Story ID:             [Story_ID]
Epic ID:              [Epic_ID]
Branch:               feature/[Epic_ID]_[Story_ID]
PLAN.md:              [GENERATED | UPDATED] ✅
PR:                   [#N — created | #N — re-review requested]
Human Approvals:      Push ✅  |  PR ✅

──────────────────────────────────────────────────────────────────
PLAN.md SECTION SUMMARY
──────────────────────────────────────────────────────────────────
Section 1 — PM Business Scope:   [N] ACs  |  [N] edge cases
Section 2 — Technical Changes:   [N] services  |  [N] interfaces
Section 3 — QA Scenarios:        [N] unit  |  [N] integration  |  [N] regression

GitNexus Impact:    [Low/Medium/High complexity]
Compliance Flag:    [YES — OBS-XX | NO]

──────────────────────────────────────────────────────────────────
WHAT HAPPENS NEXT
──────────────────────────────────────────────────────────────────
Phase 2 complete. The PR is now open for review.

Waiting for:
  - Sr. PM to approve Section 1 (business scope)
  - Tech Manager to approve Section 2 (technical plan)

Once both approve and the PR is merged to main:
  → Run /mm-tdd to begin Phase 3 (TDD code generation)

Phase 3 will only start when you explicitly run /mm-tdd.
═══════════════════════════════════════════════════════════════════
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Feature branch doesn't exist | Instruct user to run `/mm-analyze` first |
| Story file not found on branch | Prompt for manual path confirmation |
| GitNexus unavailable | Note in PLAN.md Section 2, flag for Tech Lead manual completion |
| Architecture reference inaccessible | Note service ownership unverified, flag for Tech Manager |
| User declines push approval | Ask what to change, re-present before pushing |
| User declines PR creation | Present PR creation as optional — user can create manually |
| GitHub MCP unavailable | Skip PR creation, instruct user to raise PR manually |
| git push fails | Print remote URL and manual push command |

---

## Artifact Layout After Phase 2

```
feature/[Epic_ID]_[Story_ID]
└── MM/Epic_Stories/[Epic_ID]_[Title]/
    ├── [Story_ID].md     ← validated story spec (Phase 1)
    └── PLAN.md           ← 3-section blueprint (Phase 2)
            ↓
        PR #[N] open — human-approved
        → Sr. PM approves Section 1
        → Tech Manager approves Section 2
        → Both approved → GitHub unblocks merge
        → User merges to main
        → User explicitly runs /mm-tdd → Phase 3 begins
```
