---
name: code-explorer
description: Explores any InCred microservice and produces a SERVICE-KB.md knowledge base that dev agents can use without reading source code. Run this skill from inside a service directory under ~/Incred-Engineers/. Reads the architecture service registry first (zero token cost), then uses GitNexus for structural analysis, then targeted reads of adapter/client files for dependency contracts with curl examples and sync anchors. Produces SERVICE-KB.md following InCred's 9-section KB standard plus .service-kb/index.json for /kb-merge. Detects InCred-specific patterns: DBC connectors, Dynamo HTTP requestType, Janus vendor gateway, Hermes notification gateway, monolith (Api) coupling. Flags bounded context violations. Supports delta update on re-run via sync anchors. Saves service facts to memory after each run. Proposes self-improvement patches to SKILL.md based on lessons learned. Proactively asks when stuck. Prints work summary + cost pointer at the end.
---

# Code Explorer

Produces `SERVICE-KB.md` for the service in the current working directory.

Architecture references (read as needed, do not load upfront):

Resolve `ARCH_ROOT` once at start of Phase 1:
```bash
ARCH_ROOT="$HOME/Incred-Engineers/architecture"
```

- Registry: `$ARCH_ROOT/registry/services.yaml`
- Bounded contexts: `$ARCH_ROOT/registry/bounded-contexts.yaml`
- KB format guide: `$ARCH_ROOT/Build-Agent/guideline-for-creatiung-kb.md`
- Vendors: `$ARCH_ROOT/external-service-providers.md`

---

## Phase 0 — Service Detection

```bash
pwd
```

Detect service identity:

**Node.js / TypeScript:**
```bash
cat package.json
```
Extract: `name`, `version`, `description`, `dependencies` keys (for framework detection).

**Python:**
```bash
cat pyproject.toml 2>/dev/null || cat requirements.txt 2>/dev/null
```

If neither found, ask:
```
Can't detect a service here.
[1] Tell me the service name and I'll continue
[2] Let me switch to the correct directory first
[3] Cancel
```

Store:
- `SERVICE_NAME` — from package.json `.name` or directory basename
- `SERVICE_ROOT` — absolute path from `pwd`
- `TECH_STACK` — nodejs/typescript, python, java, or mixed
- `FRAMEWORK` — express, nestjs, fastapi, flask, micronaut, etc.

---

## Phase 1 — Registry Lookup (Free Context)

Read the service registry to get declared metadata before any GitNexus call:

```bash
grep -A 20 "id: <SERVICE_NAME>" "$ARCH_ROOT/registry/services.yaml"
```

If found, extract and store:
- `REGISTRY_ID` — the `id:` field
- `LAYER` — bff / domain / core / ancillary
- `BOUNDED_CONTEXT` — the bounded context id
- `OWNS` — declared owned entities
- `STORAGE` — declared storage types and tables
- `DOWNSTREAM_SERVICES` — declared downstream calls
- `THIRD_PARTY_VENDORS` — declared vendor dependencies
- `TEAM` — owning team
- `MIGRATION_STATUS` — % migrated from monolith
- `MONOLITH_DEPENDENCY` — what's still on the monolith
- `DOC_PATH` — path to architecture doc

If not found in registry, note as a gap: "Service not yet registered in services.yaml".

Then get the enforcement rules for this service's bounded context:
```bash
grep -A 30 "id: <BOUNDED_CONTEXT>" "$ARCH_ROOT/registry/bounded-contexts.yaml"
```

Store enforcement rules — these become Key Invariants in the KB.

---

## Phase 2 — GitNexus Index

Check if already indexed:
```
mcp__gitnexus__list_repos
```

If SERVICE_ROOT found — skip indexing.

If not found, ask:
```
<SERVICE_NAME> is not in the GitNexus index.
[1] Index now (recommended — ~30–120s)
[2] Skip GitNexus — use file-based exploration only
[3] Cancel
```

On approval, index:
```
mcp__gitnexus__group_sync  (repo: SERVICE_ROOT)
```

If sync fails twice, ask before retrying or skipping. Never loop silently.

---

## Phase 3 — Architecture Extraction via GitNexus

Run these queries. Store results in memory — no file writes yet.

### 3.1 Service Context
```
mcp__gitnexus__context  (repo: SERVICE_ROOT)
```
→ Business purpose, key responsibilities

### 3.2 API Routes
```
mcp__gitnexus__route_map  (repo: SERVICE_ROOT)
```
→ All endpoints: method, path, handler, auth middleware

### 3.3 Function Map
```
mcp__gitnexus__tool_map  (repo: SERVICE_ROOT)
```
→ Public functions, locations, what they call

### 3.4 External Dependency Clients
```
mcp__gitnexus__query  (repo: SERVICE_ROOT, q: "auxiliary-services microservices adapters clients downstream HTTP axios fetch")
```
→ Where dependency clients live (e.g., `src/auxiliary-services/`, `src/common/microservices/`)

### 3.5 Who Calls This Service
```
mcp__gitnexus__api_impact  (repo: SERVICE_ROOT)
```
→ Upstream callers (Identity section)

### 3.6 Database Access Pattern Detection
```
mcp__gitnexus__query  (repo: SERVICE_ROOT, q: "requestType dynamo dynamodb makeRequest DynamoDB DBC connector")
```
Detect which pattern is used:
- **HTTP requestType**: `dynamo.post('/dynamo', { requestType: '...', data: {...} })` or similar
- **DBC named endpoint**: `dbc.makeRequest({ endpoint: '...', data: [...] })` or `applicationdbc.makeRequest`
- **Direct SDK**: `DynamoDB.DocumentClient` or `@aws-sdk/client-dynamodb` — flag as **violation**

### 3.7 Vendor Call Detection
```
mcp__gitnexus__query  (repo: SERVICE_ROOT, q: "janus vendor external API karza NSDL perfios equifax transunion")
```
Check: do all vendor calls go through Janus, or are there direct vendor clients?
- Direct vendor client detected → **bounded context violation** to flag

### 3.8 Notification Pattern Detection
```
mcp__gitnexus__query  (repo: SERVICE_ROOT, q: "hermes notification SMS email whatsapp kaleyra sendgrid FCM")
```
Check: do notification calls go through Hermes/Notification Service?
- Direct vendor (Kaleyra, SendGrid, Firebase) call detected → **bounded context violation**

### 3.9 Monolith Coupling
```
mcp__gitnexus__query  (repo: SERVICE_ROOT, q: "api-connector api monolith legacy migration")
```
→ Which modules still call the monolith, what for

### 3.10 Service Layer Structure
```
mcp__gitnexus__query  (repo: SERVICE_ROOT, q: "routes controllers services repository types validations layers")
```
→ Detect 5-layer chain (Route → Controller → Service → Repository → Types) or other patterns

### 3.11 Config & Environment
```
mcp__gitnexus__query  (repo: SERVICE_ROOT, q: "process.env env config environment variables secrets")
```
→ Env vars used (especially base URLs and service tokens)

### 3.12 Error Handling
```
mcp__gitnexus__query  (repo: SERVICE_ROOT, q: "error handling retry timeout ApiException throw catch circuit breaker")
```
→ Error strategy

### 3.13 Internal Consumer Map (Cypher — always run)
This query is more reliable than `query()` for InCred services and reveals which service files import which adapters:
```
mcp__gitnexus__cypher  (repo: SERVICE_ROOT)
  query: "MATCH (a)-[:CodeRelation {type: 'IMPORTS'}]->(b) WHERE b.filePath STARTS WITH 'src/adapters/' RETURN a.filePath, b.name, b.filePath ORDER BY b.name"
```
→ Use this to populate **Internal consumers:** lines in Section 4 dependency contracts.

**FTS fallback rule:** If ANY `mcp__gitnexus__query` call returns `processes: []` with no results, treat FTS as unavailable for this session. Do NOT retry the same query — fall back immediately to targeted `find` + `grep` file reads. Log "GitNexus FTS unavailable — used file reads" in the completion report gaps. This is a known MCP server bug (read-only database) that persists across restarts.

---

## Phase 4 — Targeted File Reads (Dependency Contracts)

This phase produces Section 4 of the KB — the most valuable section.

**Step 4.0 — Read config file first (counts as 1 file read):**
```bash
find . -path "*/config/default.json" -o -path "*/config/default.js" -o -path "*/config/qa.json" 2>/dev/null | head -1
```
Read the found config file. Extract and store for use across all sections:
- All service hostnames + ports → Section 8 env vars table
- All external URLs (payment gateways, vendors) → Section 4 base URLs
- All template ID maps (Hermes emailTemplateIdMap, smsTemplateIdMap, etc.) → Section 4 Hermes contract
- Queue URLs (SQS) → Section 6 data resources
- Secrets keys (note presence, never copy values verbatim into KB — mark as `stored in config`)

This single read often answers Section 8 completely and pre-fills Section 4 base URLs before reading any adapter file.

**Locate adapter directory:**
```bash
find . -type d -name "auxiliary-services" -o -name "microservices" -o -name "clients" -o -name "adapters" -o -name "connectors" 2>/dev/null | head -5
```

For each dependency found in Phase 3:
1. List files in its client directory
2. Read the main client file (e.g., `lms.client.ts`, `application.service.ts`, `dynamo.service.ts`)
3. Read types/interface file if present

**What to extract per client:**
- Base URL env var + cluster URL pattern
- Auth method (Bearer JWT forwarded / API key / internal / none)
- Every HTTP call method → endpoint path + HTTP method
- Request payload shape (TypeScript interface or function parameters)
- Response shape
- Error handling inside the client

**InCred-specific patterns to document:**

**Dynamo HTTP requestType pattern:**
```typescript
// Document every requestType used:
await dynamoService.post('/dynamo', {
  requestType: 'CREATE_APPLICATION',
  data: { APPLICATION_ID, ... }
})
```
List all requestTypes in a table.

**DBC named endpoint pattern:**
```typescript
await applicationdbc.makeRequest({
  endpoint: 'get_application',
  data: [APPLICATION_ID]
})
```
List all endpoint names used.

**Hermes/Notification pattern:**
```typescript
await hermes.post('/notify/send', {
  TEMPLATE_ID: '...',
  CHANNEL: ['SMS'],
  ...
})
```
List all TEMPLATE_IDs used.

**File read budget: max 10 files.** If more found:
```
Found <N> dependency client files. Which should I prioritize?
[1] Read the tier-1 dependencies (production-critical paths)
[2] Name specific ones to read
[3] Read all — will take longer
```

If an endpoint path is unclear from the client file:
```
Can't determine the exact endpoints for <dependency> from its client file.
[1] Paste the relevant code here
[2] Skip — mark as UNKNOWN
[3] Point me to the right file
```

---

## Phase 5 — Module Aliases & Code Patterns (if TypeScript/NestJS)

```bash
cat tsconfig.json 2>/dev/null || cat tsconfig.base.json 2>/dev/null | grep -A 30 '"paths"'
```

If module aliases found (e.g., `@services/*`, `@root/*`, `@core/*`), extract them for Section 9 Key Invariants — failing to use the correct alias causes import resolution failures.

Also detect decorator patterns if present:
```bash
grep -r "@Controller\|@Validator\|@Sanitize\|@bind" src/ --include="*.ts" -l 2>/dev/null | head -3
```

If custom decorators found, note the pattern for Section 9.

---

## Phase 6 — Write SERVICE-KB.md

Write `<SERVICE_ROOT>/SERVICE-KB.md`. One git HEAD SHA for all sync anchors:

```bash
git rev-parse HEAD
```

Follow InCred's 9-section SERVICE-KB.md standard exactly (see `Build-Agent/guideline-for-creatiung-kb.md` for full format). Key sections:

### Section 1 — Identity
Include: service name, type (from LAYER), language, version, Kubernetes namespace (from k8s YAMLs if found), bounded context, what it OWNS (from registry), upstream callers (from api_impact), repository path.

### Section 2 — Tech Stack
Include: runtime, framework, primary DB + access pattern (Dynamo HTTP requestType / DBC connector), cache, queue, HTTP client library, auth approach, monitoring.

### Section 3 — Dependency Map
ASCII tree of all downstream services. Include a note on where clients live (`src/auxiliary-services/<name>/` or equivalent). Flag monolith (`Api`) calls as `⚠️ legacy — migration in progress`.

### Section 4 — Dependency Contracts
One subsection per dependency with:
- Base URL env var
- Auth
- Used for (one line)
- Endpoints table (only endpoints this service actually calls)
- curl examples with actual field names
- Failure modes
- `<!-- kb:sync ... -->` anchor at end

For Dynamo/DBC: document every requestType or endpoint name in a table.

### Section 5 — Own API Catalog
All routes this service exposes, grouped by version. Include the `called_by` column populated from api_impact.

`<!-- kb:sync section="own-api" adapter="src/routes,src/controllers" last_sha="..." last_updated="..." -->`

### Section 6 — Data Entities Owned
From registry `owns[]` + storage{} fields. Document access pattern (HTTP requestType / DBC / ORM).

### Section 7 — Error Handling Patterns
Retry strategy, timeout defaults, circuit breaker, idempotency approach, fire-and-forget calls.

### Section 8 — Environment & Config
All env vars with their purpose. Note which are base URLs (downstream service addresses) vs secrets vs feature flags.

### Section 9 — Key Invariants
Include:
- Bounded context enforcement rules (from `bounded-contexts.yaml`)
- DynamoDB access pattern rule (never direct SDK)
- Janus rule if service calls vendors (all vendor calls through Janus)
- Hermes rule if service sends notifications
- Module alias rules if TypeScript with path aliases
- Decorator pattern rules if custom decorators found
- Any violations found during exploration (flagged with ⚠️)
- Monolith coupling notes (migration status %)

---

## Phase 7 — Write .service-kb/index.json

Create `<SERVICE_ROOT>/.service-kb/index.json` — machine-readable summary for `/kb-merge`.

```json
{
  "service": "<SERVICE_NAME>",
  "folder_name": "<directory basename>",
  "registry_id": "<from services.yaml id field, or null if not registered>",
  "layer": "<bff | domain | core | ancillary | unknown>",
  "bounded_context": "<from services.yaml>",
  "business_purpose": "<one sentence>",
  "tech_stack": ["nodejs", "typescript"],
  "framework": "<express | nestjs | fastapi | flask | micronaut>",
  "explored_at": "<YYYY-MM-DD>",
  "explorer_version": "1.0",
  "team": "<from services.yaml or null>",
  "repo_path": "<SERVICE_ROOT>",
  "architecture_doc": "$ARCH_ROOT/<doc_path from registry>",
  "migration_status": null,
  "monolith_dependency": null,
  "db_access_pattern": "<http_requesttype | dbc_named_endpoint | sdk_direct | mixed | unknown>",
  "upstream_callers": [],
  "dependencies": [
    {
      "name": "<dependency>",
      "type": "<http | dynamo_requesttype | dbc_connector | redis | sqs | sdk>",
      "base_url_env": "<ENV_VAR>",
      "client_path": "<src/...>",
      "endpoints_called": [
        { "method": "POST", "path": "/...", "purpose": "<one line>" }
      ],
      "auth": "<bearer | api-key | internal | none>",
      "is_monolith": false,
      "is_janus": false
    }
  ],
  "own_apis": [
    { "method": "POST", "path": "/...", "description": "<one line>", "called_by": [], "version": "v1" }
  ],
  "data_resources": [
    { "type": "DynamoDB", "name": "<table>", "primary_key": "<key>", "accessed_via": "http_requesttype", "requestTypes": [] }
  ],
  "third_party_vendors": [],
  "violations": [
    { "type": "direct_vendor_call | direct_sdk | direct_notification_vendor", "description": "<what was found>", "file": "<path>" }
  ],
  "gaps": ["<description of what couldn't be determined>"]
}
```

---

## Phase 8 — Completion Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Code Explorer — <SERVICE_NAME> complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Registry:        <LAYER> · <BOUNDED_CONTEXT> · team: <TEAM>
Migration:       <MIGRATION_STATUS>% from monolith
DB pattern:      <http_requesttype | dbc_named_endpoint | mixed>

Output:
  ✅ SERVICE-KB.md    (<N> dependency contracts · <N> own APIs)
  ✅ .service-kb/index.json   (machine-readable summary)

Dependency contracts:
  ✅ <dep-1>     (<N> endpoints documented)
  ✅ <dep-2>
  ⚠️  <dep-3>     (UNKNOWN — client file unclear)

Violations found (<N>):
  ⚠️  <violation description> — run /arch-review for full audit

Gaps (<N>):
  • <gap> — resolve by reading <file> or asking the team

Sync anchor SHA: <HEAD SHA> (<date>)

💰 Work done: <N> GitNexus queries · <N> file reads · 2 files written
   Actual cost: check the statusline at the bottom of your terminal.

Next:
  • Run /code-explorer in other services in this domain
  • Then run /kb-merge --domain <DOMAIN> to build the common KB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Delta Update Mode

If `SERVICE-KB.md` already exists, detect it and ask:

```
SERVICE-KB.md already exists (last explored: <date>).

[1] Delta update — scan sync anchors, refresh only stale sections (fast)
[2] Full re-explore — rewrite from scratch
[3] Show what changed since last explore
```

**Delta process:**
```bash
grep -n 'kb:sync' SERVICE-KB.md
```

For each anchor:
```bash
git log <last_sha>..HEAD --oneline -- <adapter_path>
```

If no commits → section is current, skip.  
If commits → read only changed files:
```bash
git diff --name-only <last_sha>..HEAD -- <adapter_path>
git diff <last_sha>..HEAD -- <changed_file>
```

Update only the rows affected by the diff (endpoint paths, payload fields, requestTypes). Update the sync anchor SHA. Never rewrite sections with no diff.

---

## Behavioral Guidelines

1. **Registry first, always.** Read `services.yaml` entry before any GitNexus query — it's free context.
2. **GitNexus second, files last.** Never open a source file if GitNexus answered it.
3. **Adapter files define the scope boundary.** Section 4 documents what THIS service calls — not the full API of each dependency.
4. **Max 10 file reads** in Phase 4 (including the config file read in step 4.0). Log every read in the report.
5. **Flag all violations.** Bounded context violations (direct vendor calls, direct SDK, direct notification vendors) go in Section 9 AND in `index.json .violations[]`. Recommend `/arch-review` for full audit.
6. **Sync anchors are mandatory.** Every Section 4 dependency and Section 5 own-API block must end with `<!-- kb:sync ... -->`.
7. **Ask, don't loop.** If any phase stalls — unclear file, missing data, ambiguous result — ask with numbered options. Max 1 retry per operation.
8. **No hallucination.** `UNKNOWN` in the KB is better than a wrong answer. Add to gaps list.
9. **DBC and HTTP requestType are both valid patterns.** Document which one is used per service. Never say one is wrong unless it's direct SDK.
10. **Always run Phase 9 and 10** after a successful full exploration or delta update — never skip memory and self-improvement.

---

## Phase 9 — Memory Persistence

After writing `SERVICE-KB.md` and `.service-kb/index.json`, save two memory files.

### 9.1 Service Memory (project-scoped)

Derive the project memory directory from `SERVICE_ROOT`:
```bash
# Convert path to project slug (replace / with -)
# e.g. /Users/aryankumarmaurya/Incred-Engineers/paymentservice
#   -> -Users-aryankumarmaurya-Incred-Engineers-paymentservice
PROJECT_SLUG=$(echo "$SERVICE_ROOT" | sed 's|/|-|g')
MEMORY_DIR="$HOME/.claude/projects/$PROJECT_SLUG/memory"
mkdir -p "$MEMORY_DIR"
```

Write `$MEMORY_DIR/service_<REGISTRY_ID>.md`:

```markdown
---
name: service-<REGISTRY_ID>
description: Key facts about <SERVICE_NAME> — layer, dependencies, violations, patterns
metadata:
  type: project
---

**Service:** <REGISTRY_ID> · <LAYER> · bounded_context: <BOUNDED_CONTEXT>
**Explored:** <DATE> · SHA: <HEAD_SHA>
**DB pattern:** <db_access_pattern>
**Monolith coupling:** <monolith_dependency or "none">

**Why:** Persisted so future agents know this service's architecture without re-reading source.
**How to apply:** Load before writing code in this service or calling its APIs.

**Key dependencies:**
<list each dependency name, type, base URL env var — one line each>

**Violations:** <list each violation type + file, or "none">

**Open gaps:**
<list each gap from index.json, or "none">
```

Also update `$MEMORY_DIR/MEMORY.md` index (create if absent):
- Add one line: `- [service-<REGISTRY_ID>](service_<REGISTRY_ID>.md) — <LAYER> service in <BOUNDED_CONTEXT>, <db_access_pattern> DB, <N> deps`

### 9.2 Skill Lessons Memory (skill-scoped)

Write/append to `~/.claude/skills/code-explorer/memory/lessons.md`.

Each entry captures one lesson from this run — a thing that worked, a thing that failed, or a pattern observed. Format:

```markdown
## <DATE> · <SERVICE_NAME>

**Worked:** <what technique was effective — e.g. "Cypher IMPORTS query gave complete internal consumer map">
**Failed:** <what didn't work — e.g. "GitNexus query() returned empty (FTS read-only bug)">
**Workaround:** <what substituted — e.g. "grep + file reads covered the same ground">
**New pattern:** <any InCred-specific pattern discovered — e.g. "lotuspay.ts used as both NACH adapter and CKYC caller">
**Suggested fix:** <one-line patch idea for the skill — e.g. "Add Cypher IMPORTS as standard Phase 3 step">
```

Only write entries where something non-obvious happened. Skip if the run was fully nominal with no surprises.

---

## Phase 10 — Self-Improvement Proposal

Read the accumulated lessons file:
```bash
cat ~/.claude/skills/code-explorer/memory/lessons.md 2>/dev/null
```

Scan for **Suggested fix** entries that appear in 2+ separate runs (recurring pattern). For each:
1. Identify the specific phase and line in SKILL.md to change
2. Draft the patch (new text to replace old text)
3. Show the user a numbered list of proposed improvements:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 Self-Improvement Proposals — code-explorer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Based on <N> runs, the following changes are proposed:

[1] Phase 3 — Add Cypher IMPORTS as standard step
    Seen in: paymentservice, <other service>
    Reason: query() is unreliable; IMPORTS Cypher always works and fills
            the internal consumer map gap.
    → Would add 3.13 to Phase 3.

[2] Phase 4 — Increase file read budget to 10 for services with >8 adapters
    Seen in: paymentservice
    Reason: Hit 8-file cap; mysql, redis, SQS workers left undocumented.
    → Would change "max 8 files" to "max 10 files".

Apply all? [Y] Apply selected? [1,2] Skip? [N]
```

- On **Y**: apply all patches to SKILL.md using Edit tool.
- On **1,2,...**: apply only selected patches.
- On **N**: skip — lessons remain in memory for next run.

**Never apply a patch that:**
- Removes a behavioral guideline without user confirmation
- Changes phase ordering
- Edits the frontmatter `description` field (that's auto-updated from the description field only)

After applying, print:
```
✅ SKILL.md updated — <N> improvements applied.
   Changes will take effect on next /code-explorer run.
```

---

## Memory Files Reference

| File | Location | Purpose |
|---|---|---|
| `service_<id>.md` | `~/.claude/projects/<slug>/memory/` | Service facts for future agents in this project |
| `MEMORY.md` | `~/.claude/projects/<slug>/memory/` | Index of all memories for this project |
| `lessons.md` | `~/.claude/skills/code-explorer/memory/` | Accumulated lessons across all runs (feeds Phase 10) |
| `SKILL.md` | `~/.claude/skills/code-explorer/` | The skill itself (patched by Phase 10) |
