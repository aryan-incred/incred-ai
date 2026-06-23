---
name: claude-publish
description: |
  Publishes Claude Code skills and agents from your local ~/.claude/ directory to all configured GitHub repositories in one command. Use this skill whenever you want to push skill or agent updates — say "publish my skills", "push skill updates", "sync skills to GitHub", or "publish mm-enrich". Auto-detects which files have changed vs remote, shows a diff, and waits for approval before pushing. Syncs to all repos in publish-config.json by default. Supports --skill, --agent, --all, --repo, and --dry-run flags.
command: claude-publish
trigger: |
  - User says "publish skills", "push skill updates", "sync to GitHub"
  - User says "publish [skill-name]" or "update [skill-name] on GitHub"
  - After editing a skill or agent file and wanting to share the update
kind: skill
visibility: project
---

## Overview

Syncs your local `~/.claude/skills/` and `~/.claude/agents/` to all GitHub repositories configured in `~/.claude/publish-config.json`. By default syncs to all repos simultaneously — private and org.

**Invocation:**
- `/claude-publish` — auto-detect all changed files, push to all repos
- `/claude-publish --skill mm-story` — publish specific skill to all repos
- `/claude-publish --skill mm-story,mm-enrich` — publish multiple
- `/claude-publish --agent mm-enricher` — publish specific agent
- `/claude-publish --repo org` — push to org repo only
- `/claude-publish --repo private` — push to private repo only
- `/claude-publish --all` — publish everything to all repos
- `/claude-publish --dry-run` — show what would be published, no push

---

## STEP 0: LOAD CONFIG

Read `~/.claude/publish-config.json`:

```json
{
  "repos": [
    {
      "name": "private",
      "repo": "aryan-incred/incred-ai",
      "branch": "main",
      "token_env": "INCRED_AI_TOKEN",
      "local_path": "~/Incred-Engineers/incred-ai"
    },
    {
      "name": "org",
      "repo": "Incred-Engineers/MM-agentic-SDLC",
      "branch": "main",
      "token_env": null,
      "local_path": "~/Incred-Engineers/MM-agentic-SDLC"
    }
  ],
  "skills_remote_path": "claude/skills",
  "agents_remote_path": "claude/agents",
  "local_skills_root": "~/.claude/skills",
  "local_agents_root": "~/.claude/agents"
}
```

**If config not found**, run first-time setup and write it.

**Filter repos by `--repo` flag:**
- `--repo all` or no flag → all repos
- `--repo org` → only `name: "org"` entries
- `--repo private` → only `name: "private"` entries

For each repo with `token_env` set, check the env var exists:
```bash
echo ${INCRED_AI_TOKEN:+set}
```
If missing, warn but continue — the push step will fail gracefully for that repo.

---

## STEP 1: DETECT CHANGES

### If specific skills/agents provided → skip detection, go to STEP 2

### If `--all` or no flags → auto-detect changed files

For each skill in `~/.claude/skills/[name]/SKILL.md`, compare with remote using the first configured repo as reference:

```bash
# Fetch remote version
curl -fsSL ${TOKEN:+-H "Authorization: token $TOKEN"} \
  "https://raw.githubusercontent.com/[repo]/[branch]/claude/skills/[name]/SKILL.md" \
  -o /tmp/remote-[name].md 2>/dev/null
diff ~/.claude/skills/[name]/SKILL.md /tmp/remote-[name].md
```

Classify each file:
- `NEW` — exists locally, not in remote
- `MODIFIED` — local differs from remote
- `IN SYNC` — identical (skip)

Show change summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 PUBLISH SUMMARY
Syncing to: [N] repos (private + org)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Skills:
  ✨ NEW       mm-blueprint
  📝 MODIFIED  mm-enrich
  ✓  IN SYNC   mm-analyze

Agents:
  ✨ NEW       mm-enricher
  ✓  IN SYNC   mm-pm-reviewer

Total: [N] new, [N] modified
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If nothing to publish → print `✓ All repos in sync — nothing to publish.` and stop.

If `--dry-run` → print summary and stop here.

---

## STEP 2: APPROVAL GATE

Show files to publish and wait:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  APPROVAL REQUIRED — Publish to GitHub
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Repos:
  private → aryan-incred/incred-ai
  org     → Incred-Engineers/MM-agentic-SDLC

Files:
  claude/skills/mm-enrich/SKILL.md      [MODIFIED]
  claude/skills/mm-blueprint/SKILL.md   [NEW]
  claude/agents/mm-enricher.md          [NEW]

  [1] Show diff for each before publishing
  [2] Publish to all repos now
  [3] Publish to org only
  [4] Publish to private only
  [5] Cancel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## STEP 3: COPY + GIT PUSH (per repo)

For each target repo, copy approved files to the local repo mirror and push:

```bash
# Copy skills
for skill in [approved-skills]; do
  mkdir -p [local_path]/claude/skills/$skill
  cp ~/.claude/skills/$skill/SKILL.md [local_path]/claude/skills/$skill/SKILL.md
done

# Copy agents
for agent in [approved-agents]; do
  cp ~/.claude/agents/$agent.md [local_path]/claude/agents/$agent.md
done

# Commit and push
cd [local_path]
git add claude/
git commit -m "publish: [summary of what changed]"
git push origin [branch]
```

For the private repo (has `token_env`): ensure the git remote uses HTTPS with the token, or that the token is set in the environment so gh CLI can authenticate.

Show progress per repo:

```
Pushing to private (aryan-incred/incred-ai)...     ✅
Pushing to org (Incred-Engineers/MM-agentic-SDLC)... ✅
```

If a push fails for one repo → report the error and continue to the next. Never abort mid-sync.

---

## STEP 4: SIGN-OFF

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PUBLISHED

  private → aryan-incred/incred-ai         ✅ [sha]
  org     → Incred-Engineers/MM-agentic-SDLC ✅ [sha]

Files published:
  claude/skills/mm-enrich/SKILL.md
  claude/skills/mm-blueprint/SKILL.md
  claude/agents/mm-enricher.md

Install command for teammates:
  curl -fsSL https://raw.githubusercontent.com/Incred-Engineers/MM-agentic-SDLC/main/install.sh | bash -s -- --skill mm-enrich,mm-blueprint --agent mm-enricher
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

The sign-off always shows the org repo install command (not private) since that's what teammates use.

---

## Flags Reference

| Flag | Behaviour |
|------|-----------|
| *(none)* | Auto-detect all changed files, push to all repos |
| `--skill name` | Publish specific skill (comma-separate for multiple) |
| `--agent name` | Publish specific agent (comma-separate for multiple) |
| `--all` | Publish all skills and agents |
| `--repo all` | Push to all configured repos (default) |
| `--repo org` | Push to org repo only |
| `--repo private` | Push to private repo only |
| `--dry-run` | Show what would change, no push |

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Config not found | Run first-time setup |
| Token env var missing for private repo | Warn, skip that repo, continue with others |
| Local repo path not found | Prompt for correct path, offer to update config |
| git push fails for one repo | Show error, continue to next repo |
| Uncommitted changes in local mirror | Warn and offer: `[1] Stash and continue  [2] Cancel` |
