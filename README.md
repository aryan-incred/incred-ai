# InCred AI — Claude Code Skills & Agents

Claude Code skills and agents for InCred engineers. Includes shared engineering tools (codebase exploration, KB generation) and MM team SDLC skills for the Money Movement team.

---

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash
```

No flags = installs the **story creation preset** (default). Restart Claude Code and run `/reload-skills` to activate.

---

## Install Options

### Presets

| Preset | Who it's for | What it installs |
|--------|-------------|-----------------|
| `story` | MM PMs | `mm-story` `mm-enrich` + 3 agents |
| `pipeline` | MM Developers, QA, Tech Leads | `mm-story` + full SDLC pipeline + 7 agents |
| `all` | Full team setup | Everything |

```bash
# Story creation preset (MM PMs)
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset story

# Full SDLC pipeline (MM Developers / Tech Leads / QA)
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset pipeline

# Everything
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset all
```

### Individual Skills & Agents

```bash
# Single skill
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill mm-story

# Multiple skills
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill mm-story,mm-enrich

# Skills + agents
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill mm-story --agent mm-enricher,mm-scoping-analyst

# Shared engineering tools only (any InCred engineer)
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill code-explorer,kb-merge,claude-publish

# See everything available
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --list
```

### Updating

```bash
# Update everything silently
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset all --update

# Update a specific skill (prompts if file changed)
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill mm-story --update
```

---

## Skills

### Shared Engineering Tools

For any InCred engineer — not team-specific.

| Skill | Command | What it does |
|-------|---------|--------------|
| `code-explorer` | `/code-explorer` | Explores any InCred microservice from inside its directory. Produces `SERVICE-KB.md` (human-readable, 9 sections) and `.service-kb/index.json` (machine-readable). Uses GitNexus for AST analysis + targeted file reads. Self-improves after each run. |
| `kb-merge` | `/kb-merge` | Assembles a unified domain KB from all `index.json` files created by `/code-explorer`. Produces `api-registry.md`, `integrations.md` (cross-service impact table), `data-models.md`, `services.md`, and an HTML architecture overview. Never re-reads source code. |
| `claude-publish` | `/claude-publish` | Publishes local skill/agent edits to this GitHub repo. Auto-detects changed files, shows diffs, waits for approval. Supports `--skill`, `--agent`, `--all`, `--dry-run`. |

### MM Story Skills (PM-facing)

For Money Movement PMs. All story work lives in one skill — `/mm-story`.

| Skill | Command | What it does |
|-------|---------|--------------|
| `mm-story` | `/mm-story --help` | **All PM story work in one skill.** Create epics, add/edit stories, run checklist review, explain gap reports, submit to pipeline, revise from PR comments. Run `--help` for the full guide. |
| `mm-enrich` | `/mm-enrich` | Enriches the MM Knowledge Base from any source — Slack threads, emails, meeting notes, paste. Run `/mm-enrich --help` for routing guide (what goes to KB vs PRFAQ). |

**`mm-story` flags at a glance:**

```bash
/mm-story                              # create new epic
/mm-story --add   MM-Epic-5            # add story to existing epic
/mm-story --edit  MM-Epic-5-Story-3A   # edit story (pre-pipeline only)
/mm-story --review   MM-Epic-5 MM-Epic-5-Story-3A  # checklist check, read-only
/mm-story --check-gap MM-Epic-5 MM-Epic-5-Story-3A  # explain GAP-REPORT.md
/mm-story --submit   MM-Epic-5 MM-Epic-5-Story-3A  # Phase 1 formal gate
/mm-story --revise   MM-Epic-5 MM-Epic-5-Story-3A  # update from PR comments
/mm-story --help                       # full PM workflow guide
```

### MM Pipeline Skills (Developer / Tech Lead / QA)

For Money Movement engineers running the SDLC pipeline. Phases 2–8.

| Skill | Command | Phase | What it does |
|-------|---------|-------|--------------|
| `mm-blueprint` | `/mm-blueprint` | 2 | Generates `PLAN.md` on the feature branch (Section 1: PM scope, Section 2: technical changes, Section 3: QA scenarios). Reads KB and uses GitNexus. If story is incomplete, creates `GAP-REPORT.md` for PM to fix. |
| `mm-approve-plan` | `/mm-approve-plan --pm` or `--tech` | 2 | PM approves Section 1, Tech Lead approves Section 2. Posts formal GitHub PR review. Both must approve before Phase 3 unlocks. |
| `mm-tdd` | `/mm-tdd` | 3 & 4 | Phase 3 Red: failing tests from PLAN.md Section 3. Phase 4 Green: minimal code to pass them. Human approval before each commit. Generates `BUILD-EVIDENCE.md`. |
| `mm-ship` | `/mm-ship --qa / --runway / --prod` | 5–7 | Promotes through environments in order. Conflict check before every PR. `@mm-qa-gatekeeper` runs tests at each gate. Generates `QA-EVIDENCE.md`. |
| `mm-telemetry` | `/mm-telemetry` | 8 | Posts Slack success summary, updates HTML metrics dashboard, triggers re-index. |
| `mm-status` | `/mm-status` | All | Read-only pipeline inspector. Shows current phase, what's done, what's blocking, what to run next. |

---

## Agents

Agents are specialist subagents invoked automatically by skills during pipeline phases.

### MM PM Agents

| Agent | Invoked by | Role |
|-------|-----------|------|
| `@mm-enricher` | `mm-enrich` | Multi-source KB enrichment sessions — processes Slack threads, emails, PDFs together |
| `@mm-scoping-analyst` | `mm-story --submit` | Runs structured Sign-Off Checklist, produces specific PM action items |
| `@mm-pm-reviewer` | `mm-approve-plan --pm` | Conversational PM review companion — story review, gap explanation, Section 1 approval |

### MM Engineering Agents

| Agent | Invoked by | Role |
|-------|-----------|------|
| `@mm-codebase-planner` | `mm-blueprint` | GitNexus call chain tracing, populates PLAN.md Section 2 |
| `@mm-tech-reviewer` | `mm-approve-plan --tech` | Tech Lead review companion — Section 2 review and approval |
| `@mm-test-architect` | `mm-tdd` | Writes failing tests from PLAN.md Section 3 (Phase 3 Red) |
| `@mm-implementer` | `mm-tdd` | Writes minimal code to make tests pass (Phase 4 Green) |
| `@mm-qa-gatekeeper` | `mm-ship` | Runs regression, smoke, and p95 tests at each environment gate |
| `@mm-release-herald` | `mm-telemetry` | Composes the Slack success post after prod deploy |

---

## Role-Based Install Guide

### PM / Product Manager (MM team)
```bash
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset story
```
Installs `mm-story` + `mm-enrich` + 3 PM agents.

**Start with:** `/mm-story --help` for the full PM workflow guide.

### Developer (MM team)
```bash
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset pipeline
```
Installs full MM pipeline + 7 engineering agents.

**Start with:** `/mm-status` to see where a story is, `/mm-blueprint` when PM has submitted.

### Tech Lead (MM team)
```bash
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill mm-approve-plan,mm-status --agent mm-tech-reviewer,mm-codebase-planner
```

### QA Engineer (MM team)
```bash
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill mm-ship,mm-status --agent mm-qa-gatekeeper
```

### Any InCred Engineer (shared tools only)
```bash
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill code-explorer,kb-merge,claude-publish
```
Codebase exploration and KB generation — no MM team dependency.

---

## Self-Learning Skills

All skills in this repo follow the shared memory protocol (`claude/shared/memory-protocol.md`). Over time each skill learns:

- **User preferences** — which approval gates you always approve, which steps you always skip
- **Run efficiency** — which reads return nothing useful for your codebase
- **Self-improvement** — after 5 runs, proposes patches to reduce friction further

Memory is stored per-user, per-skill at `~/.claude/skills/[skill]/memory/`. Nothing is shared between users.

---

## After Installing

1. Restart Claude Code
2. Run `/reload-skills` to activate
3. Test: `/mm-story --help` (MM PMs) or `/code-explorer` (any engineer)

---

## Publishing Updates

If you have edit access, use `/claude-publish` to push local changes:

```bash
/claude-publish              # detect what changed vs remote
/claude-publish --skill mm-story   # publish specific skill
/claude-publish --all --dry-run    # preview without pushing
/claude-publish --all --update     # force update everything
```

Config saved at `~/.claude/publish-config.json` after first run.

---

## Repo Structure

```
incred-ai/
├── install.sh
├── README.md
└── claude/
    ├── shared/
    │   └── memory-protocol.md        ← self-learning protocol for all skills
    ├── skills/
    │   ├── code-explorer/            ← shared: microservice KB generator
    │   ├── kb-merge/                 ← shared: domain KB assembler
    │   ├── claude-publish/           ← shared: publish skills to this repo
    │   ├── mm-story/                 ← MM PM: all story work (create/review/submit/etc)
    │   ├── mm-enrich/                ← MM PM: Knowledge Base enrichment
    │   ├── mm-blueprint/             ← MM dev: Phase 2 blueprinting
    │   ├── mm-approve-plan/          ← MM PM+TL: PLAN.md approval (--pm / --tech)
    │   ├── mm-tdd/                   ← MM dev: Phase 3 & 4 TDD
    │   ├── mm-ship/                  ← MM dev: Phase 5–7 environment promotion
    │   ├── mm-telemetry/             ← MM dev: Phase 8 telemetry
    │   └── mm-status/                ← MM all: pipeline inspector
    └── agents/
        ├── mm-enricher.md            ← PM: multi-source enrichment
        ├── mm-scoping-analyst.md     ← PM: story validation (--submit)
        ├── mm-pm-reviewer.md         ← PM: review companion
        ├── mm-tech-reviewer.md       ← TL: technical review companion
        ├── mm-codebase-planner.md    ← Dev: GitNexus analysis
        ├── mm-test-architect.md      ← Dev: Phase 3 tests
        ├── mm-implementer.md         ← Dev: Phase 4 code
        ├── mm-qa-gatekeeper.md       ← QA: environment test gates
        └── mm-release-herald.md      ← Dev: Slack post after prod
```

---

*Maintained by InCred Engineering — contributions via `/claude-publish`*
