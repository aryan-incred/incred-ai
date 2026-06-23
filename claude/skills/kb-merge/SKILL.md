---
name: kb-merge
description: Merges multiple service SERVICE-KB.md files into a unified domain knowledge base. Run from any directory — reads service locations from domain-map.json. Reads only .service-kb/index.json from each service (never re-reads source code). Produces services/ (per-service profile cards), api-registry.md, integrations.md (with impact analysis table), data-models.md (including DynamoDB requestType registry), and architecture-overview.html. Preserves manually maintained KB files. Supports --domain MM (default) and --service <name> for single-service refresh. Prints work summary and cost pointer at the end. Use after running /code-explorer on each service.
---

# KB Merge

Synthesizes per-service `.service-kb/index.json` files into a domain-level common knowledge base.

Architecture references (read as needed):
- Service registry: `/Users/aryankumarmaurya/Incred-Engineers/architecture/registry/services.yaml`
- Bounded contexts: `/Users/aryankumarmaurya/Incred-Engineers/architecture/registry/bounded-contexts.yaml`

---

## Invocation

```bash
/kb-merge                           # merge all services for default domain (MM)
/kb-merge --domain MM               # explicit domain
/kb-merge --status                  # show exploration status, no writes
/kb-merge --service paymentservice  # refresh one service's contribution only
```

---

## Phase 0 — Setup & Status

**Step 1: Load domain config**
```bash
cat ~/.claude/skills/generate-pr/domain-map.json
```

For `--domain MM`, read:
- `MM.services_root` — base path for all service repos
- `MM.services.mm_owned` — services owned by MM
- `MM.services.mm_uses` — ancillary/core services MM calls
- `MM.services.shared_core` — core services (all teams use)
- `MM.services.shared_infra` — infra services (Dynamo, Api, document-service)
- `MM.kb_dir` — where to write the common KB
- `MM.protected_files` — files never to overwrite

All service categories together = the full list to check.

**Step 2: Check each service for .service-kb/index.json**
```bash
ls <services_root>/<folder>/.service-kb/index.json 2>/dev/null && echo "found" || echo "missing"
```

**Step 3: Print status**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MM Services — Exploration Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MM-Owned:
  ✅ ckyc-service           explored 2026-06-22  (ancillary · kyc_verification)
  ❌ lms-connector-service  not explored

MM Uses (Ancillary/Core):
  ✅ paymentservice         explored 2026-06-22  (ancillary · loan_repayment)
  ❌ artifact-service       not explored
  ❌ task-service           not explored

Shared Core:
  ❌ customer-service       not explored
  ❌ application-service    not explored

Shared Infra:
  ❌ Api                    not explored  (monolith — partial migration)
  ❌ Dynamo                 not explored
  ❌ document-service       not explored

Ready to merge: 2 of 10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1] Merge available services now (2 of 10)
[2] Stop — I'll run /code-explorer on more services first
[3] Merge specific services (I'll name them)
```

If `--status`: print table and stop.  
If `--service <name>`: process only that folder, skip table prompt.

---

## Phase 1 — Read index.json Files

For each service with `.service-kb/index.json`:
```bash
cat <services_root>/<folder>/.service-kb/index.json
```

Store all as `SERVICE_INDEXES[]`. These are compact JSON — reading all is low token cost.

If an index.json is malformed:
```
<folder>/.service-kb/index.json is malformed or unreadable.
[1] Re-run /code-explorer on <folder> first, then come back
[2] Skip this service for this merge
[3] Show me the file to fix it
```

---

## Phase 2 — Write Common KB Files

Output directory: `MM.kb_dir` from domain-map.json.

Before overwriting any existing file:
```
<filename> already exists.
[1] Overwrite with new synthesized data
[2] Show diff first
[3] Skip this file
```

**Never touch these files** (manually maintained):
- `compliance.md`
- `field-vocabulary.md`
- `personas.md`
- `EPIC-REGISTRY.md`
- `ENRICHMENT-LOG.md` (append only — see Phase 4)

---

### 2.1 `services/` — Per-Service Profile Cards

Create `MM/Knowledge_Base/services/` if it doesn't exist.

For each service in SERVICE_INDEXES, write `services/<folder-name>.md`:

```markdown
# <SERVICE_NAME>

**Business Purpose:** <from index.json .business_purpose>
**Layer:** <layer> · **Bounded Context:** `<bounded_context>`
**Team:** <team> · **Migration:** <migration_status>% from monolith
**Tech:** <tech_stack> · <framework>
**DB Pattern:** <db_access_pattern>
**Repository:** `<repo_path>`
**Architecture Doc:** [<layer>/<doc>](<architecture_doc>)
**Last Explored:** <explored_at>

> Full dependency contracts with curl examples: `<repo_path>/SERVICE-KB.md`

## Upstream Callers
<upstream_callers list, or "No callers detected">

## Own APIs (<count>)
| Method | Path | Version | Description | Called By |
|--------|------|---------|-------------|-----------|
<rows from own_apis[]>

## Dependencies (<count>)
| Dependency | Type | Key Endpoints / Operations |
|------------|------|---------------------------|
<rows from dependencies[]>

## Data Resources
| Type | Table / Resource | Primary Key | Access Pattern | requestTypes / Endpoints |
|------|-----------------|-------------|----------------|--------------------------|
<rows from data_resources[]>

## Violations Detected
<if violations[] is non-empty, list with ⚠️ and recommend /arch-review>
<if empty: "None detected during exploration">

## Known Gaps
<gaps[] list, or "None">
```

---

### 2.2 `api-registry.md`

File: `MM/Knowledge_Base/api-registry.md`

```markdown
# MM API Registry

_Last updated: <date> | Services: <N> of 10 explored | Total endpoints: <count>_

> Quick-reference for all MM-domain endpoints. Full contracts (curl examples, auth, failure modes): each service's `SERVICE-KB.md`.

## By Service

### <SERVICE_NAME> (<layer>)
| Method | Path | Version | Description | Called By | Auth |
|--------|------|---------|-------------|-----------|------|
<rows from own_apis[]>

<repeat per service>

---

## Alphabetical Index

| Path | Method | Service | Description |
|------|--------|---------|-------------|
<all endpoints sorted alphabetically by path>
```

---

### 2.3 `integrations.md`

The most important file for `/generate-pr` impact analysis. File: `MM/Knowledge_Base/integrations.md`

```markdown
# MM — Integration Map

_Last updated: <date> | Built from <N> explored services_

> **Primary use**: When changing a service, check this file to find all downstream consumers before writing code.

## Cross-Service Impact Table

_"If I change SERVICE_A, which services must I check?"_

| Service Changed | Callers That Depend On It | Endpoints They Use |
|----------------|--------------------------|-------------------|
<built by inverting the dependency map:
 for each service S, find all other services that have S in their dependencies[]
 list the endpoints they call>

## Internal Integrations (MM service → MM service)

| Caller | Called Service | Endpoints Used | Auth | Type |
|--------|----------------|----------------|------|------|
<rows from dependencies[] where the called service is also in the MM service list>

## External Integrations (MM service → Outside InCred)

| MM Service | External System | Via (Janus / Direct) | Endpoints / Operations | Auth |
|------------|----------------|----------------------|------------------------|------|
<rows from dependencies[] where the called service is not in MM list
 note if it goes through Janus (correct) or direct (violation)>

## Shared Core & Infrastructure

| MM Service | Shared Service | Layer | What MM Uses It For |
|------------|---------------|-------|---------------------|
<rows for application-service, customer-service, Dynamo, document-service, Api>

## Monolith Coupling (Migration Debt)

| Service | Monolith Dependency | What Remains on Monolith |
|---------|-------------------|--------------------------|
<rows from services with migration_status < 100 and monolith_dependency set>
```

---

### 2.4 `data-models.md`

File: `MM/Knowledge_Base/data-models.md`

```markdown
# MM — Data Models

_Last updated: <date>_

## Data Resources by Service

| Service | Type | Table / Resource | Primary Key | Access Pattern |
|---------|------|-----------------|-------------|----------------|
<rows from all data_resources[]>

## DynamoDB requestType Registry

_InCred rule: all DynamoDB access goes through Dynamo Utility (HTTP POST with requestType) or DBC connectors — never direct AWS SDK_

| Service | requestType / DBC Endpoint | Operation | Description |
|---------|---------------------------|-----------|-------------|
<rows from data_resources[].requestTypes[] across all services>

## Bounded Context — Data Ownership

| Entity | Canonical Owner | Bounded Context | Rule |
|--------|----------------|----------------|------|
| application | application-service | application_lifecycle | SOLE WRITER — all products |
| customer | customer-service | customer_profile | SOLE WRITER — all products |
| task lifecycle | task-orchestration-service | workflow_orchestration | SOLE WRITER of task state |
<add any other ownership rules found>

## Storage Distribution

| Type | Services Using It | Notes |
|------|-----------------|-------|
| DynamoDB (via Dynamo Utility) | <list> | HTTP requestType pattern |
| DynamoDB (via DBC connector) | <list> | Named endpoint pattern |
| Redis | <list> | Cache / session |
| S3 (via document-service) | <list> | All file storage |
| MySQL | <list> | MDM master data, retry queues |
| SQS | <list> | Async receipt queues |
| Elasticsearch | <list> | Search indexes |
```

---

### 2.5 `services.md` — Quick Reference Index

File: `MM/Knowledge_Base/services.md`

```markdown
# MM Services

_Full profiles: `services/` directory. Full dependency contracts: each repo's `SERVICE-KB.md`._

| Service | Layer | Bounded Context | Purpose | Tech | APIs | Explored |
|---------|-------|----------------|---------|------|------|----------|
<one row per service in all categories, link to services/<folder>.md>

## Services Not Yet Explored (<N>)

| Folder | Category | Next Step |
|--------|----------|-----------|
<list with: cd ~/Incred-Engineers/<folder> && /code-explorer>
```

---

## Phase 3 — architecture-overview.html

File: `MM/Knowledge_Base/architecture-overview.html`

Standalone HTML, no external dependencies. InCred brand colors: `#E8500A` (orange), `#1A1A2E` (navy), `#F7F8FA` (background). Light mode — no dark backgrounds on content blocks.

**Structure:**

1. **Header** — "MM Architecture Overview · <date> · <N> services"

2. **Summary bar** — 4 stat cards:
   - Total Services Explored / Total
   - Total API Endpoints
   - Total Internal Integrations
   - Violations Detected

3. **Service grid** — one card per explored service:
   - Name + layer badge (navy=core, amber=ancillary, teal=domain, slate=bff)
   - Business purpose (one sentence)
   - Tech stack pill badges
   - API count · Dependency count · Migration %
   - Link to SERVICE-KB.md (relative path)
   - ⚠️ badge if violations found

4. **Integration matrix** — expandable table showing which services call which (collapse if > 15 rows)

5. **Violations panel** — amber alert if any violations detected across services, listing each with the service name and type

6. **Unexplored panel** — services not yet explored, with the `/code-explorer` command for each

**Animations:** fadeInUp on load (staggered), expand/collapse on integration table, smooth transitions.

---

## Phase 4 — Update ENRICHMENT-LOG.md

Append to `MM/Knowledge_Base/ENRICHMENT-LOG.md` (never overwrite, only append):

```markdown
| <date> | Knowledge_Base/services/<name>.md | Service profile card | explicit | /code-explorer + /kb-merge | <current user or "automated"> |
```

One row per service updated. One row for each common KB file written.

---

## Phase 5 — Completion Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ KB Merge — MM domain complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Services merged: <N> of 10
  MM-Owned:     ✅ <list>  ⏭️  <skipped>
  MM-Uses:      ✅ <list>  ⏭️  <skipped>
  Shared Core:  ✅ <list>  ⏭️  <skipped>
  Shared Infra: ✅ <list>  ⏭️  <skipped>

Files written:
  ✅ services/    (<N> profile cards)
  ✅ api-registry.md       (<N> endpoints)
  ✅ integrations.md       (<N> internal · <N> external · <N> monolith deps)
  ✅ data-models.md        (<N> resources · <N> requestTypes)
  ✅ services.md           (index)
  ✅ architecture-overview.html
  ✅ ENRICHMENT-LOG.md     (<N> rows appended)

Cross-service impact (key findings):
  application-service is called by: <list>
  customer-service is called by: <list>
  Dynamo is used by: <list>

Violations across all services (<N> total):
  <service>: <violation type> — run /arch-review <path> for full audit

Unexplored (<N>): <list>
  → cd ~/Incred-Engineers/<folder> && /code-explorer

💰 Work done: <N> index.json reads · <N> file writes
   Actual cost: check the statusline at the bottom of your terminal.

Next:
  • Open MM/Knowledge_Base/architecture-overview.html in a browser
  • /generate-pr Phase 2 now queries api-registry.md + integrations.md
    instead of reading service source code
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Behavioral Guidelines

1. **Never read service source code.** Only `.service-kb/index.json` and config files. If you need more depth, tell the user to run `/code-explorer` on that service first.
2. **Protected files are sacred.** `compliance.md`, `field-vocabulary.md`, `personas.md`, `EPIC-REGISTRY.md` — never write to these.
3. **ENRICHMENT-LOG.md is append-only.** Never truncate or rewrite it.
4. **Ask before overwriting.** Any existing KB file prompts a diff-or-skip choice.
5. **Partial merge is valid.** Document clearly what's missing. Don't block on unexplored services.
6. **Impact table is mandatory.** The cross-service impact table in integrations.md is the single most important output — it's what prevents silent breakage during `/generate-pr` Phase 4.
7. **Violations surface to the overview.** Any violation found in any `index.json` appears in the HTML overview's violations panel.
8. **Shared services get full treatment.** `Api`, `Dynamo`, `document-service` are in the KB just like owned services — MM calls them and needs to know the contracts.
