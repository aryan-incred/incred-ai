# InCred AI — Claude Code Skills & Agents

Claude Code skills and agents for InCred engineers. Includes shared engineering tools (codebase exploration, KB generation) and team-specific SDLC skills for the Money Movement (MM) team.

---

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash
```

No flags = installs the **story creation preset** (default). Restart Claude Code and run `/reload-skills` to activate.

---

## Install Options

### Presets

| Preset | What it installs | Best for |
|--------|-----------------|----------|
| `story` | 6 skills + 3 agents for writing and validating MM stories | PMs, story authors |
| `pipeline` | 8 skills + 7 agents for the full MM SDLC pipeline | Developers, QA, Tech Leads |
| `all` | Everything in this repo | Full team setup |

```bash
# Story creation (PM default)
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset story

# Full MM SDLC pipeline
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset pipeline

# Everything
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset all
```

### Individual Skills & Agents

```bash
# Single skill
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill code-explorer

# Multiple skills
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill code-explorer,kb-merge

# Skills + agents together
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill mm-enrich --agent mm-enricher

# See all available skills and agents
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --list
```

### Updating

```bash
# Update everything (auto-overwrites without prompting)
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset all --update

# Update a specific skill (prompts if file has changed)
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill mm-enrich --update
```

---

## Available Skills

### Shared Engineering Tools

These skills work across all InCred teams and services.

| Skill | Command | What it does |
|-------|---------|--------------|
| `code-explorer` | `/code-explorer` | Explores any InCred microservice and produces a `SERVICE-KB.md` knowledge base for dev agents. Run from inside a service directory under `~/Incred-Engineers/`. |
| `kb-merge` | `/kb-merge` | Merges multiple `SERVICE-KB.md` files into a unified domain KB — `api-registry.md`, `integrations.md`, `data-models.md`, and an HTML architecture overview. |
| `claude-publish` | `/claude-publish` | Publishes local skill/agent edits from `~/.claude/` to this GitHub repo. Auto-detects changes, shows diffs, waits for approval. |

### MM Story Creation

For PMs and story authors on the Money Movement team.

| Skill | Command | What it does |
|-------|---------|--------------|
| `mm-story` | `/mm-story` | Creates and edits MM epics and stories following InCred standards. Run this before `/mm-analyze`. |
| `mm-enrich` | `/mm-enrich` | Adds knowledge to the MM Knowledge Base from Slack threads, emails, meeting notes, or paste. Run `/mm-enrich --help` for a guided tour. |
| `mm-review-story` | `/mm-review-story` | Runs the Sr. PM Sign-Off Checklist on a story and surfaces specific gaps. Read-only. |
| `mm-check-gap` | `/mm-check-gap` | Explains a `GAP-REPORT.md` in plain English with exact fix instructions. |
| `mm-analyze` | `/mm-analyze` | Phase 1 of the MM SDLC — validates story completeness, creates feature branch, generates gap reports. |

### MM SDLC Pipeline

For developers, QA, and Tech Leads running the full MM engineering pipeline.

| Skill | Command | Phase | What it does |
|-------|---------|-------|--------------|
| `mm-analyze` | `/mm-analyze` | 1 | Story validation, feature branch creation, gap report |
| `mm-blueprint` | `/mm-blueprint` | 2 | Generates `PLAN.md` (PM scope + technical changes + QA scenarios) |
| `mm-tdd` | `/mm-tdd` | 3 & 4 | TDD Red (failing tests) → Green (minimal passing code) |
| `mm-ship` | `/mm-ship` | 5–7 | Environment promotion: `qa → runway → prod` with evidence generation |
| `mm-telemetry` | `/mm-telemetry` | 8 | Slack success post, HTML metrics dashboard update, re-index |
| `mm-status` | `/mm-status` | All | Read-only pipeline state inspector — shows current phase and blockers |
| `mm-approve-plan` | `/mm-approve-plan` | 2 | PM and Tech Lead approve PLAN.md sections on the GitHub PR |

---

## Available Agents

Agents are specialist subagents invoked automatically by skills. Install them alongside the relevant skill.

### Shared

| Agent | Invoked by | Role |
|-------|-----------|------|
| *(none yet — shared agents coming soon)* | | |

### MM Team

| Agent | Invoked by | Role |
|-------|-----------|------|
| `@mm-enricher` | `mm-enrich` | Multi-source KB enrichment (Slack, email, PDF, meeting notes) |
| `@mm-scoping-analyst` | `mm-analyze` | Structured Sign-Off Checklist validation with PM action items |
| `@mm-pm-reviewer` | `mm-approve-plan` | Guides PMs through story review and PLAN.md Section 1 approval |
| `@mm-tech-reviewer` | `mm-approve-plan` | Guides Tech Leads through PLAN.md Section 2 review and approval |
| `@mm-codebase-planner` | `mm-blueprint` | GitNexus call chain tracing, Section 2 population |
| `@mm-test-architect` | `mm-tdd` | Writes failing tests from PLAN.md Section 3 (Phase 3 Red) |
| `@mm-implementer` | `mm-tdd` | Writes minimal code to make tests pass (Phase 4 Green) |
| `@mm-qa-gatekeeper` | `mm-ship` | Regression, integration, smoke, and p95 latency tests per environment |
| `@mm-release-herald` | `mm-telemetry` | Composes the Slack success post after prod deploy |

---

## Role-Based Install Guide

### PM / Product Manager
```bash
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset story
```
Installs: `/mm-story`, `/mm-enrich`, `/mm-review-story`, `/mm-check-gap`, `/mm-analyze`, `/code-explorer` + 3 agents.

**Start with:** `/mm-enrich --help` to understand the Knowledge Base, then `/mm-story` to write your first story.

### Developer
```bash
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset pipeline
```
Installs: Full MM pipeline skills + 7 agents + `/code-explorer` + `/kb-merge`.

**Start with:** `/mm-status` to see where a story is, or `/code-explorer` to map a service before implementation.

### Tech Lead
```bash
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill mm-approve-plan,mm-status,code-explorer,kb-merge --agent mm-tech-reviewer,mm-codebase-planner
```

### QA Engineer
```bash
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill mm-ship,mm-status --agent mm-qa-gatekeeper
```

### Any InCred Engineer (codebase tools only)
```bash
curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill code-explorer,kb-merge,claude-publish
```

---

## After Installing

1. Restart Claude Code
2. Run `/reload-skills` to activate
3. Test with `/mm-status` (MM team) or `/code-explorer` (any engineer)

---

## Publishing Updates

If you have edit access, use the `claude-publish` skill to push local changes back to this repo:

```bash
/claude-publish              # auto-detects what changed vs remote
/claude-publish --skill mm-enrich   # publish specific skill
/claude-publish --all --dry-run     # preview without pushing
/claude-publish --all --update      # force-push everything
```

First run will save config to `~/.claude/publish-config.json`.

---

## Repo Structure

```
incred-ai/
├── install.sh                        ← installer with flag support
├── README.md                         ← this file
└── claude/
    ├── skills/
    │   ├── code-explorer/            ← shared: microservice KB generator
    │   ├── kb-merge/                 ← shared: domain KB assembler
    │   ├── claude-publish/           ← shared: publish skills to this repo
    │   ├── mm-story/                 ← MM: story creation
    │   ├── mm-enrich/                ← MM: Knowledge Base enrichment
    │   ├── mm-review-story/          ← MM: story review
    │   ├── mm-check-gap/             ← MM: gap report explainer
    │   ├── mm-analyze/               ← MM: Phase 1 validation
    │   ├── mm-blueprint/             ← MM: Phase 2 blueprinting
    │   ├── mm-tdd/                   ← MM: Phase 3 & 4 TDD
    │   ├── mm-ship/                  ← MM: Phase 5–7 environment promotion
    │   ├── mm-telemetry/             ← MM: Phase 8 telemetry
    │   ├── mm-status/                ← MM: pipeline status
    │   └── mm-approve-plan/          ← MM: plan approval
    └── agents/
        ├── mm-enricher.md
        ├── mm-scoping-analyst.md
        ├── mm-pm-reviewer.md
        ├── mm-tech-reviewer.md
        ├── mm-codebase-planner.md
        ├── mm-test-architect.md
        ├── mm-implementer.md
        ├── mm-qa-gatekeeper.md
        └── mm-release-herald.md
```

---

*Maintained by InCred Engineering — contributions via `/claude-publish`*
