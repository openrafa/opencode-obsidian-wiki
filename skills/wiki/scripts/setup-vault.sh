#!/usr/bin/env bash
# setup-vault.sh — provision wiki runtime helper scripts into an Obsidian vault.
#
# Copies the vault-runtime helpers shipped with the wiki skill bundle into
# <vault>/scripts/ so the skills' vault-relative invocations
# (python3 scripts/wiki-mode.py route ..., bash scripts/wiki-lock.sh acquire ...)
# resolve against the vault instead of the skill install directory.
#
# Every helper locates the vault as "parent of the directory it lives in",
# so they only work once they sit in <vault>/scripts/.
#
# Usage:
#   bash scripts/setup-vault.sh [VAULT_DIR]   # default: current directory
#
# Idempotent: safe to re-run; files are overwritten with the bundled copies.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT_DIR="${1:-$PWD}"

if [ ! -d "$VAULT_DIR" ]; then
  echo "ERR: vault directory not found: $VAULT_DIR" >&2
  exit 2
fi
VAULT_DIR="$(cd "$VAULT_DIR" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERR: python3 is required by the wiki helpers but was not found on PATH." >&2
  exit 3
fi

HELPERS=(
  wiki-mode.py
  wiki-lock.sh
  allocate-address.sh
  tiling-check.py
  boundary-score.py
)

mkdir -p "$VAULT_DIR/scripts"

copied=0
for helper in "${HELPERS[@]}"; do
  if [ ! -f "$SKILL_DIR/scripts/$helper" ]; then
    echo "ERR: bundled helper missing: $SKILL_DIR/scripts/$helper" >&2
    exit 4
  fi
  cp -f "$SKILL_DIR/scripts/$helper" "$VAULT_DIR/scripts/$helper"
  chmod 0755 "$VAULT_DIR/scripts/$helper"
  copied=$((copied + 1))
done

# detect-transport.sh ships with the wiki-cli skill; provision it too when the
# sibling skill was installed alongside this one.
if [ -f "$SKILL_DIR/../wiki-cli/scripts/detect-transport.sh" ]; then
  cp -f "$SKILL_DIR/../wiki-cli/scripts/detect-transport.sh" "$VAULT_DIR/scripts/detect-transport.sh"
  chmod 0755 "$VAULT_DIR/scripts/detect-transport.sh"
  copied=$((copied + 1))
else
  echo "NOTE: wiki-cli skill not found next to this skill; skipped detect-transport.sh." >&2
fi

echo "Provisioned $copied helper script(s) into $VAULT_DIR/scripts/"
echo "Next: bash scripts/detect-transport.sh   # write .vault-meta/transport.json (from the vault root)"
