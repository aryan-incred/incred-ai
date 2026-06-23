#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# InCred AI — Claude Code Skills & Agents Installer
# Repo: https://github.com/aryan-incred/incred-ai
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/aryan-incred/incred-ai/main/install.sh | bash
#   curl -fsSL ... | bash -s -- --preset story
#   curl -fsSL ... | bash -s -- --skill mm-story,mm-enrich --agent mm-enricher
#   curl -fsSL ... | bash -s -- --preset all --update
#   curl -fsSL ... | bash -s -- --list
# ──────────────────────────────────────────────────────────────────────────────
set -e

REPO_RAW="https://raw.githubusercontent.com/aryan-incred/incred-ai/main/claude"
SKILLS_DIR="$HOME/.claude/skills"
AGENTS_DIR="$HOME/.claude/agents"
FORCE_UPDATE=false

# ── Preset definitions ────────────────────────────────────────────────────────
PRESET_STORY_SKILLS=(mm-story mm-enrich code-explorer)
PRESET_STORY_AGENTS=(mm-enricher mm-scoping-analyst mm-pm-reviewer)

PRESET_PIPELINE_SKILLS=(mm-story mm-blueprint mm-tdd mm-ship mm-telemetry mm-status mm-approve-plan kb-merge)
PRESET_PIPELINE_AGENTS=(mm-scoping-analyst mm-codebase-planner mm-test-architect mm-implementer mm-qa-gatekeeper mm-release-herald mm-tech-reviewer)

PRESET_ALL_SKILLS=(mm-story mm-enrich code-explorer mm-blueprint mm-tdd mm-ship mm-telemetry mm-status mm-approve-plan kb-merge claude-publish)
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
    if curl -fsSL "$REPO_RAW/skills/$name/SKILL.md" -o "$tmp" 2>/dev/null; then
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
    if curl -fsSL "$REPO_RAW/skills/$name/SKILL.md" -o "$dest" 2>/dev/null; then
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
    if curl -fsSL "$REPO_RAW/agents/$name.md" -o "$tmp" 2>/dev/null; then
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
    if curl -fsSL "$REPO_RAW/agents/$name.md" -o "$dest" 2>/dev/null; then
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
  echo "  Story creation:  mm-story  mm-enrich  code-explorer"
  echo "  Full pipeline:   mm-story  mm-blueprint  mm-tdd  mm-ship  mm-telemetry  mm-status  mm-approve-plan  kb-merge"
  echo "  Note: mm-story covers create/review/check-gap/submit/revise in one skill"
  echo ""
  echo "Available agents:"
  echo "  Story creation:  mm-enricher  mm-scoping-analyst  mm-pm-reviewer"
  echo "  Full pipeline:   mm-tech-reviewer  mm-codebase-planner  mm-test-architect"
  echo "                   mm-implementer  mm-qa-gatekeeper  mm-release-herald"
  echo ""
  echo "Presets:"
  echo "  --preset story     Story creation bundle (6 skills + 3 agents)"
  echo "  --preset pipeline  Full MM SDLC pipeline (8 skills + 7 agents)"
  echo "  --preset all       Everything (13 skills + 9 agents)"
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

# ── Install / update ──────────────────────────────────────────────────────────
echo "InCred AI — installing to ~/.claude/"
[[ "$FORCE_UPDATE" == "true" ]] && echo "(--update: overwriting existing files without prompting)"
echo ""

if [[ ${#SKILLS_TO_INSTALL[@]} -gt 0 ]]; then
  echo "Skills:"
  for skill in "${SKILLS_TO_INSTALL[@]}"; do
    install_skill "$skill"
  done
fi

if [[ ${#AGENTS_TO_INSTALL[@]} -gt 0 ]]; then
  echo ""
  echo "Agents:"
  for agent in "${AGENTS_TO_INSTALL[@]}"; do
    install_agent "$agent"
  done
fi

echo ""
echo "Done. Restart Claude Code, then run /reload-skills to activate."
