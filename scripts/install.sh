#!/usr/bin/env bash
set -euo pipefail

# Installs the wiki skill bundle into the shared agent-skills directory so any
# agent (OpenCode, pi, omp, ...) can load it. Merge-only by default: skills
# this repo does not own are never touched.
#
#   bash scripts/install.sh            # → ~/.agents/skills/
#   bash scripts/install.sh --prune    # remove previously-installed wiki-* first
#   bash scripts/install.sh --target DIR
#   bash scripts/install.sh --dry-run

TARGET="$HOME/.agents/skills"
PRUNE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:?missing value for --target}"
      shift 2
      ;;
    --prune)
      PRUNE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      echo "Usage: install.sh [--dry-run] [--prune] [--target DIR]"
      echo "  default target: $HOME/.agents/skills (shared across agents)"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "$PRUNE" -eq 1 ]]; then
  for d in "$TARGET"/wiki*; do
    [[ -d "$d" ]] || continue
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "Would remove $d"
    else
      rm -rf "$d"
    fi
  done
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Would copy $ROOT_DIR/skills -> $TARGET"
else
  mkdir -p "$TARGET"
  cp -R "$ROOT_DIR/skills"/. "$TARGET"/
fi

echo "Wiki skills installation complete. Target: $TARGET"
echo "Skills are now shared by every agent that reads ~/.agents/skills."
