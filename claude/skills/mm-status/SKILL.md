---
name: mm-status
description: |
  Shows the current pipeline state for any Money Movement (MM) story across all 8 phases. Use this skill whenever the user asks "where are we", "what phase are we on", "what's the status of story X", "what's blocking", or "what's next" for any MM story — even mid-conversation. Works without parameters (scans for active stories) or with explicit Epic_ID and Story_ID. Read-only — never pushes or modifies anything.
command: mm-status
trigger: |
  - User asks about current phase, pipeline status, or what's next for an MM story
  - User says "where are we", "what's blocking", "status check", "pipeline status"
  - Claude needs to orient before recommending the next action in MM work
  - User references a story ID and wants to know its state
kind: skill
visibility: project
---

## Memory

Follows shared memory protocol: `~/.claude/skills/shared/memory-protocol.md`

Memory location: `~/.claude/skills/mm-status/memory/`

Run M0 → M2 at start. Run M3 → M5 at end.
(Read-only skill — M3/M5 only log which story was checked and what phase it was at.)

Key things to learn:
- Which story the user checks most frequently → surface it first when no params given
- Does GitHub MCP always fail for this user → skip the PR check, use local file detection only

---

## INTERACTION PROTOCOL

**Identify the caller (run once at start):**
```bash
git config user.email
```
Look up the email in `MM/Knowledge_Base/personas.md`. If found, greet by first name (e.g. `Hi Aryan 👋 — pipeline status check.`). If not found, ask with numbered options who they are. Role is informational only — included in the status report header.

---

## Overview

A lightweight read-only pipeline inspector. It reads the PM monorepo and reports exactly where a story stands across all 8 phases — what's done, what's in progress, what's blocking, and what command to run next.

**Read-only — this skill never writes, pushes, or creates branches.**

**Invocation:**
- With params: `/mm-status MM-Epic-5 MM-Epic-5-Story-3A`
- Without params: `/mm-status` — scans `MM/Epic_Stories/` for active stories

---

## STEP 1: DISCOVER STORIES (if no params given)

```bash
cd "$(git rev-parse --show-toplevel)"
git checkout main && git pull origin main

# Find all active story directories
find MM/Epic_Stories -name "*.md" -not -name "GAP-REPORT.md" -not -name "PLAN.md" \
  -not -name "BUILD-EVIDENCE.md" -not -name "QA-EVIDENCE.md" | sort
```

If multiple stories found, list them and ask which to inspect — or show all if ≤3.

---

## STEP 2: DETERMINE PHASE FOR EACH STORY

For each story, check which artifacts exist to determine current phase:

| Artifact Present | Phase Inference |
|-----------------|-----------------|
| Story file only, no branch | Phase 1 not started |
| Story file + feature branch exists | Phase 1 in progress |
| GAP-REPORT.md on feature branch | Phase 1 failed — gaps unresolved |
| Story file, no gaps, no PLAN.md | Phase 1 passed — Phase 2 not started |
| PLAN.md on feature branch, no PR | Phase 2 in progress |
| PLAN.md on feature branch, PR open | Phase 2 pending approval |
| PLAN.md on main (PR merged) | Phase 2 complete — Phase 3 not started |
| BUILD-EVIDENCE.md exists | Phase 3 & 4 complete |
| QA-EVIDENCE.md, qa only | Phase 5 complete — Phase 6 not started |
| QA-EVIDENCE.md, qa + runway | Phase 6 complete — Phase 7 not started |
| QA-EVIDENCE.md, all 3 envs | Phase 7 complete — Phase 8 not started |
| mm-fulfillment-dashboard.html updated | Phase 8 complete — story fully shipped |

Check branches in code repo and PR state via GitHub MCP where needed.

---

## STEP 3: OUTPUT STATUS REPORT

```
═══════════════════════════════════════════════════════════════════
MM PIPELINE STATUS
═══════════════════════════════════════════════════════════════════
Story:    [Story_ID] — [title]
Epic:     [Epic_ID]
As of:    [timestamp]

──────────────────────────────────────────────────────────────────
PHASE PROGRESS
──────────────────────────────────────────────────────────────────
  Phase 1 — Sync & Scoping:        [✅ passed | 🔴 gaps | ⏳ in progress | ⬜ not started]
  Phase 2 — Blueprinting:          [✅ merged | 🔄 PR open #N | ⏳ in progress | ⬜ not started]
  Phase 3 — TDD Red:               [✅ committed | ⏳ in progress | ⬜ not started]
  Phase 4 — TDD Green:             [✅ passing | ⏳ in progress | ⬜ not started]
  Phase 5 — QA Environment:        [✅ passed | ❌ failed | ⬜ not started]
  Phase 6 — Runway Environment:    [✅ passed | ❌ failed | ⬜ not started]
  Phase 7 — Prod Environment:      [✅ passed | ❌ failed | ⬜ not started]
  Phase 8 — Telemetry:             [✅ complete | ⬜ not started]

──────────────────────────────────────────────────────────────────
CURRENT STATUS
──────────────────────────────────────────────────────────────────
  Active phase:   Phase [N] — [phase name]
  Status:         [what's happening right now]
  Blocking:       [what's preventing the next step, if anything]

──────────────────────────────────────────────────────────────────
ARTIFACTS
──────────────────────────────────────────────────────────────────
  Story file:         [✅ exists | ❌ missing]
  GAP-REPORT.md:      [✅ present — needs PM action | ✅ resolved | N/A]
  PLAN.md:            [✅ on main | 🔄 on feature branch | ❌ missing]
  BUILD-EVIDENCE.md:  [✅ exists | ❌ missing]
  QA-EVIDENCE.md:     [✅ exists | ❌ missing]

──────────────────────────────────────────────────────────────────
NEXT ACTION
──────────────────────────────────────────────────────────────────
  [Specific command to run and brief reason]
  e.g.: /mm-blueprint MM-Epic-5 MM-Epic-5-Story-3A
        (Phase 1 passed — PLAN.md not yet generated)
═══════════════════════════════════════════════════════════════════
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Story directory not found | List available stories in MM/Epic_Stories/ |
| GitHub MCP unavailable | Note PR status as "unable to verify — check GitHub manually" |
| Ambiguous state (artifacts conflict) | Show what was found and explain the ambiguity |
| Multiple active stories | Show condensed status for all, offer to drill into one |
