---
name: mm-tdd
description: |
  Executes TDD (Test-Driven Development) for a Money Movement (MM) story as Phases 3 and 4 of InCred's SDLC pipeline. Use this skill whenever the user asks to start coding, begin implementation, write tests, run TDD, start Phase 3, or begin development on an MM story — even if they don't explicitly say "TDD". Requires Phase 2 (mm-blueprint) PR to be merged to main first. Phase 3 (Red) writes failing tests from PLAN.md Section 3. Phase 4 (Green) writes minimal code to make them pass. Human approval is required before every push, and Phase 4 never starts without explicit human confirmation after Phase 3. Generates BUILD-EVIDENCE.md on Green phase completion.
command: mm-tdd
trigger: |
  - User says "start coding", "begin implementation", "write tests", or "start Phase 3"
  - User asks to run TDD on an MM story
  - User references implementing a validated PLAN.md
  - Claude detects MM implementation context after Phase 2 is complete
  Note: Never auto-invoked. User must explicitly trigger after Phase 2 PR merges to main.
kind: skill
visibility: project
---

## Memory

Follows shared memory protocol: `~/.claude/skills/shared/memory-protocol.md`

Memory location: `~/.claude/skills/mm-tdd/memory/`

Run M0 → M2 at start. Run M3 → M5 at end.

Key things to learn:
- Does developer always approve chunk commit gates → condense them
- Which test framework is used per repo → skip auto-detection on re-runs
- Does developer always proceed from Phase 3 to Phase 4 immediately → skip the explicit gate prompt
- Does developer always run full test suite before committing → make that default

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

**Phases 3 & 4** of InCred MM's 8-phase SDLC pipeline.

This skill reads the approved PLAN.md from the PM monorepo and drives TDD across the code repo(s) identified in Section 2. It runs in two strictly separated phases:

- **Phase 3 — Red:** `@test-architect` writes failing tests scaffolded from PLAN.md Section 3. No production code yet. Human reviews and approves test commit before Phase 4 begins.
- **Phase 4 — Green:** `@implementer` writes the minimal code patches needed to make every test pass. Human reviews and approves each code commit.

The reason TDD is enforced here: in a multi-service architecture, writing tests first locks in the contract before implementation starts. This prevents the common failure mode where code is written first, tests are retrofitted, and edge cases from Section 3 get silently dropped.

**Non-negotiable rules:**
1. Human approval before every push
2. Phase 4 never starts without explicit human confirmation after Phase 3
3. No production code written during Phase 3 — tests only
4. Never auto-invoke Phase 5 (`/mm-ship`) — present it as an option after Green phase

**PM monorepo:** resolved at runtime via `git rev-parse --show-toplevel` (run this skill from inside the monorepo)

**Invocation:**
- With params: `/mm-tdd MM-Epic-5 MM-Epic-5-Story-3A`
- Without params: `/mm-tdd` (prompts interactively)
- Revision mode: `/mm-tdd --revise MM-Epic-5 MM-Epic-5-Story-3A` or auto-detected via open PR

---

## STEP 0: DOMAIN GUARD — Run before anything else

This skill is exclusively for the **Money Movement (MM)** team. Check the domain prefix before touching git, files, or branches.

**Valid prefix:** `MM-` only.

If the Epic_ID or Story_ID starts with any other prefix (e.g., `LAP-`, `UBL-`, `TREASURY-`) — stop immediately:

```
❌ WRONG SKILL — Domain mismatch

You passed: [provided ID]
This skill:  mm-tdd (Money Movement team only)

MM IDs follow the pattern: MM-Epic-[N] / MM-Epic-[N]-Story-[X]

No files were read. No branches were created. No tests were written.
```

Do not proceed past this point for non-MM IDs.

---

## Prerequisites

Verify before proceeding:
1. PLAN.md exists at `MM/Epic_Stories/[Epic_ID]_[Title]/PLAN.md` on **main** of PM monorepo
2. PLAN.md status is not `PENDING APPROVAL` — it must be merged and approved
3. Code repo(s) from PLAN.md Section 2 are cloned locally

If PLAN.md is still pending → instruct user to get the Phase 2 PR approved and merged first, then stop.

---

## STEP 1: LOAD PLAN & DETECT MODE

Pull latest main from PM monorepo and read the approved PLAN.md:

```bash
cd "$(git rev-parse --show-toplevel)"
git checkout main && git pull origin main
```

Read: `MM/Epic_Stories/[Epic_ID]_[Title]/PLAN.md`

Extract:
- **Section 1:** All ACs, out-of-scope list, business edge cases, demo gate
- **Section 2:** Services in scope, interface changes, call chain, files to create/modify/delete
- **Section 3:** Unit test scenarios, integration test scenarios, regression scenarios, golden data

**Mode Detection:**
1. `--revise` flag → revision mode (fix failing tests or code from prior run)
2. No flag → check for open PR on implementation branch in code repo via GitHub MCP
   - Open PR with unresolved test/code review comments → revision mode
   - No open PR → normal mode
3. GitHub MCP unavailable → default to normal mode, note check skipped

Print:
```
📋 PLAN.md loaded from main
   Story: [Story_ID] | Epic: [Epic_ID]
   Services: [N] | ACs: [N] | Test scenarios: [N]
🔍 Mode: NORMAL — beginning Phase 3 (Red)
```

---

## STEP 2: CREATE IMPLEMENTATION BRANCH IN CODE REPO

**Read from PLAN.md `## IMPLEMENTATION INFO`:**
- `Base Branch` — what to pull and branch from
- `Branch Prefix` — feat/fix/refactor/chore (derived from requirement type)
- `Impl Branch` — full branch name: `[prefix]/[Epic_ID]_[Story_ID]`
- `Test Command` — default `npm run test`, or as confirmed in blueprint

If any of these are missing (older plans) → ask the developer before proceeding.

If `Test Command` is `TBD — no tests exist yet` → proceed; `@test-architect` will scaffold from scratch in Phase 3.

**Pull base branch before creating implementation branch** — local may be stale:

```bash
cd [local-path-to-code-repo]
git checkout [base-branch]
git pull origin [base-branch]
```

**Create implementation branch:**
```bash
git checkout -b [prefix]/[Epic_ID]_[Story_ID]
# e.g. feat/MM-Epic-5_MM-Epic-5-Story-3A
#      fix/MM-Epic-5_MM-Epic-5-Story-3A
```

If branch already exists (re-entry):
```bash
git checkout [prefix]/[Epic_ID]_[Story_ID]
git pull origin [prefix]/[Epic_ID]_[Story_ID] 2>/dev/null || true
```

Print:
```
🌿 Implementation branch: [prefix]/[Epic_ID]_[Story_ID]
   Base: [base-branch] (pulled ✅)
   Repo: [repo-name] at [local-path]
   Test command: [npm run test | custom command | TBD]
```

---

## PHASE 3 — RED: WRITE FAILING TESTS

### STEP 3: DELEGATE TO @test-architect

Spawn `@test-architect` with the following context:

```
You are the test architect for this MM story implementation.

Read PLAN.md Section 3 and write failing tests for:
- All unit test scenarios (table in Section 3)
- All integration test scenarios with p95 latency assertions
- All regression scenarios (existing behaviours that must not break)
- Use the golden data from Section 3 as test fixtures

Rules:
- Write tests ONLY — no production code
- Tests must fail when run against the current codebase (that's the point)
- Use the project's existing test framework (detect from repo: pytest/jest/etc.)
- Place tests in the correct test directories per repo conventions
- Each test must map to a named scenario from PLAN.md Section 3
- Add a comment on each test: # PLAN.md: [Scenario Name]

Output: list of test files written and their locations
```

While `@test-architect` runs, read the existing test structure in the code repo to confirm conventions. Confirm the test framework and directory structure before finalizing file paths.

---

### STEP 4: HUMAN APPROVAL GATE — Before committing tests

Show the full list of test files and their content:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Phase 3 (Red) Test Commit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Branch:  feature/[Epic_ID]_[Story_ID]
Repo:    [repo-name]

Test files to commit:
  [path/to/test_file_1.py]  — [N] tests
  [path/to/test_file_2.py]  — [N] tests

Coverage against PLAN.md Section 3:
  Unit tests:        [N]/[N] scenarios covered
  Integration tests: [N]/[N] scenarios covered
  Regression tests:  [N]/[N] scenarios covered

[Show full content of each test file]

  [1] Run tests & commit     [2] Review tests first     [3] Reject — revise tests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Run tests to verify they fail (this is the Red gate — if tests pass before implementation, they're testing nothing):

```bash
cd [code-repo-path]
pytest [test-files] -v 2>&1 | tail -30
# or: npm test -- [test-files]
```

Show test output. If tests pass unexpectedly → investigate with the user before proceeding (tests may be testing the wrong thing or the feature already exists).

After confirmation:
```bash
git add [test-files]
git commit -m "test(red): failing tests for [Story_ID] — [N] scenarios from PLAN.md"
git push origin feature/[Epic_ID]_[Story_ID]
```

---

### STEP 5: PHASE 3 GATE — Human must confirm before Phase 4

Never proceed to Phase 4 automatically. Present it explicitly:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PHASE 3 COMPLETE — Red phase committed

[N] failing tests pushed to feature/[Epic_ID]_[Story_ID]

Test Results:
  Unit:        [N] failing ✅
  Integration: [N] failing ✅
  Regression:  [N] failing ✅

All tests are correctly failing. Phase 3 gate passed.

  [1] Start Phase 4 (Green)     [2] Review tests more     [3] Stop here for now
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Wait for explicit confirmation before starting Phase 4.

---

## PHASE 4 — GREEN: WRITE MINIMAL CODE

### STEP 6: DELEGATE TO @implementer

Spawn `@implementer` with the following context:

```
You are the implementer for this MM story.

Context:
- PLAN.md Section 2: [paste services, interface changes, files to create/modify/delete]
- PLAN.md Section 1 ACs: [paste ACs]
- Failing tests at: [test file paths]

Rules:
- Write the minimal code needed to make the failing tests pass
- Do not write code that isn't covered by a test
- Do not change test files
- Respect the files-to-create/modify/delete list from PLAN.md Section 2
- Do not touch services outside the Section 2 scope
- Use existing reusable modules from Section 2 — do not rebuild
- For interface changes: update consumers listed in Section 2 interface table
- For MIGRATION type: reference OBS-XX compliance note from Section 2

After each logical chunk of code (one file or one interface change):
- Run the relevant tests and show pass/fail count
- Only move to the next file when current tests pass
```

---

### STEP 7: HUMAN APPROVAL GATE — Before each code commit

After `@implementer` completes a logical chunk, show the diff and test results before committing:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Phase 4 (Green) Code Commit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Branch:  feature/[Epic_ID]_[Story_ID]
Chunk:   [description — e.g., "payment-service endpoint + validation"]

Files changed:
  [path/to/file.py] — [+N/-N lines]

Test results after this change:
  Passing: [N] ✅
  Failing: [N] ⏳ (remaining)

[Show full diff]

  [1] Commit this chunk     [2] Reject — revise code     [3] Comment first
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After confirmation:
```bash
git add [changed-files]
git commit -m "feat([service]): [what this chunk implements] — [Story_ID]"
git push origin feature/[Epic_ID]_[Story_ID]
```

Repeat for each logical chunk until all tests pass.

---

### STEP 8: FULL TEST RUN — Green gate

Once all tests pass, run the full suite to confirm no regressions:

```bash
cd [code-repo-path]
pytest -v 2>&1 | tail -50
```

Show results. If any tests fail unexpectedly → pause and investigate with the user before proceeding.

---

### STEP 9: GENERATE BUILD-EVIDENCE.md

Generate `MM/Epic_Stories/[Epic_ID]_[Title]/BUILD-EVIDENCE.md` in the **PM monorepo** on the feature branch (or directly to main via a separate small PR):

```markdown
# BUILD-EVIDENCE.md — [Story_ID]
Generated: [ISO 8601 timestamp]
Branch: feature/[Epic_ID]_[Story_ID]
Code Repo: [repo-name]

## Test Results Summary
| Suite | Total | Passing | Failing |
|-------|-------|---------|---------|
| Unit | [N] | [N] ✅ | 0 |
| Integration | [N] | [N] ✅ | 0 |
| Regression | [N] | [N] ✅ | 0 |

## AC Coverage
| AC | Test(s) | Status |
|----|---------|--------|
| [AC 1] | [test_name] | ✅ |
| [AC 2] | [test_name] | ✅ |

## Implementation Summary
| File | Action | Lines Changed |
|------|--------|---------------|
| [path] | [CREATE/MODIFY/DELETE] | +[N]/-[N] |

## p95 Latency Targets (from PLAN.md Section 3)
| Integration Scenario | Target | Measured | Status |
|---------------------|--------|----------|--------|
| [scenario] | <[N]ms | [N]ms | ✅ |

## Commits
[List of commits on feature branch with short hash + message]
```

Show approval gate before pushing BUILD-EVIDENCE.md.

---

## STEP 10: SIGN-OFF TREE + PHASE GATE

```
═══════════════════════════════════════════════════════════════════
MM TDD — SIGN-OFF TREE
═══════════════════════════════════════════════════════════════════
Mode:               [NORMAL | REVISION]
Story ID:           [Story_ID]
Epic ID:            [Epic_ID]
Code Repo:          [repo-name]
Branch:             feature/[Epic_ID]_[Story_ID]

Phase 3 (Red):      ✅ [N] failing tests committed
Phase 4 (Green):    ✅ All [N] tests passing
BUILD-EVIDENCE.md:  ✅ Generated
Human Approvals:    All gates confirmed ✅

──────────────────────────────────────────────────────────────────
TEST SUMMARY
──────────────────────────────────────────────────────────────────
  Unit:         [N] passing
  Integration:  [N] passing
  Regression:   [N] passing (no regressions)
  p95 Latency:  [all within targets | [N] exceeded — see evidence]

──────────────────────────────────────────────────────────────────
WHAT HAPPENS NEXT
──────────────────────────────────────────────────────────────────
Phase 3 & 4 complete. BUILD-EVIDENCE.md pushed.

When you're ready to promote to QA environment:
  → Run /mm-ship qa [Epic_ID] [Story_ID]

Phase 5 (QA promotion) only starts when you explicitly run /mm-ship.
═══════════════════════════════════════════════════════════════════
```

---

## Revision Mode

When an open PR exists with unresolved review comments on test or code files:

1. Fetch PR comments via GitHub MCP
2. Classify each comment: failing test fix / code logic fix / missing scenario / out-of-scope
3. Show triage and wait for human confirmation before modifying any file
4. For new test scenarios → go back through Phase 3 gate for those scenarios
5. For code fixes → go back through Phase 4 gate for affected files
6. Regenerate BUILD-EVIDENCE.md after all fixes pass
7. Re-request review after human-approved push

---

## Error Handling

| Situation | Action |
|-----------|--------|
| PLAN.md missing or still pending | Stop — instruct user to complete Phase 2 first |
| Code repo not cloned locally | Provide clone command from PLAN.md, wait for user to clone |
| Tests pass before implementation (Red gate) | Investigate — tests may target wrong thing or feature already exists |
| All tests cannot be made green | Surface failing tests, get user guidance before stopping |
| p95 latency target missed | Flag in BUILD-EVIDENCE.md, notify user — do not silently pass |
| User declines approval gate | Ask what to change, re-present before committing |
| git push fails | Print remote URL and manual push command |
| @test-architect or @implementer unavailable | Fall back to inline execution with same rules |

---

## Artifact Layout After Phase 4

```
Code Repo:
  feature/[Epic_ID]_[Story_ID]
  ├── [test files]         ← Phase 3 (Red) — failing tests first
  └── [implementation]     ← Phase 4 (Green) — minimal code to pass

PM Monorepo (main or feature branch):
  MM/Epic_Stories/[Epic_ID]_[Title]/
  ├── [Story_ID].md        ← validated story (Phase 1)
  ├── PLAN.md              ← approved blueprint (Phase 2)
  └── BUILD-EVIDENCE.md    ← test + AC coverage proof (Phase 4)
          ↓
      Run /mm-ship qa to begin Phase 5 (human must trigger explicitly)
```
