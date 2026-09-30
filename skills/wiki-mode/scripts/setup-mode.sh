#!/usr/bin/env bash
# setup-mode.sh — set the methodology mode for an Obsidian wiki vault.
#
# Writes <vault>/.vault-meta/mode.json via the vault's provisioned
# scripts/wiki-mode.py, and seeds the per-mode template folders described in
# skills/wiki-mode/SKILL.md.
#
# Usage:
#   bash scripts/setup-mode.sh [VAULT_DIR]            # interactive pick
#   bash scripts/setup-mode.sh --mode <m> [VAULT_DIR] # non-interactive (generic|lyt|para|zettelkasten)
#   bash scripts/setup-mode.sh --list [VAULT_DIR]     # show current mode and exit
#
# Provisioning: wiki-mode.py ships with the wiki-mode skill and must first be
# copied into <vault>/scripts/ (the `wiki` skill's setup-vault.sh does this).
# This script does that automatically if the helper is missing.
#
# Exit codes:
#   0 — mode written (or read with --list)
#   2 — vault directory invalid
#   3 — invalid --mode value
#   4 — non-interactive stdin and no --mode

set -euo pipefail

MODE=""
VAULT_DIR=""
LIST=0

while [ $# -gt 0 ]; do
  case "$1" in
    --mode)
      MODE="${2:?missing value for --mode}"
      shift 2
      ;;
    --list)
      LIST=1
      shift
      ;;
    -h|--help)
      sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      echo "ERR: unrecognized flag: $1" >&2
      exit 3
      ;;
    *)
      if [ -n "$VAULT_DIR" ]; then
        echo "ERR: multiple vault directories given: '$VAULT_DIR' and '$1'" >&2
        exit 3
      fi
      VAULT_DIR="$1"
      shift
      ;;
  esac
done

VAULT_DIR="${VAULT_DIR:-$PWD}"
if [ ! -d "$VAULT_DIR" ]; then
  echo "ERR: vault directory not found: $VAULT_DIR" >&2
  exit 2
fi
VAULT_DIR="$(cd "$VAULT_DIR" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERR: python3 is required but was not found on PATH." >&2
  exit 2
fi

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROUTER="$VAULT_DIR/scripts/wiki-mode.py"

# Provision the router into the vault if missing (idempotent).
if [ ! -f "$ROUTER" ]; then
  if [ ! -f "$SKILL_DIR/scripts/wiki-mode.py" ]; then
    echo "ERR: bundled router missing: $SKILL_DIR/scripts/wiki-mode.py" >&2
    exit 2
  fi
  mkdir -p "$VAULT_DIR/scripts"
  cp -f "$SKILL_DIR/scripts/wiki-mode.py" "$ROUTER"
  chmod 0755 "$ROUTER"
  echo "Provisioned scripts/wiki-mode.py into the vault."
fi

if [ "$LIST" -eq 1 ]; then
  echo "current mode: $(python3 "$ROUTER" get)"
  exit 0
fi

# -- Pick the mode -------------------------------------------------------------
if [ -n "$MODE" ]; then
  case "$MODE" in
    generic|lyt|para|zettelkasten) ;;
    *)
      echo "ERR: invalid mode '$MODE' (valid: generic, lyt, para, zettelkasten)" >&2
      exit 3
      ;;
  esac
else
  if [ ! -t 0 ]; then
    echo "ERR: non-interactive stdin; pass --mode <generic|lyt|para|zettelkasten>" >&2
    exit 4
  fi
  echo "Pick a methodology mode for this vault:"
  echo "  1) generic       — flat sources/entities/concepts (v1.7 default, zero behavior change)"
  echo "  2) lyt           — Maps of Content: mocs/ + notes/"
  echo "  3) para          — projects/ areas/ resources/ archives/"
  echo "  4) zettelkasten  — flat wiki/ with timestamp IDs, no topic folders"
  printf "Choice [1-4, default 1]: "
  read -r choice
  case "${choice:-1}" in
    1) MODE="generic" ;;
    2) MODE="lyt" ;;
    3) MODE="para" ;;
    4) MODE="zettelkasten" ;;
    *)
      echo "ERR: invalid choice: $choice" >&2
      exit 3
      ;;
  esac
fi

# -- Write the mode --------------------------------------------------------------
python3 "$ROUTER" set "$MODE"
echo "mode set: $MODE  ->  .vault-meta/mode.json"

# -- Seed per-mode template/folder scaffolding -----------------------------------
case "$MODE" in
  lyt)
    mkdir -p "$VAULT_DIR/wiki/mocs" "$VAULT_DIR/wiki/notes"
    echo "seeded: wiki/mocs/, wiki/notes/ (LYT)"
    ;;
  para)
    mkdir -p "$VAULT_DIR/wiki/projects" "$VAULT_DIR/wiki/areas" "$VAULT_DIR/wiki/resources" "$VAULT_DIR/wiki/archives"
    echo "seeded: wiki/projects/, wiki/areas/, wiki/resources/, wiki/archives/ (PARA)"
    ;;
  zettelkasten)
    echo "zettelkasten: no folder scaffolding (flat wiki/, timestamp IDs via \`python3 scripts/wiki-mode.py id\`)"
    ;;
  *)
    echo "generic: no folder scaffolding needed"
    ;;
esac

echo "Next: newly-filed pages follow '$MODE' (existing files are NOT migrated; see SKILL.md §Migration)."
