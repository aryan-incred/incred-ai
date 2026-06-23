---
name: mm-enrich
description: |
  Enriches the MM Knowledge Base and PRFAQs from any source — Slack threads, email threads, meeting notes, PDFs, or explicit pastes. Writes structured markdown entries to MM/Knowledge_Base/ or MM/PRFAQs/ and keeps index.md current so mm-story and mm-blueprint can find context without reading every file. Use this skill whenever anyone on the MM team wants to add knowledge to the KB, save a decision, log a business rule, record a retrospective, or enrich a PRFAQ. Run /mm-enrich --help for a guided onboarding on what to enrich and where. Invoke proactively whenever a RESOLVE-IN-PLAN item is confirmed during mm-story or mm-blueprint.
command: mm-enrich
trigger: |
  - Anyone says "add to KB", "save this decision", "we agreed that", "the rule is"
  - User runs /mm-enrich --help to understand what and how to enrich
  - A RESOLVE-IN-PLAN item is confirmed during mm-story or mm-blueprint
  - Pasted meeting notes, Slack thread, or email thread needs to be saved
  - Claude detects useful domain knowledge during any pipeline phase
kind: skill
visibility: project
---

## Memory

Follows shared memory protocol: `~/.claude/skills/shared/memory-protocol.md`

Memory location: `~/.claude/skills/mm-enrich/memory/`

Run M0 → M2 at start (skip if --help). Run M3 → M5 at end.

Key things to learn:
- Does user always commit to main → default to main
- Does user always approve batch → skip per-item review, go straight to batch approval
- Does user always use --slack → surface as default suggestion
- Which KB files the user enriches most → pre-load those on future runs

---

## INTERACTION PROTOCOL

**Identify the caller (run once at start — skip if --help):**
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
Role is recorded in ENRICHMENT-LOG.md as the approver. **Role never blocks anyone from enriching.**

**All choices use numbered options — never yes/no:**
- Approve / reject: `[1] Approve  [2] Reject  [3] Comment first`
- Per-item: `[1] Add this  [2] Edit first  [3] Skip`
- Batch: `[1] Approve all  [2] Select (e.g. "1,3")  [3] Skip all`
- Contradiction: `[1] Use latest  [2] Override — I'll specify`
- Duplicate: `[1] Proceed anyway  [2] Cancel  [3] Update existing entry`

---

## --help: ENRICHMENT GUIDE

When `--help` flag is passed (or user asks "how do I enrich", "what can I add"), skip all other steps and show this guide:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MM KNOWLEDGE ENRICHMENT GUIDE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WHAT CAN I ENRICH?
──────────────────
The MM Knowledge Base (KB) stores operational knowledge — how
the domain works today. PRFAQs store strategic intent — why
we're building something new.

  ONE-QUESTION TEST:
  "Is this about HOW the domain behaves (rules, values, contracts)?
   Or WHY we're building something new (initiative, customer problem)?"
  → HOW = Knowledge Base
  → WHY = PRFAQ

WHERE DOES MY CONTENT GO?
──────────────────────────
  business-rules.md     → Rules, limits, thresholds
                           e.g. "NACH retries: max 3 per calendar day"
                           e.g. "Minimum payout amount: ₹1"

  field-vocabulary.md   → Enum values, field names, status flows
                           e.g. "Payment Status: INITIATED → PROCESSING
                                 → SETTLED → FAILED"
                           e.g. "Mandate Type: CREATE / REVOKE / UPDATE"

  integrations.md       → External service contracts, API behaviour
                           e.g. "HDFC NACH max transaction: ₹10L"
                           e.g. "Janus gateway timeout: 30s"

  product-decisions.md  → Agreed decisions on in-scope work
                           e.g. "Use NACH over UPI for recurring mandates
                                 — decided 2026-06-10 by Aryan + Sunil"

  MM/PRFAQs/            → New initiative framing (WHY we're building)
                           e.g. "PRFAQ for real-time payout dashboard"
                           e.g. "Initiative: reduce settlement failures by 40%"

  retrospectives/       → Lessons from completed epics
                           e.g. "Epic 3 slowed by missing NACH enum values
                                 in KB — add enums before story writing next time"

HOW DO I ENRICH?
────────────────
  FROM PASTED TEXT:     /mm-enrich
                        Paste meeting notes, a decision, or a rule
                        when prompted

  FROM SLACK:           /mm-enrich --slack [thread-url]
                        Fetches the thread via Slack MCP

  FROM EMAIL:           /mm-enrich --email [thread-id]
                        Fetches the thread via Gmail MCP

  FROM A FILE:          /mm-enrich --file [local-path]
                        Reads a local .md, .txt, or .pdf

  SAVE A DECISION:      /mm-enrich --resolve [Epic_ID] [Story_ID]
                        Saves a confirmed RESOLVE-IN-PLAN value
                        from an active story

  ENRICH A PRFAQ:       /mm-enrich --prfaq
                        Routes to MM/PRFAQs/ instead of Knowledge_Base/

  RETROSPECTIVE:        /mm-enrich --retro [Epic_ID]
                        Routes to Knowledge_Base/retrospectives/

WHAT HAPPENS AFTER ENRICHMENT?
───────────────────────────────
  1. Your content is written to the right KB file
  2. index.md is updated — mm-story and mm-blueprint read
     this to find KB context without reading every file
  3. ENRICHMENT-LOG.md is updated with what was added and by whom
  4. Changes are committed (you approve before anything is pushed)

TIPS FOR GOOD ENRICHMENT
─────────────────────────
  • Enrich BEFORE writing stories — a richer KB means fewer
    RESOLVE-IN-PLAN blockers mid-story
  • After vendor meetings: /mm-enrich --slack or --email
    immediately while context is fresh
  • After sprint retro: /mm-enrich --retro [Epic_ID]
  • When in doubt about WHERE something goes, just paste it
    and mm-enrich will classify and route for your approval

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ready to enrich? Tell me what you have, or use one of the
flags above to get started.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After showing --help, wait for user to provide content or a flag. Do not proceed automatically.

---

## KB & PRFAQ STRUCTURE

```
MM/Knowledge_Base/
├── index.md                  ← master index — always read first, always update last
├── business-rules.md         ← domain rules, limits, thresholds
├── field-vocabulary.md       ← enums, field definitions, status values
├── integrations.md           ← external service contracts, API details
├── product-decisions.md      ← agreed product decisions with rationale
├── personas.md               ← team members, roles, Slack handles
├── ENRICHMENT-LOG.md         ← audit trail of all additions
└── retrospectives/           ← lessons learned per epic

MM/PRFAQs/
└── [initiative-name].md      ← strategic initiative framing (WHY we build)
```

**`index.md` is the entry point for mm-story and mm-blueprint.** It must be updated in every enrichment session — a stale index makes the KB invisible to the pipeline.

---

## ROUTING DECISION

**The one-question test before routing anything:**

> *"Is this content about HOW the domain behaves (rules, values, contracts, decisions on in-scope work) — or about WHY we're building a new initiative (customer problem, strategic vision, press release framing)?"*

| Answer | Destination |
|--------|-------------|
| HOW the domain behaves | `Knowledge_Base/` → correct file per type |
| WHY a new initiative exists | `PRFAQs/[initiative].md` |
| Lesson from a completed epic | `Knowledge_Base/retrospectives/[Epic_ID].md` |

**Edge cases:**
- "We decided to use NACH instead of UPI" → `product-decisions.md` (KB) — it's a decision on in-scope work, not an initiative framing
- "We want to build a real-time payout dashboard because customers can't see payment status" → `PRFAQs/` — this is initiative framing with a customer problem
- A vendor API spec → `integrations.md` (KB) — it's a contract, not an initiative

When unsure, show both options and let the stakeholder decide:
```
This content could go to:
  [1] product-decisions.md (KB) — it's a clarification on in-scope work
  [2] PRFAQs/payout-dashboard.md — it's framing for a new initiative
```

---

## STEP 0: DOMAIN GUARD + DUPLICATE SOURCE CHECK

**Domain guard:** If `--resolve` is passed with a non-MM ID → stop:
```
❌ mm-enrich: RESOLVE-IN-PLAN items must belong to MM epics (MM-Epic-N).
   No changes were made.
```

**Duplicate source check** (for `--slack`, `--email`, `--file` only):

Read `MM/Knowledge_Base/ENRICHMENT-LOG.md` and match:

| Mode | Match against |
|------|---------------|
| `--slack [url]` | Slack URL in Source column |
| `--email [id]` | Thread ID or subject in Source column |
| `--file [path]` | Filename in Source column |

If match found:
```
⛔  DUPLICATE SOURCE — no changes made

   Already enriched on [date] by [person]:
   Sections: [list from log]

   [1] Proceed — has new info not captured last time
   [2] Cancel — KB is already up to date
   [3] Update — newer version with changed facts
```

---

## STEP 1: FETCH CONTENT

| Flag | How |
|------|-----|
| *(none — paste)* | Use pasted text directly |
| `--slack [url]` | Slack MCP `slack_read_thread` — chronological, preserve timestamps + authors |
| `--email [id]` | Gmail MCP `get_thread` — full chain, chronological |
| `--file [path]` | Read file directly; if unreadable ask user to paste sections |
| `--resolve [Epic] [Story]` | Skip to STEP 3 — value already confirmed |
| `--prfaq` | Fetch then route to `MM/PRFAQs/` |
| `--retro [Epic_ID]` | Fetch then route to `Knowledge_Base/retrospectives/[Epic_ID].md` |

---

## STEP 2: EXTRACT + RESOLVE CONTRADICTIONS

Scan for actionable knowledge: decisions ("we agreed", "the rule is"), definitions ("status values are", "enum is"), contracts ("the API returns", "limit is").

For each signal: note what, who said it, when, and which KB file it belongs to.

When the same entity has conflicting values, show contradiction and confirm:
```
⚠️  CONTRADICTION — auto-resolved (latest wins)

  Earlier (2026-06-10 @aryan.maurya): PENDING → PROCESSING → COMPLETE
  Later   (2026-06-18 @sunil.kumar):  INITIATED → PROCESSING → SETTLED → FAILED

  Using: INITIATED → PROCESSING → SETTLED → FAILED

  [1] Use latest     [2] Override — I'll specify
```

---

## STEP 3: CLASSIFY & ROUTE — BATCH REVIEW

Apply the routing decision (see above). Present all facts together before writing any:

```
Found [N] items. Review before saving:

  ① → field-vocabulary.md      [Payment Status Enum]
  ② → business-rules.md        [NACH retry limit = 3]
  ③ → integrations.md          [HDFC NACH max = ₹10L]
  ④ → product-decisions.md     [Reconciliation at 2am IST]

  [1] Approve all     [2] Select specific (e.g. "1,3")     [3] Skip all
```

---

## STEP 4: APPROVAL GATE — Per entry

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — KB Addition
Destination: Knowledge_Base/field-vocabulary.md
Section:     ## Payment Status Enum

## Payment Status Enum
> **Summary:** INITIATED → PROCESSING → SETTLED → FAILED

Valid transitions:
- INITIATED: payment instruction created
- PROCESSING: sent to gateway, awaiting response
- SETTLED: funds confirmed transferred
- FAILED: terminal failure — retry not automatic

**Source:** Slack thread #payments-infra | 2026-06-18 | Approved by: Sunil Kumar

  [1] Add this     [2] Edit first     [3] Skip
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## KB Entry Format

```markdown
## [Fact Title]
> **Summary:** [one sentence — what a PM or dev needs to know immediately]

[Detailed content — rules, values, context, edge cases]

**Source:** [source type] | [date] | Approved by: [name]
```

If section exists: update summary + detail, append new source line (never delete old source lines).
If section is new: append to the correct file.

---

## STEP 5: WRITE + UPDATE INDEX

After all approved entries are written, update `MM/Knowledge_Base/index.md`:

```markdown
# MM Knowledge Base Index
_Last updated: [ISO 8601 timestamp]_

## Quick Lookup
| Topic | File | Summary |
|-------|------|---------|
| Payment Status Enum | field-vocabulary.md | INITIATED → PROCESSING → SETTLED → FAILED |
| NACH Retry Limit | business-rules.md | Max 3 retries per calendar day |
```

Add new rows for new entries. Update summary + timestamp for updated entries.

Then append to `MM/Knowledge_Base/ENRICHMENT-LOG.md`:
```
| [date] | [file] | [section] | [source] | [approved-by] |
```

---

## STEP 6: COMMIT GATE

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Commit KB Updates

Files changed: [list]
index.md: updated ✅
ENRICHMENT-LOG.md: appended ✅

  [1] Commit to main     [2] Commit to current branch     [3] Skip commit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

```bash
git add MM/Knowledge_Base/ MM/PRFAQs/
git commit -m "kb: enrich [N] entries — [topic summary] ([approved-by])"
git push origin [branch]
```

---

## STEP 7: SIGN-OFF

```
✅ MM KB ENRICHMENT COMPLETE

  Entries added/updated: [N]
  Files modified: [list]
  index.md: updated ✅
  ENRICHMENT-LOG.md: appended ✅

  Available to mm-story and mm-blueprint on next run via index.md.
```

---

## Proactive Hook (from pipeline skills)

When mm-story or mm-blueprint resolves a `RESOLVE-IN-PLAN:` item:
```
💡 Resolved: Payment Status Enum = INITIATED → PROCESSING → SETTLED → FAILED
   Save to KB so future stories skip this blocker?
   [1] Save to KB     [2] Skip for now
```
If yes → jump to STEP 3 with the confirmed value.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Slack MCP unavailable | Ask user to paste thread content |
| Gmail MCP unavailable | Ask user to paste email content |
| File unreadable | Ask user to paste relevant sections |
| KB file missing | Create it with section heading, then append |
| index.md missing | Create fresh — scan existing KB files to populate |
| Commit fails | Show manual git commands; files are already written locally |
