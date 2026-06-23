---
name: claude-publish
description: |
  Publishes Claude Code skills and agents from your local ~/.claude/ directory to a configured GitHub repository. Use this skill whenever you want to push skill or agent updates to GitHub — say "publish my skills", "push skill updates", "sync skills to GitHub", or "publish mm-enrich". Auto-detects which files have changed vs the remote, shows a diff, and waits for approval before pushing. Supports --skill, --agent, --all, and --dry-run flags.
command: claude-publish
trigger: |
  - User says "publish skills", "push skill updates", "sync to GitHub"
  - User says "publish [skill-name]" or "update [skill-name] on GitHub"
  - User says "push agents to GitHub"
  - After editing a skill or agent file and wanting to share the update
kind: skill
visibility: project
---

## Overview

Syncs your local `~/.claude/skills/` and `~/.claude/agents/` files to a GitHub repository, so teammates can install via `curl`.

The publish repo is configured in `~/.claude/publish-config.json`. If not present, the skill prompts you to set it up once.

**Invocation:**
- `/claude-publish` — auto-detects all changed skills/agents vs remote, prompts to publish
- `/claude-publish --skill mm-enrich` — publish specific skill
- `/claude-publish --skill mm-story,mm-enrich` — publish multiple
- `/claude-publish --agent mm-enricher` — publish specific agent
- `/claude-publish --skill mm-enrich --agent mm-enricher` — mix
- `/claude-publish --all` — publish everything
- `/claude-publish --dry-run` — show what would be published without pushing

---

## STEP 0: LOAD PUBLISH CONFIG

Read `~/.claude/publish-config.json`:

```json
{
  "repo": "aryan-incred/incred-ai",
  "branch": "main",
  "skills_remote_path": "claude/skills",
  "agents_remote_path": "claude/agents",
  "local_skills_root": "~/.claude/skills",
  "local_agents_root": "~/.claude/agents",
  "local_repo_path": "~/Incred-Engineers/incred-ai"
}
```

**If config not found**, run setup once:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚙️  FIRST-TIME SETUP — claude-publish
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What GitHub repo should skills be published to?
(e.g. aryan-incred/incred-ai)
→
```

After the user provides the repo, write `~/.claude/publish-config.json` and confirm.

---

## STEP 1: DETECT CHANGES

### If specific skills/agents provided via flags → skip detection, go to STEP 2

### If `--all` or no flags → auto-detect changed files

For each skill in `~/.claude/skills/[name]/SKILL.md`:

```bash
# Fetch remote version
curl -fsSL "https://raw.githubusercontent.com/[repo]/[branch]/claude/skills/[name]/SKILL.md" -o /tmp/remote-[name].md 2>/dev/null
diff ~/.claude/skills/[name]/SKILL.md /tmp/remote-[name].md
```

For each agent in `~/.claude/agents/[name].md`:

```bash
curl -fsSL "https://raw.githubusercontent.com/[repo]/[branch]/claude/agents/[name].md" -o /tmp/remote-[name].md 2>/dev/null
diff ~/.claude/agents/[name].md /tmp/remote-[name].md
```

Classify each file as:
- `NEW` — exists locally, not in remote
- `MODIFIED` — exists in both, local is different
- `REMOTE ONLY` — exists in remote, not locally (skip — don't delete)
- `IN SYNC` — identical in both (skip)

Show the change summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 PUBLISH SUMMARY — aryan-incred/incred-ai
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Skills:
  ✨ NEW       mm-blueprint
  📝 MODIFIED  mm-enrich         (local differs from remote)
  📝 MODIFIED  mm-story          (local differs from remote)
  ✓  IN SYNC   mm-analyze
  ✓  IN SYNC   code-explorer

Agents:
  ✨ NEW       mm-enricher
  📝 MODIFIED  mm-scoping-analyst
  ✓  IN SYNC   mm-pm-reviewer

Total: 2 new, 3 modified, 0 unchanged skipped
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If nothing to publish:
```
✓ Everything is in sync with aryan-incred/incred-ai — nothing to publish.
```

If `--dry-run`: print the summary and stop here.

---

## STEP 2: SHOW DIFF — APPROVAL GATE

For each NEW or MODIFIED file, show a preview before asking for confirmation:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Publish to GitHub
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Repo:   aryan-incred/incred-ai
Branch: main

Files to publish:
  claude/skills/mm-enrich/SKILL.md      [MODIFIED]
  claude/skills/mm-blueprint/SKILL.md   [NEW]
  claude/agents/mm-enricher.md          [NEW]
  claude/agents/mm-scoping-analyst.md   [MODIFIED]

[1] Show diff for each before publishing
[2] Publish all listed files now
[3] Select which to publish
[4] Cancel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**On [1]:** Show the diff for each file one at a time with per-file confirmation:
```
Diff — claude/skills/mm-enrich/SKILL.md:
[show unified diff]

  [1] Publish this file    [2] Skip this file    [3] Cancel all
```

**On [2]:** Proceed to STEP 3 with all listed files.

**On [3]:** Let user type file numbers to include (e.g., `1,3`), then proceed.

Never push without explicit approval.

---

## STEP 3: COPY TO LOCAL REPO + GIT PUSH

First sync the approved files to the local repo mirror:

```bash
# Skills
for skill in [approved-skills]; do
  mkdir -p ~/Incred-Engineers/incred-ai/claude/skills/$skill
  cp ~/.claude/skills/$skill/SKILL.md ~/Incred-Engineers/incred-ai/claude/skills/$skill/SKILL.md
done

# Agents
for agent in [approved-agents]; do
  cp ~/.claude/agents/$agent.md ~/Incred-Engineers/incred-ai/claude/agents/$agent.md
done
```

Then commit and push:

```bash
cd ~/Incred-Engineers/incred-ai
git add claude/
git commit -m "publish: [summary of what changed]

Updated:
[list of files]"
git push origin main
```

Print progress as it happens. If `git push` fails, show the error and the manual commands to retry.

---

## STEP 4: SIGN-OFF

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PUBLISHED — aryan-incred/incred-ai
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Published:
  claude/skills/mm-enrich/SKILL.md      ✅
  claude/skills/mm-blueprint/SKILL.md   ✅
  claude/agents/mm-enricher.md          ✅
  claude/agents/mm-scoping-analyst.md   ✅

Commit: [short sha] — [commit message]

Install command for teammates:
  curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --skill mm-enrich,mm-blueprint --agent mm-enricher,mm-scoping-analyst
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

The sign-off always includes a ready-to-share install command scoped to exactly what was published.

---

## Flags Reference

| Flag | Behaviour |
|------|-----------|
| *(none)* | Auto-detect all changed files, prompt to publish |
| `--skill name` | Publish specific skill (comma-separate for multiple) |
| `--agent name` | Publish specific agent (comma-separate for multiple) |
| `--all` | Publish all skills and agents |
| `--dry-run` | Show what would be published, no push |

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Config not found | Run first-time setup |
| Local repo path not found | Prompt for correct path, update config |
| Remote file fetch fails | Mark as NEW (assume not in remote yet) |
| `git push` fails | Show error + manual commands: `cd ~/Incred-Engineers/incred-ai && git push origin main` |
| Uncommitted changes in local repo | Warn and offer: `[1] Stash and continue  [2] Cancel` |
