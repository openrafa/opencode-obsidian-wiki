#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Match legacy identity/paths/tools — not bare upstream repo URLs used in attribution.
legacy_cli_mcp="cla""ude mcp"
legacy_home="~/.""cla""ude"
legacy_md="CLA""UDE.md"
legacy_product="Cla""ude Code"
legacy_token="ANTH""ROPIC""_AUTH_TOKEN"
patterns=(
  'mcp''__'
  'Post''ToolUse'
  'Web''Fetch'
  'Web''Search'
  "${legacy_cli_mcp}"
  "${legacy_home}"
  "${legacy_md}"
  "${legacy_product}"
  '/Users/''[A-Za-z0-9._-]+'
  'model:'' sonnet'
  'max''Turns'
  "${legacy_token}"
  'sk-''[A-Za-z0-9]{12,}'
  'Bearer ''[A-Fa-f0-9]{16,}'
)
PATTERN="$(IFS='|'; echo "${patterns[*]}")"

if command -v rg >/dev/null 2>&1; then
  rg -n "$PATTERN" "$ROOT_DIR" && exit 1 || exit 0
fi

if grep -R -n -E "$PATTERN" "$ROOT_DIR"; then
  exit 1
fi
