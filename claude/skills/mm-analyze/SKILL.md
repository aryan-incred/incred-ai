---
name: mm-analyze
description: |
  Analyzes Money Movement (MM) team requirements and validates epic/story completeness for InCred's SDLC pipeline. Use this skill whenever the user asks to analyze a story, kick off an epic, validate acceptance criteria, check requirement completeness, or start any MM development work — even if they don't explicitly say "analyze" or "validate". Supports manual invocation with optional Epic_ID and Story_ID parameters (/mm-analyze [Epic_ID] [Story_ID]), and Claude invokes autonomously when analyzing MM requirements in conversation. Also handles revision mode (auto-detected or via --revise flag) to update story artifacts based on GitHub PR review comments. Human approval is required before every git push, PR operation, and phase transition.
command: mm-analyze
trigger: |
  - User asks to analyze, validate, or kick off an MM epic or story
  - User references a Story ID or Epic ID in Money Movement context
  - User wants to check if a story is complete or ready for development
  - User asks to revise or update a story based on PR feedback
  - Claude detects MM requirements analysis or revision context during conversation
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

**Phase 1** of InCred MM's 8-phase SDLC pipeline.

This skill operates on the **PM monorepo** (specs, not code). It creates a feature branch as the PM's working space, validates the story against InCred's Sr. PM Sign-off Checklist, and either generates a GAP-REPORT.md for the PM to resolve, or presents the validation result and waits for the human to decide what happens next.

**Two non-negotiable rules:**
1. **Human approval before every push** — always show what's being pushed and wait for explicit confirmation
2. **Human approval before every phase transition** — never auto-invoke the next phase; present it as an option and wait

**Monorepo local path:** `/Users/aryankumarmaurya/Incred-Engineers/InCred-Product-PRFAQ-Epic-Stories-Artefacts-MonoRepo/`

**Invocation:**
- Normal mode: `/mm-analyze MM-Epic-5 MM-Epic-5-Story-3A`
- Revision mode (manual): `/mm-analyze --revise MM-Epic-5 MM-Epic-5-Story-3A`
- Revision mode (auto): skill detects open PR with unresolved comments and switches automatically
- Without params: `/mm-analyze` (prompts interactively)

---

## STEP 0: DOMAIN GUARD — Run before anything else

This skill is exclusively for the **Money Movement (MM)** team. Check the domain prefix of the provided ID before touching git, files, or branches.

**Valid prefixes:** `MM-` only.

**If the Epic_ID or Story_ID starts with any other prefix** (e.g., `LAP-`, `UBL-`, `TREASURY-`, `PersonalLoans-`, `DMS-`) — stop immediately and print:

```
❌ WRONG SKILL — Domain mismatch

You passed: [provided ID]
This skill:  mm-analyze (Money Movement team only)

MM IDs follow the pattern: MM-Epic-[N] / MM-Epic-[N]-Story-[X]

For [detected domain] work, use the correct team's analyzer skill.
No files were read. No branches were created. Nothing was changed.
```

Do not proceed past this point for non-MM IDs. Do not read any files, do not run git, do not search the monorepo.

**If no ID is provided** (plain `/mm-analyze`): prompt for the Epic_ID first, then apply this guard before doing anything else.

---

## ID Naming Convention (InCred Standard)

Always normalize IDs before proceeding:
- **Epic ID:** `[Domain]-Epic-[N]` → e.g., `MM-Epic-5`
- **Story ID:** `[Domain]-Epic-[N]-Story-[X]` → e.g., `MM-Epic-5-Story-3A`

If user provides shorthand without a domain prefix (e.g., `EPIC-5`, `5`): ask "Which team is this for?" before expanding — never assume MM.

---

## STEP 1: SYNC & DETECT MODE

```bash
cd /Users/aryankumarmaurya/Incred-Engineers/InCred-Product-PRFAQ-Epic-Stories-Artefacts-MonoRepo
git checkout main && git pull origin main
```

**Mode Detection (in order of precedence):**
1. `--revise` flag provided → **revision mode**
2. No flag → check for open PR on the feature branch via GitHub MCP:
   ```
   gh pr list --head feature/[Epic_ID]_[Story_ID] --state open
   ```
   - Open PR with unresolved review comments → **revision mode**
   - No open PR or no unresolved comments → **normal mode**
3. GitHub MCP unavailable → default to **normal mode**, note check was skipped

Print detected mode before continuing:
```
🔍 Mode: NORMAL  — running full validation
🔄 Mode: REVISION — open PR #[N] detected with [N] unresolved comments
```

**Resolve story file path (checked in order):**
1. `MM/Epic_Stories/[Epic_ID]_[Title]/[Story_ID].md`
2. `MM/Epic_Stories/[Epic_ID]_[Title]/[Story_ID]/STORY.md`
3. First `.md` file found in the story directory
4. If none found → prompt user to confirm path before aborting

---

## STEP 2: CREATE OR RESUME FEATURE BRANCH

```bash
# New branch
git checkout -b feature/[Epic_ID]_[Story_ID]

# Re-entry (branch already exists)
git checkout feature/[Epic_ID]_[Story_ID]
git pull origin feature/[Epic_ID]_[Story_ID] 2>/dev/null || true
```

Print:
```
🌿 Branch: feature/[Epic_ID]_[Story_ID] — active
```

---

## STEP 3: CLASSIFY REQUIREMENT TYPE  *(normal mode only — skip in revision)*

| Type | When |
|------|------|
| `[NEW FEATURE]` | Novel functionality not present in codebase |
| `[UPDATE IN EXISTING FEATURE]` | Enhancement to existing capability |
| `[BUG FIX]` | Defect resolution |
| `[ENHANCEMENT]` | Optimization or improvement |
| `[REFACTOR]` | Restructuring without behavioral change |
| `[MIGRATION]` | Data, infrastructure, or system migration ⚠️ |

**Service Target Footprint** (check story metadata first, ask if unclear):
Modern Microservice / Shared Utility Core / Legacy Component (ERPNext/Frappe)

**Story Sizing Limits:**
- Completable in **<48 hours** (coded + tested)
- Max **3 story points** — flag for XA/XB split if exceeded
- Epic target **8–10 stories** — suggest sub-epic if more

---

## STEP 4A: VALIDATE — SR. PM SIGN-OFF CHECKLIST  *(normal mode)*

Validate every criterion. A single unmet criterion fails the story.

| Criterion | What to Check |
|-----------|---------------|
| **"So What?" Test** | Business ROI clear without reading implementation details |
| **Story Atomicity** | Completable in <48h — flag for split if not |
| **Vertical Slice** | Ships independently, no hidden dependency on unshipped epic |
| **AI Prompt Readiness** | `## AI Acceleration Strategy` with golden data + edge cases |
| **No Hidden Context** | Any dev not in the meeting can build from this doc alone |
| **Demo Gate Defined** | `## Demo Gate` with named validators, specific dataset, quantitative pass criteria |

**Compliance check (MIGRATION only):** If epic touches KYC, V-CIP, encryption, AML/STR, consent, API security, DR/BCP → reference `Central-Infosec-Policies/policies/` and note OBS numbers.

---

## STEP 4B: PROCESS PR COMMENTS  *(revision mode)*

Fetch all unresolved review comments via GitHub MCP:
```
gh pr view [PR_NUMBER] --comments
```

Classify each comment and show a triage summary before touching any file:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — PR Comment Triage
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PR #[N] — [N] unresolved comments

  #1 [Sr. PM]: "The Demo Gate is missing the dataset name"
     → Action: Update ## Demo Gate with dataset name
     → Criterion affected: Demo Gate Defined

  #2 [Tech Manager]: "Add upstream dependency for payment-router"
     → Action: Add to story dependencies section
     → Criterion affected: No Hidden Context

  #3 [Sr. PM]: "Can we add mobile support here?"
     → Action: REJECT — out of scope, log as future epic item
     → Criterion affected: N/A

  [1] Apply all changes     [2] Edit the plan     [3] Cancel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Wait for explicit confirmation before modifying any file. After applying, re-run the full Sign-off Checklist validation.

---

## STEP 5: GAP REPORT OR CLEAR

**If existing GAP-REPORT.md found on branch:**
- Re-evaluate each prior gap against current story
- All gaps resolved → delete report, proceed to validation result
- Gaps remain → update report with current status

---

## ⚠️ HUMAN APPROVAL GATE — Required before every push

Before pushing any artifact, show the full content/diff and wait:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Push to feature branch
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Branch:  feature/[Epic_ID]_[Story_ID]
Files:   [list of files to be pushed]

[Show full diff or full content of new/changed files]

  [1] Approve — push now     [2] Reject — stop     [3] Comment first — I'll adjust
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Only proceed after **[1] Approve**. On [2] or [3] → ask what to change, re-present before pushing. Never push silently.

---

### PASS — All criteria met

After human approves the push:
```bash
git add MM/Epic_Stories/[Epic_ID]_[Title]/[Story_ID].md
git commit -m "docs: validated story [Story_ID] — all criteria met"
# revision: "docs: revised [Story_ID] per PR #[N] feedback"
git push origin feature/[Epic_ID]_[Story_ID]
```

In revision mode: re-request review on the open PR after push.

---

### FAIL — One or more criteria unmet

Generate `MM/Epic_Stories/[Epic_ID]_[Title]/GAP-REPORT.md`, show approval gate, then after confirmation:

```bash
git add MM/Epic_Stories/[Epic_ID]_[Title]/GAP-REPORT.md
git commit -m "docs: gap report for [Story_ID] — [N] criteria unmet"
git push origin feature/[Epic_ID]_[Story_ID]
```

GAP-REPORT.md structure:
```markdown
# GAP REPORT — [Story_ID]
Generated: [ISO 8601 timestamp]
Mode: [NORMAL | REVISION — PR #N]
Branch: feature/[Epic_ID]_[Story_ID]

## Failed Criteria
- [ ] [Criterion]: [specific missing item and why it fails]

## PM Action Items
1. [Specific action — exact section name to add or fix]

## Re-entry Instructions
1. Fix the story file on this branch
2. Commit and push to feature/[Epic_ID]_[Story_ID]
3. Re-run: /mm-analyze [Epic_ID] [Story_ID]

Note: Nothing moves to Linear until validation passes and the PR merges to main.
```

---

## STEP 6: SIGN-OFF TREE + PHASE GATE

Print the sign-off tree, then present Phase 2 as an option — never auto-invoke it:

```
═══════════════════════════════════════════════════════════════════
MM REQUIREMENTS ANALYSIS — SIGN-OFF TREE
═══════════════════════════════════════════════════════════════════
Mode:                     [NORMAL | REVISION — PR #N]
Ticket ID:                [Story_ID]
Epic ID:                  [Epic_ID]
Requirement Type:         [CLASSIFICATION]
Service Footprint:        [FOOTPRINT]
Story Points:             [N]pts (limit: 3pts)
Compliance Flag:          [YES — OBS-XX | NO]
Validation Status:        [PASS | FAIL]
Branch:                   feature/[Epic_ID]_[Story_ID]
Human Approval:           ✅ Confirmed

──────────────────────────────────────────────────────────────────
SR. PM SIGN-OFF CHECKLIST
──────────────────────────────────────────────────────────────────
  "So What?" Test:          [✅ | ❌]
  Story Atomicity (<48h):   [✅ | ❌]
  Vertical Slice:           [✅ | ❌]
  AI Prompt Readiness:      [✅ | ❌]
  No Hidden Context:        [✅ | ❌]
  Demo Gate Defined:        [✅ | ❌]

──────────────────────────────────────────────────────────────────
WHAT HAPPENS NEXT
──────────────────────────────────────────────────────────────────
[If PASS + NORMAL]:
  Phase 1 complete. When you're ready to generate the technical
  blueprint, run: /mm-blueprint [Epic_ID] [Story_ID]

[If PASS + REVISION]:
  Story updated and re-review requested on PR #[N].
  Waiting for Sr. PM and Tech Manager to re-review.

[If FAIL]:
  GAP-REPORT.md pushed to feature/[Epic_ID]_[Story_ID]
  Fix the story, then re-run this skill to re-validate.
  Nothing moves to Linear until the PR merges to main.
═══════════════════════════════════════════════════════════════════
```

Phase 2 is only started when the user explicitly runs `/mm-blueprint`. This skill does not invoke it.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Git workspace dirty | Abort — instruct user to commit or stash first |
| Story file not found | Prompt for manual path before aborting |
| ID format non-standard | Normalize, confirm with user |
| Branch already exists | Checkout + pull, do not recreate |
| GitHub MCP unavailable | Default to normal mode, note PR check was skipped |
| User declines approval gate | Ask what to change, re-present before pushing |
| git push fails | Print remote URL and manual push command |

---

## Artifact Layout

```
feature/[Epic_ID]_[Story_ID]
└── MM/Epic_Stories/[Epic_ID]_[Title]/
    ├── [Story_ID].md      ← story spec
    ├── GAP-REPORT.md      ← if validation fails (deleted on pass)
    └── PLAN.md            ← added by /mm-blueprint when human triggers Phase 2
            ↓ PR to main (human-approved push)
            → Sr. PM + Tech Manager approve (GitHub branch protection)
            → Merge → Phase 3 unlocked (human must explicitly trigger /mm-tdd)
```
