# Shared Memory Protocol
# Referenced by all MM skills. Do not duplicate this inline — always reference it.

## Purpose

Every skill that follows this protocol gets smarter over time. It learns two things:
1. **User preferences** — what a specific person always does the same way (so we stop asking)
2. **Run efficiency** — which steps repeatedly waste tokens with no useful output (so we skip them)

The goal is fewer tokens per run without losing correctness. Memory never overrides human approval gates for destructive actions — it only skips friction that has proven unnecessary.

---

## Memory File Locations

```
~/.claude/skills/[skill-name]/memory/
  ├── lessons.md           ← run patterns, efficiency observations, self-improvement proposals
  └── users/
      └── [email].md       ← per-user preferences for this specific skill
```

Create these files on first write. If they don't exist yet, skip the read and proceed normally.

---

## PROTOCOL START — Run at the beginning of every skill invocation

### Step M0: Identify caller

```bash
git config user.email 2>/dev/null || echo "anonymous"
```

Store as `CALLER_EMAIL`. If anonymous, skip user memory entirely — proceed normally.

### Step M1: Load user memory (if file exists)

```
Read ~/.claude/skills/[skill-name]/memory/users/[CALLER_EMAIL].md
```

If file missing → skip, no error. If found, extract:
- `ALWAYS_APPROVE`: list of gate IDs this user always approves immediately
- `ALWAYS_SKIP`: list of steps this user always skips
- `TRUST_LEVEL`: `standard` (default) | `trusted` (user has approved 10+ gates without ever rejecting)
- `PREFERENCES`: any other noted preferences

Apply immediately:
- Gates in `ALWAYS_APPROVE` → show condensed version (file list only, no full diff)
- Steps in `ALWAYS_SKIP` → skip silently, note in sign-off tree as "(skipped — learned preference)"
- `TRUST_LEVEL: trusted` → reduce approval gate verbosity across the run

### Step M2: Load skill lessons (if file exists)

```
Read ~/.claude/skills/[skill-name]/memory/lessons.md
```

If file missing → skip, no error. If found, apply any active optimizations flagged as `ACTIVE`.

---

## PROTOCOL END — Run at the end of every skill invocation

### Step M3: Write run summary

Append to `~/.claude/skills/[skill-name]/memory/lessons.md`:

```markdown
## [ISO 8601 date] · [CALLER_EMAIL] · [flags used]

Steps taken: [N]
Gates shown: [N] | Auto-skipped (learned): [N]
Useful reads: [list of files that produced actionable output]
Empty reads:  [list of files that returned nothing useful]
Steps skipped by user: [list]
Steps always approved: [list]
Observation: [one sentence — anything non-obvious about this run]
```

Only append — never overwrite. Keep the last 20 entries, trim older ones.

### Step M4: Update user memory

Read the current run summary and update `~/.claude/skills/[skill-name]/memory/users/[CALLER_EMAIL].md`:

**Increment counters:**
- If a gate was approved without hesitation 3+ times → add to `ALWAYS_APPROVE`
- If a step was skipped by the user 3+ times → add to `ALWAYS_SKIP`
- If total approved gates ≥ 10 with 0 rejections → set `TRUST_LEVEL: trusted`

**User memory file format:**
```markdown
---
email: [CALLER_EMAIL]
skill: [skill-name]
last_updated: [ISO 8601]
trust_level: standard | trusted
---

## Always Approve (skip full diff, show condensed)
- push-gate          (approved 8/8 runs)
- pr-create-gate     (approved 5/5 runs)

## Always Skip
- slack-notify       (skipped 6/6 runs)
- review-suggestion  (skipped 4/4 runs)

## Preferences
- prefers --submit directly without --review first
- never requests diff view, approves on file list alone
```

### Step M5: Self-improvement proposal (every 5 runs)

After every 5 runs, read `lessons.md` and check for recurring patterns:

- Same file repeatedly returns empty → propose removing that read from the skill
- Same step always skipped by all users → propose making it opt-in with a flag
- Same gate always approved in <3s by all users → propose condensing it by default

If a pattern appears in 3+ of the last 5 runs, generate a proposal:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 SKILL IMPROVEMENT PROPOSAL — [skill-name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Observed in 4 of last 5 runs:
  Slack notification step always skipped by all users.

Proposed change:
  Make Slack notification opt-in via --notify flag
  instead of showing the gate every run.

Apply this improvement?
  [1] Yes — update SKILL.md now
  [2] No — keep current behaviour
  [3] Remind me next time
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

On [1]: apply the patch to SKILL.md using Edit tool. Log the change in lessons.md.
On [2] or [3]: log decision, don't propose the same thing for 10 more runs.

---

## Gate Condensing Rules

When `TRUST_LEVEL: trusted` or gate is in `ALWAYS_APPROVE`:

**Standard gate (shown to new users):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Push to feature branch
Branch: feature/MM-Epic-5_MM-Epic-5-Story-3A
Files:  [story.md — 47 lines changed]
[full diff shown here]
  [1] Approve  [2] Reject  [3] Comment first
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Condensed gate (learned user):**
```
Push → feature/MM-Epic-5_MM-Epic-5-Story-3A
Files: story.md (47 lines)
  [1] Approve  [2] Show full diff first  [3] Reject
```

Full diff is always available on request — condensing just skips showing it by default.

---

## What Memory Never Does

- Never skips approval gates for `git push --delete`, `git reset --hard`, or PR creation without showing intent
- Never auto-approves a gate where the content has changed significantly from last run
- Never applies self-improvement patches without explicit user approval
- Never shares user preference data between different users
- Never stores secret values, tokens, or credentials
