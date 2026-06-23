---
name: mm-story
description: |
  The single PM skill for all Money Movement story work. Use whenever a PM wants to create, edit, review, fix gaps, or submit a story into the pipeline. Flags: /mm-story (create new epic), --add (add story), --edit (edit story), --review (checklist check, read-only), --check-gap (explain any GAP-REPORT.md — from story validation OR blueprint phase), --submit (Phase 1 formal gate), --revise (update from PR comments). Self-learns user preferences over time to reduce repeated approval prompts and token usage.
command: mm-story
trigger: |
  - PM wants to create, write, or spec out an MM epic or story
  - PM wants to review a story before submitting
  - PM wants to understand or fix a gap report (from any phase)
  - PM wants to formally submit a story into the SDLC pipeline
  - PM wants to revise a story based on PR feedback
kind: skill
visibility: project
---

## Memory

Follows shared memory protocol: `~/.claude/skills/shared/memory-protocol.md`

Memory location: `~/.claude/skills/mm-story/memory/`

Run M0 → M2 at start (load user preferences, skip learned gates).
Run M3 → M5 at end (log run, update user memory, surface improvement proposals every 5 runs).

---

## Interaction Protocol

**Identify caller** (M0 — run once):
```bash
git config user.email
```
Look up in `MM/Knowledge_Base/personas.md`. Greet by first name if found. If not found, ask role once (role never blocks access).

**All choices use numbered options — never yes/no.**

---

## Flag Routing

| Invocation | Mode |
|-----------|------|
| `/mm-story` | CREATE new epic |
| `/mm-story --add [Epic_ID]` | ADD story to existing epic |
| `/mm-story --edit [Epic_ID] [Story_ID]` | EDIT existing story (pre-pipeline only) |
| `/mm-story --review [Epic_ID] [Story_ID]` | REVIEW — checklist, read-only |
| `/mm-story --check-gap [Epic_ID] [Story_ID]` | CHECK GAP — explain GAP-REPORT.md from any phase |
| `/mm-story --submit [Epic_ID] [Story_ID]` | SUBMIT — Phase 1 formal gate |
| `/mm-story --revise [Epic_ID] [Story_ID]` | REVISE — update story from PR comments |

If `--help` flag → show guide below and stop. Do not run any other steps.

If no flag and Epic_ID provided but exists → ask:
```
MM-Epic-[N] exists. What would you like to do?
  [1] Add a new story    [2] Edit a story    [3] Review a story    [4] Submit a story
```

---

## --help: MM STORY GUIDE

When `--help` is detected, print the following guide in full. Do not summarize or shorten it.

---

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  
**MM STORY — COMPLETE GUIDE**  
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**CREATING STORIES**

    /mm-story                            Create a new epic from scratch
    /mm-story --add MM-Epic-5            Add a new story to an existing epic
    /mm-story --edit MM-Epic-5-Story-3A  Edit a story (only before pipeline starts)

    Tip: Enrich the Knowledge Base first for better stories:
      /mm-enrich --help

**CHECKING A STORY**

    /mm-story --review MM-Epic-5 MM-Epic-5-Story-3A
      Run the Sr. PM Sign-Off Checklist (read-only, no git ops).
      Use this to self-check before submitting.

      Checks:
        ✓ "So What?" test — business value in 2 sentences
        ✓ Story fits in <48 hours
        ✓ No dependency on unshipped work
        ✓ AI Acceleration Strategy with real sample data
        ✓ No hidden context or unexplained acronyms
        ✓ Demo Gate: named person + specific dataset + number

**UNDERSTANDING GAPS**

    /mm-story --check-gap MM-Epic-5 MM-Epic-5-Story-3A
      Explains the GAP-REPORT.md in plain English.
      Works whether the gap came from submission (Phase 1)
      or from blueprinting (Phase 2).
      Offers to apply fixes one at a time.

**SUBMITTING TO THE PIPELINE**

    /mm-story --submit MM-Epic-5 MM-Epic-5-Story-3A
      Phase 1 formal gate. Creates the feature branch,
      validates the story, and either:
        PASS → developer can run /mm-blueprint
        FAIL → GAP-REPORT.md pushed to feature branch

      After submission, the developer runs /mm-blueprint
      (generates PLAN.md — you don't need to do anything for this step)

**AFTER THE PR IS RAISED**

    PM approves Section 1:        /mm-approve-plan --pm MM-Epic-5 MM-Epic-5-Story-3A
    Tech Lead approves Section 2: /mm-approve-plan --tech MM-Epic-5 MM-Epic-5-Story-3A

    If reviewers leave comments on your story:
      /mm-story --revise MM-Epic-5 MM-Epic-5-Story-3A
      (reads PR comments, updates story, re-requests review)

**THE FULL PM FLOW**

    1. /mm-enrich --help           ← build KB first (one-time setup)
    2. /mm-story                   ← write the epic + stories
    3. /mm-story --review ...      ← self-check
    4. /mm-story --submit ...      ← formal submission
    5. Gaps? /mm-story --check-gap ...  ← understand and fix
    6. Re-submit: /mm-story --submit ...
    7. Developer runs /mm-blueprint (nothing for you to do here)
    8. /mm-approve-plan --pm ...   ← approve Section 1 of PLAN.md
    9. After merge → developer handles Phases 3–8

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  
Questions? Ask Claude in plain English — it will route to the right mode.  
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---

## STEP 0: DOMAIN GUARD

Check Epic_ID or Story_ID prefix before doing anything.

Valid: `MM-` only. Any other prefix → stop immediately:
```
❌ WRONG SKILL — mm-story is for MM team only.
MM IDs: MM-Epic-[N] / MM-Epic-[N]-Story-[X]
Nothing was read or changed.
```

---

## STEP 1: SYNC MONOREPO

```bash
cd "$(git rev-parse --show-toplevel)"
git checkout main && git pull origin main
```

---

## MODE: CREATE

*No code is read. Only story markdown files and KB index.md.*

**KB health check** (skip if memory shows user always skips):
```bash
cat MM/Knowledge_Base/index.md 2>/dev/null | head -5
```
If missing or empty:
```
⚠️  MM Knowledge Base is empty — stories will have RESOLVE-IN-PLAN: blockers.
  [1] Continue anyway    [2] Run /mm-enrich first to build the KB
```

Read in order:
1. `MM/Knowledge_Base/index.md` — domain facts quick lookup
   **Audience filter:** only follow links tagged `[PM]`. Skip any row tagged `[Dev]` (those contain API paths, HTTP methods, requestTypes — engineering detail that doesn't belong in stories).
2. `MM/PRFAQs/` — any PRFAQ this epic traces back to
3. `MM/Epic_Stories/` — next available Epic number

Run the full `/epic-stories` workflow with MM context:
- Domain: Money Movement (MM)
- Epic ID: `MM-Epic-[N]`
- Story ID: `MM-Epic-[N]-Story-[X]` or `[XA/XB]` for splits
- Save path: `MM/Epic_Stories/MM-Epic-[N]_[ShortTitle]/`
- Sizing: 1–3pts, <48h per story, 8–10 stories per epic

Follow `/epic-stories` phases 0–6 completely including review loop and Linear placement gate.

**MM compliance flags** — add to Implementation Notes if story touches:

| Area | Flag |
|------|------|
| KYC / V-CIP | `COMPLIANCE: KYC` |
| AML / STR | `COMPLIANCE: AML` |
| Payment limits | `COMPLIANCE: RBI payment limits` |
| Encryption / data residency | `COMPLIANCE: Data` |
| API security | `COMPLIANCE: API security` |

**Handoff:**
```
✅ MM STORY COMPLETE
Epic: MM-Epic-[N] | Stories: [N] ([total]pts)
Saved: MM/Epic_Stories/MM-Epic-[N]_[ShortTitle]/

NEXT:
  Self-check:   /mm-story --review MM-Epic-[N] MM-Epic-[N]-Story-[X]
  Submit when ready: /mm-story --submit MM-Epic-[N] MM-Epic-[N]-Story-[X]
```

---

## MODE: --add

Read existing epic. Check story count (8–10 = suggest sub-epic). Assign next Story ID.
Write new story in epic-stories Phase 3 format. Show full content for approval before appending.
Run review agents on new story only (not full epic — keeps tokens light).

---

## MODE: --edit

First check if story is already in the pipeline:
```bash
git branch -a | grep feature/[Epic_ID]_[Story_ID]
```

If branch exists → redirect:
```
⚠️  Story is already in the pipeline (branch exists).
Use: /mm-story --revise [Epic_ID] [Story_ID]
```

If no branch → read story, ask what to change, show diff-style preview, write only changed sections.

---

## MODE: --review

*Read-only. No git ops. No branch creation. Story files only.*

Read the story file. Run all 6 criteria.

| # | Criterion | Pass condition |
|---|-----------|----------------|
| 1 | "So What?" Test | Business value ≤2 sentences, no technical detail |
| 2 | Story Atomicity | Completable in <48h, ≤3pts |
| 3 | Vertical Slice | No dependency on unshipped parallel epic |
| 4 | AI Prompt Readiness | `## AI Acceleration Strategy` with real sample data |
| 5 | No Hidden Context | No unexplained acronyms or system names |
| 6 | Demo Gate Defined | Named person + specific dataset + number-based pass criterion |

**Output:**
```
═══════════════════════════════════════════════════════
MM STORY REVIEW — [Story_ID]
═══════════════════════════════════════════════════════
  ✅/❌ "So What?" Test      — [specific finding]
  ✅/❌ Story Atomicity       — [specific finding]
  ✅/❌ Vertical Slice        — [specific finding]
  ✅/❌ AI Prompt Readiness   — [specific finding]
  ✅/❌ No Hidden Context     — [specific finding]
  ✅/❌ Demo Gate Defined     — [specific finding]

VERDICT: [PASS — ready for --submit | FAIL — [N] gaps]

WHAT TO FIX:
  1. [Criterion]: [specific missing item]
     Fix: Add [exact section name] with [specific content]

NEXT:
  [PASS]:  /mm-story --submit [Epic_ID] [Story_ID]
  [FAIL]:  Fix above → re-run /mm-story --review
═══════════════════════════════════════════════════════
```

Offer to apply fixes:
```
  [1] Apply fixes one by one    [2] I'll fix manually    [3] Skip
```

---

## MODE: --check-gap

*Explains GAP-REPORT.md from ANY phase — story validation (--submit) or blueprint (mm-blueprint).*

Find the gap report on the feature branch:
```bash
git fetch origin
git checkout feature/[Epic_ID]_[Story_ID] 2>/dev/null || git checkout main
```

Read both:
- `MM/Epic_Stories/[Epic_ID]_[Title]/GAP-REPORT.md`
- `MM/Epic_Stories/[Epic_ID]_[Title]/[Story_ID].md`

Check the `Source:` field in GAP-REPORT.md header to tell the PM which phase found the gap:

```
═══════════════════════════════════════════════════════
GAP REPORT — [Story_ID]
Source: [mm-story --submit (Phase 1) | mm-blueprint (Phase 2)]
[N] items blocking [Phase 2 | blueprint completion]
═══════════════════════════════════════════════════════

GAP 1: [Criterion — plain English]
  What it means:    [plain English, no jargon]
  What's there now: "[current text or 'nothing']"
  What to write:
    In ## [Section Name]:
    BEFORE: "[current]"
    AFTER:  "[exact fix]"
  Time to fix: ~[N] mins

[repeat per gap]

PRIORITY: Fix gaps [N, N] first — they block progress.

AFTER FIXING:
  Commit changes to the feature branch
  Push to: feature/[Epic_ID]_[Story_ID]
  Then re-run:
    [If source = Phase 1]:  /mm-story --submit [Epic_ID] [Story_ID]
    [If source = Phase 2]:  Developer re-runs /mm-blueprint [Epic_ID] [Story_ID]
═══════════════════════════════════════════════════════
```

Offer to apply:
```
  [1] Apply fixes one by one    [2] I'll fix manually    [3] Skip
```
Show one diff at a time with approval gate. Never push automatically — remind PM to commit and push manually, then re-run the correct skill.

---

## MODE: --submit

*Phase 1 formal gate. Creates feature branch. Pushes artifacts. Story files only — never reads code.*

**Scope boundary:** Reads only story markdown files and PR comments. Never opens any code repository.

### Run checklist

Same 6 criteria as --review mode.

**Classify requirement type from story text** (no code inspection):

| Type | Signal in story text |
|------|----------------------|
| `[NEW FEATURE]` | Describes functionality that doesn't exist yet |
| `[UPDATE IN EXISTING FEATURE]` | Modifies something described as existing |
| `[BUG FIX]` | Corrects a broken behaviour |
| `[ENHANCEMENT]` | Improves performance/UX of something existing |
| `[REFACTOR]` | Restructures without changing business behaviour |
| `[MIGRATION]` | Moves data, infrastructure, or systems ⚠️ |

Service footprint from story metadata/tags — ask PM if absent.

### Create or resume feature branch

```bash
# New
git checkout -b feature/[Epic_ID]_[Story_ID]
# Re-entry
git checkout feature/[Epic_ID]_[Story_ID]
git pull origin feature/[Epic_ID]_[Story_ID] 2>/dev/null || true
```

### Check for existing GAP-REPORT.md

If found on branch — re-evaluate each prior gap against current story:
- All resolved → delete report, proceed to validation result
- Gaps remain → update report with current status

### PASS — all criteria met

Show approval gate (condensed if learned user), then:
```bash
git add MM/Epic_Stories/[Epic_ID]_[Title]/[Story_ID].md
git commit -m "docs: validated story [Story_ID] — all criteria met"
git push origin feature/[Epic_ID]_[Story_ID]
```

```
✅ SUBMITTED — [Story_ID]
Branch:           feature/[Epic_ID]_[Story_ID]
Requirement Type: [CLASSIFICATION]
Story Points:     [N]pts | Compliance: [YES/NO]

NEXT: Developer runs /mm-blueprint [Epic_ID] [Story_ID]
      (generates PLAN.md on this feature branch)
      Code writing is blocked until PLAN.md PR merges to main.
```

### FAIL — gaps found

Generate `GAP-REPORT.md` with source header:
```markdown
# GAP REPORT — [Story_ID]
Source: mm-story --submit (Phase 1)
Generated: [ISO 8601 timestamp]
Branch: feature/[Epic_ID]_[Story_ID]

## Failed Criteria
- [ ] [Criterion]: [specific missing item]

## PM Action Items
1. [Specific action — exact section name to add or fix]

## Re-entry Instructions
Fix story → commit → push to feature/[Epic_ID]_[Story_ID]
Then re-run: /mm-story --submit [Epic_ID] [Story_ID]
```

Show approval gate, then push to feature branch:
```bash
git add MM/Epic_Stories/[Epic_ID]_[Title]/GAP-REPORT.md
git commit -m "docs: gap report for [Story_ID] — [N] criteria unmet"
git push origin feature/[Epic_ID]_[Story_ID]
```

```
❌ VALIDATION FAILED — [N] criteria unmet
GAP-REPORT.md → feature/[Epic_ID]_[Story_ID]

Understand gaps: /mm-story --check-gap [Epic_ID] [Story_ID]
Fix + re-submit: /mm-story --submit [Epic_ID] [Story_ID]
```

---

## MODE: --revise

*Updates story based on open PR review comments. Story files only.*

Auto-detect: if no `--revise` flag but open PR has unresolved comments on `[Story_ID].md` → offer to switch:
```
Open PR #[N] has [N] unresolved comments on the story file.
  [1] Switch to revision mode    [2] Continue normally
```

Fetch PR comments via GitHub MCP. Filter to comments on `[Story_ID].md` only (not PLAN.md — those belong to `/mm-blueprint --revise`).

Show triage before touching any file:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  STORY REVISION TRIAGE — PR #[N]
[N] unresolved comments on [Story_ID].md

  #1 [Sr. PM]: "Demo Gate missing named dataset"
     → Update ## Demo Gate with dataset name

  #2 [Sr. PM]: "Add mobile scope — could we include it?"
     → REJECT — out of scope, log as future epic item

  [1] Apply all    [2] Edit the plan    [3] Cancel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After applying, re-run checklist. Show push approval gate. Re-request review after push.

---

## ⚠️ Human Approval Gate

Before every push (condensed for learned users — see memory protocol):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Push to feature branch
Branch: feature/[Epic_ID]_[Story_ID]
Files:  [list]
[full diff | condensed file list for trusted users]
  [1] Approve    [2] Reject    [3] Show full diff first
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Story Sizing Reference

| Points | Time | When |
|--------|------|------|
| 1pt | ~2–4 hrs | Single endpoint or calculation |
| 2pts | ~1 day | Preferred max |
| 3pts | ~1.5 days | Hard ceiling — split into XA/XB if larger |

Epic limit: 8–10 stories → sub-epic `MM-Epic-[N.M]` if more needed.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Non-MM domain prefix | Block at domain guard |
| Story file not found | Prompt for manual path |
| Branch already exists during --edit | Redirect to --revise |
| KB index.md empty | Warn, offer to enrich first |
| GAP-REPORT.md from mm-blueprint | --check-gap reads it the same way, tells PM to re-run /mm-blueprint after fixing |
| GitHub MCP unavailable | Default to normal mode, note PR check skipped |
| git push fails | Print remote URL + manual command |
