#!/usr/bin/env bash
set -euo pipefail

# Installs the wiki skill bundle.
#
# Recommended (opt-in wiki profile — other agents will not see these skills
# unless launched with `agentctl --profile wiki` / `omp --profile wiki`):
#
#   bash scripts/install.sh --profile wiki
#   # → ~/.agents/profiles/wiki/skills/
#
# Legacy (always-on, every runtime that scans ~/.agents/skills):
#
#   bash scripts/install.sh
#   bash scripts/install.sh --target ~/.agents/skills
#
#   bash scripts/install.sh --prune              # remove wiki-* in the target first
#   bash scripts/install.sh --profile wiki --prune-shared
#       # also remove leftover wiki-* from ~/.agents/skills after a profile install

TARGET=""
PROFILE=""
PRUNE=0
PRUNE_SHARED=0
DRY_RUN=0
SHARED="$HOME/.agents/skills"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:?missing value for --target}"
      shift 2
      ;;
    --profile)
      PROFILE="${2:?missing value for --profile}"
      shift 2
      ;;
    --prune)
      PRUNE=1
      shift
      ;;
    --prune-shared)
      PRUNE_SHARED=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      echo "Usage: install.sh [--dry-run] [--prune] [--prune-shared] [--profile NAME] [--target DIR]"
      echo "  default target: $SHARED  (always-on / legacy)"
      echo "  --profile wiki:  $HOME/.agents/profiles/wiki/skills"
      echo "  --prune-shared:  remove wiki-* from $SHARED (after a profile install)"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -n "$PROFILE" && -n "$TARGET" ]]; then
  echo "Use either --profile or --target, not both" >&2
  exit 1
fi

if [[ -n "$PROFILE" ]]; then
  TARGET="$HOME/.agents/profiles/${PROFILE}/skills"
fi

TARGET="${TARGET:-$SHARED}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

prune_wiki() {
  local dir="$1"
  local label="$2"
  [[ -d "$dir" ]] || return 0
  local d
  for d in "$dir"/wiki "$dir"/wiki-*; do
    [[ -d "$d" ]] || continue
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "Would remove $d  ($label)"
    else
      rm -rf "$d"
    fi
  done
}

if [[ "$PRUNE" -eq 1 ]]; then
  prune_wiki "$TARGET" "target"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Would copy $ROOT_DIR/skills -> $TARGET"
else
  mkdir -p "$TARGET"
  cp -R "$ROOT_DIR/skills"/. "$TARGET"/
fi

if [[ "$PRUNE_SHARED" -eq 1 ]]; then
  if [[ "$TARGET" == "$SHARED" ]]; then
    echo "Note: --prune-shared with target=$SHARED is the same as --prune" >&2
  fi
  prune_wiki "$SHARED" "shared ~/.agents/skills"
fi

echo "Wiki skills installation complete. Target: $TARGET"
if [[ -n "$PROFILE" ]]; then
  echo "Launch with: agentctl --profile ${PROFILE} opencode   (or: omp --profile ${PROFILE})"
  echo "See opencode-methodology/docs/skill-profiles.md"
  if [[ -d "$SHARED/wiki" || -d "$SHARED/wiki-anki" ]]; then
    echo "WARNING: wiki-* still present under $SHARED — default runtimes will keep loading them."
    echo "         Re-run with --prune-shared after you confirm the profile copy."
  fi
else
  echo "Installed as always-on skills (every agent that scans ~/.agents/skills will load them)."
  echo "For on-demand wiki loading, use: bash scripts/install.sh --profile wiki"
fi
