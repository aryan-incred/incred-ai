#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# InCred AI — Claude Code Skills & Agents Installer
# Repo: https://github.com/aryan-incred/incred-ai
#
# Usage (private repo — token required):
#   export INCRED_AI_TOKEN=ghp_xxxx   # set once in ~/.zshrc to avoid repeating
#
#   curl -fsSL -H "Authorization: token $INCRED_AI_TOKEN" \
#     https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash
#
#   With flags:
#   curl -fsSL -H "Authorization: token $INCRED_AI_TOKEN" \
#     https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash -s -- --preset story
#
#   Or pass token inline:
#   ... | bash -s -- --preset story --token ghp_xxxx
# ──────────────────────────────────────────────────────────────────────────────
set -e

REPO_RAW="https://raw.githubusercontent.com/aryan-incred/incred-ai/main/claude"
SKILLS_DIR="$HOME/.claude/skills"
AGENTS_DIR="$HOME/.claude/agents"
FORCE_UPDATE=false
INCRED_AI_TOKEN="${INCRED_AI_TOKEN:-}"  # set via env var or --token flag

# ── Preset definitions ────────────────────────────────────────────────────────
# story  = MM PMs only (no engineering tools)
PRESET_STORY_SKILLS=(mm-story mm-enrich)
PRESET_STORY_AGENTS=(mm-enricher mm-scoping-analyst mm-pm-reviewer)

# pipeline = MM developers, Tech Leads, QA (includes mm-story so devs can also review stories)
PRESET_PIPELINE_SKILLS=(mm-story mm-enrich mm-blueprint mm-approve-plan mm-tdd mm-ship mm-telemetry mm-status)
PRESET_PIPELINE_AGENTS=(mm-scoping-analyst mm-pm-reviewer mm-tech-reviewer mm-codebase-planner mm-test-architect mm-implementer mm-qa-gatekeeper mm-release-herald)

# all = everything including shared engineering tools
PRESET_ALL_SKILLS=(mm-story mm-enrich mm-blueprint mm-approve-plan mm-tdd mm-ship mm-telemetry mm-status code-explorer kb-merge claude-publish)
PRESET_ALL_AGENTS=(mm-enricher mm-scoping-analyst mm-pm-reviewer mm-tech-reviewer mm-codebase-planner mm-test-architect mm-implementer mm-qa-gatekeeper mm-release-herald)

# ── Helpers ───────────────────────────────────────────────────────────────────
install_skill() {
  local name="$1"
  local dest="$SKILLS_DIR/$name/SKILL.md"

  mkdir -p "$SKILLS_DIR/$name"

  if [[ -f "$dest" && "$FORCE_UPDATE" == "false" ]]; then
    # Already installed — fetch remote to check if update is available
    local tmp
    tmp=$(mktemp)
    if curl -fsSL ${INCRED_AI_TOKEN:+-H "Authorization: token $INCRED_AI_TOKEN"} "$REPO_RAW/skills/$name/SKILL.md" -o "$tmp" 2>/dev/null; then
      if diff -q "$dest" "$tmp" > /dev/null 2>&1; then
        echo "  ✓ skill: $name  (already up to date)"
      else
        # Prompt for update
        printf "  ↑ skill: $name  (update available) — update? [y/N] "
        read -r answer </dev/tty
        if [[ "$answer" =~ ^[Yy]$ ]]; then
          cp "$tmp" "$dest"
          echo "    → updated ✅"
        else
          echo "    → skipped"
        fi
      fi
    else
      echo "  ❌ skill: $name — not found in repo"
    fi
    rm -f "$tmp"
  else
    # Fresh install or --update flag set
    if curl -fsSL ${INCRED_AI_TOKEN:+-H "Authorization: token $INCRED_AI_TOKEN"} "$REPO_RAW/skills/$name/SKILL.md" -o "$dest" 2>/dev/null; then
      if [[ "$FORCE_UPDATE" == "true" ]]; then
        echo "  ✅ skill: $name  (updated)"
      else
        echo "  ✅ skill: $name  (installed)"
      fi
    else
      echo "  ❌ skill: $name — not found in repo"
    fi
  fi
}

install_agent() {
  local name="$1"
  local dest="$AGENTS_DIR/$name.md"

  mkdir -p "$AGENTS_DIR"

  if [[ -f "$dest" && "$FORCE_UPDATE" == "false" ]]; then
    local tmp
    tmp=$(mktemp)
    if curl -fsSL ${INCRED_AI_TOKEN:+-H "Authorization: token $INCRED_AI_TOKEN"} "$REPO_RAW/agents/$name.md" -o "$tmp" 2>/dev/null; then
      if diff -q "$dest" "$tmp" > /dev/null 2>&1; then
        echo "  ✓ agent: @$name  (already up to date)"
      else
        printf "  ↑ agent: @$name  (update available) — update? [y/N] "
        read -r answer </dev/tty
        if [[ "$answer" =~ ^[Yy]$ ]]; then
          cp "$tmp" "$dest"
          echo "    → updated ✅"
        else
          echo "    → skipped"
        fi
      fi
    else
      echo "  ❌ agent: @$name — not found in repo"
    fi
    rm -f "$tmp"
  else
    if curl -fsSL ${INCRED_AI_TOKEN:+-H "Authorization: token $INCRED_AI_TOKEN"} "$REPO_RAW/agents/$name.md" -o "$dest" 2>/dev/null; then
      if [[ "$FORCE_UPDATE" == "true" ]]; then
        echo "  ✅ agent: @$name  (updated)"
      else
        echo "  ✅ agent: @$name  (installed)"
      fi
    else
      echo "  ❌ agent: @$name — not found in repo"
    fi
  fi
}

print_list() {
  echo ""
  echo "Available skills:"
  echo "  MM PM:           mm-story  mm-enrich"
  echo "  MM Pipeline:     mm-blueprint  mm-approve-plan  mm-tdd  mm-ship  mm-telemetry  mm-status"
  echo "  Shared (any):    code-explorer  kb-merge  claude-publish"
  echo "  Note: mm-story covers create/review/check-gap/submit/revise (run /mm-story --help)"
  echo ""
  echo "Available agents:"
  echo "  MM PM:           mm-enricher  mm-scoping-analyst  mm-pm-reviewer"
  echo "  MM Pipeline:     mm-tech-reviewer  mm-codebase-planner  mm-test-architect"
  echo "                   mm-implementer  mm-qa-gatekeeper  mm-release-herald"
  echo ""
  echo "Presets:"
  echo "  --preset story     MM PM bundle: mm-story + mm-enrich + 3 PM agents"
  echo "  --preset pipeline  MM full pipeline: all skills + 8 agents"
  echo "  --preset all       Everything including shared engineering tools"
  echo ""
  echo "Flags:"
  echo "  --skill name1,name2    Install specific skills (comma-separated)"
  echo "  --agent name1,name2    Install specific agents (comma-separated)"
  echo "  --preset NAME          Install a named bundle"
  echo "  --update               Force update all without prompting"
  echo "  --list                 Show available skills and agents"
  echo ""
  echo "Examples:"
  echo "  Install story preset:       bash install.sh --preset story"
  echo "  Install single skill:       bash install.sh --skill mm-story"
  echo "  Install multiple:           bash install.sh --skill mm-story,mm-enrich --agent mm-enricher"
  echo "  Force update everything:    bash install.sh --preset all --update"
  echo "  Update single skill:        bash install.sh --skill mm-enrich --update"
}

# ── Arg parsing ───────────────────────────────────────────────────────────────
SKILLS_TO_INSTALL=()
AGENTS_TO_INSTALL=()
PRESET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill)
      IFS=',' read -ra s <<< "$2"
      SKILLS_TO_INSTALL+=("${s[@]}")
      shift 2
      ;;
    --agent)
      IFS=',' read -ra a <<< "$2"
      AGENTS_TO_INSTALL+=("${a[@]}")
      shift 2
      ;;
    --preset)
      PRESET="$2"
      shift 2
      ;;
    --token)
      INCRED_AI_TOKEN="$2"
      shift 2
      ;;
    --update)
      FORCE_UPDATE=true
      shift
      ;;
    --list)
      print_list
      exit 0
      ;;
    -h|--help)
      echo "InCred AI installer — https://github.com/aryan-incred/incred-ai"
      print_list
      exit 0
      ;;
    *)
      echo "Unknown flag: $1  (run with --help)"
      exit 1
      ;;
  esac
done

# ── Apply preset ──────────────────────────────────────────────────────────────
case "$PRESET" in
  story)
    SKILLS_TO_INSTALL=("${PRESET_STORY_SKILLS[@]}")
    AGENTS_TO_INSTALL=("${PRESET_STORY_AGENTS[@]}")
    ;;
  pipeline)
    SKILLS_TO_INSTALL=("${PRESET_PIPELINE_SKILLS[@]}")
    AGENTS_TO_INSTALL=("${PRESET_PIPELINE_AGENTS[@]}")
    ;;
  all)
    SKILLS_TO_INSTALL=("${PRESET_ALL_SKILLS[@]}")
    AGENTS_TO_INSTALL=("${PRESET_ALL_AGENTS[@]}")
    ;;
  "")
    if [[ ${#SKILLS_TO_INSTALL[@]} -eq 0 && ${#AGENTS_TO_INSTALL[@]} -eq 0 ]]; then
      echo "InCred AI installer"
      echo "No flags provided — installing story creation preset (default)."
      echo "Run with --list to see all options, or --help for usage."
      echo ""
      SKILLS_TO_INSTALL=("${PRESET_STORY_SKILLS[@]}")
      AGENTS_TO_INSTALL=("${PRESET_STORY_AGENTS[@]}")
    fi
    ;;
  *)
    echo "Unknown preset: $PRESET  (valid: story, pipeline, all)"
    exit 1
    ;;
esac

# ── Progress bar helper ───────────────────────────────────────────────────────
TOTAL=0
CURRENT=0
INSTALLED=0
UPDATED=0
SKIPPED=0
FAILED=0

progress_bar() {
  local current="$1"
  local total="$2"
  local label="$3"
  local width=30
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  printf "\r  [%s] %d/%d  %s" "$bar" "$current" "$total" "$label"
}

# Wrap install_skill to track progress
install_skill_progress() {
  local name="$1"
  CURRENT=$(( CURRENT + 1 ))
  progress_bar "$CURRENT" "$TOTAL" "skill: $name          "

  local dest="$SKILLS_DIR/$name/SKILL.md"
  mkdir -p "$SKILLS_DIR/$name"

  if [[ -f "$dest" && "$FORCE_UPDATE" == "false" ]]; then
    local tmp; tmp=$(mktemp)
    if curl -fsSL ${INCRED_AI_TOKEN:+-H "Authorization: token $INCRED_AI_TOKEN"} "$REPO_RAW/skills/$name/SKILL.md" -o "$tmp" 2>/dev/null; then
      if diff -q "$dest" "$tmp" > /dev/null 2>&1; then
        SKIPPED=$(( SKIPPED + 1 ))
      else
        printf "\r"
        printf "  ↑ skill: %-28s (update available) — update? [y/N] " "$name"
        read -r answer </dev/tty
        if [[ "$answer" =~ ^[Yy]$ ]]; then
          cp "$tmp" "$dest"
          UPDATED=$(( UPDATED + 1 ))
        else
          SKIPPED=$(( SKIPPED + 1 ))
        fi
      fi
    else
      FAILED=$(( FAILED + 1 ))
    fi
    rm -f "$tmp"
  else
    if curl -fsSL ${INCRED_AI_TOKEN:+-H "Authorization: token $INCRED_AI_TOKEN"} "$REPO_RAW/skills/$name/SKILL.md" -o "$dest" 2>/dev/null; then
      INSTALLED=$(( INSTALLED + 1 ))
    else
      printf "\r  ❌ skill: %-28s not found in repo\n" "$name"
      FAILED=$(( FAILED + 1 ))
    fi
  fi
}

# Wrap install_agent to track progress
install_agent_progress() {
  local name="$1"
  CURRENT=$(( CURRENT + 1 ))
  progress_bar "$CURRENT" "$TOTAL" "agent: @$name          "

  local dest="$AGENTS_DIR/$name.md"
  mkdir -p "$AGENTS_DIR"

  if [[ -f "$dest" && "$FORCE_UPDATE" == "false" ]]; then
    local tmp; tmp=$(mktemp)
    if curl -fsSL ${INCRED_AI_TOKEN:+-H "Authorization: token $INCRED_AI_TOKEN"} "$REPO_RAW/agents/$name.md" -o "$tmp" 2>/dev/null; then
      if diff -q "$dest" "$tmp" > /dev/null 2>&1; then
        SKIPPED=$(( SKIPPED + 1 ))
      else
        printf "\r"
        printf "  ↑ agent: %-28s (update available) — update? [y/N] " "@$name"
        read -r answer </dev/tty
        if [[ "$answer" =~ ^[Yy]$ ]]; then
          cp "$tmp" "$dest"
          UPDATED=$(( UPDATED + 1 ))
        else
          SKIPPED=$(( SKIPPED + 1 ))
        fi
      fi
    else
      FAILED=$(( FAILED + 1 ))
    fi
    rm -f "$tmp"
  else
    if curl -fsSL ${INCRED_AI_TOKEN:+-H "Authorization: token $INCRED_AI_TOKEN"} "$REPO_RAW/agents/$name.md" -o "$dest" 2>/dev/null; then
      INSTALLED=$(( INSTALLED + 1 ))
    else
      printf "\r  ❌ agent: %-28s not found in repo\n" "@$name"
      FAILED=$(( FAILED + 1 ))
    fi
  fi
}

# ── Install / update ──────────────────────────────────────────────────────────
TOTAL=$(( ${#SKILLS_TO_INSTALL[@]} + ${#AGENTS_TO_INSTALL[@]} ))

# ── Token check ───────────────────────────────────────────────────────────────
if [[ -z "$INCRED_AI_TOKEN" ]]; then
  echo ""
  echo "⚠️  No GitHub token found."
  echo "   This repo is private — installs will fail without a token."
  echo ""
  echo "   Fix (add to ~/.zshrc or ~/.bashrc):"
  echo "     export INCRED_AI_TOKEN=ghp_xxxx"
  echo ""
  echo "   Or pass inline:"
  echo "     bash install.sh --preset story --token ghp_xxxx"
  echo ""
  echo "   Ask Aryan for the read-only token."
  echo ""
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  InCred AI — Claude Code Skills & Agents"
echo "  Installing to ~/.claude/"
[[ "$FORCE_UPDATE" == "true" ]] && echo "  Mode: --update (overwriting without prompting)"
printf "  Items: %d skills + %d agents = %d total\n" \
  "${#SKILLS_TO_INSTALL[@]}" "${#AGENTS_TO_INSTALL[@]}" "$TOTAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for skill in "${SKILLS_TO_INSTALL[@]}"; do
  install_skill_progress "$skill"
done

for agent in "${AGENTS_TO_INSTALL[@]}"; do
  install_agent_progress "$agent"
done

# Clear progress bar line and print summary
printf "\r%-60s\r" " "
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  ✅ Installed:  %d\n" "$INSTALLED"
[[ "$UPDATED"  -gt 0 ]] && printf "  ↑  Updated:    %d\n" "$UPDATED"
[[ "$SKIPPED"  -gt 0 ]] && printf "  ✓  Up to date: %d\n" "$SKIPPED"
[[ "$FAILED"   -gt 0 ]] && printf "  ❌ Failed:     %d\n" "$FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ "$FAILED" -gt 0 ]]; then
  echo "  Some items failed. Check your network or re-run with --update."
  echo ""
fi

echo "  Next steps:"
echo "    1. Restart Claude Code"
echo "    2. Run /reload-skills to activate"
echo ""
