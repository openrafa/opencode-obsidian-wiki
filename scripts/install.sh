#!/usr/bin/env bash
set -euo pipefail

TARGET="$HOME/.opencode/skills/opencode-wiki"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:?missing value for --target}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      echo "Usage: install.sh [--dry-run] [--target DIR]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Would copy $ROOT_DIR/skills -> $TARGET"
else
  mkdir -p "$TARGET"
  cp -R "$ROOT_DIR/skills"/. "$TARGET"/
fi

echo "OpenCode wiki skills installation complete. Target: $TARGET"
