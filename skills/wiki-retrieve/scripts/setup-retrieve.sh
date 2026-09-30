#!/usr/bin/env bash
# setup-retrieve.sh — provision and run the hybrid retrieval pipeline for a vault.
#
# Copies the retrieval helpers shipped with the wiki-retrieve skill into
# <vault>/scripts/ (the helpers locate the vault as "parent of their own
# directory", so they only work from <vault>/scripts/), then drives the
# ingest pipeline described in SKILL.md.
#
# Usage:
#   bash scripts/setup-retrieve.sh [VAULT_DIR]            # full provisioning run
#   bash scripts/setup-retrieve.sh --check [VAULT_DIR]    # diagnostics only
#   bash scripts/setup-retrieve.sh --no-llm [VAULT_DIR]   # force tier-3 synthetic prefix
#   bash scripts/setup-retrieve.sh --rebuild [VAULT_DIR]  # re-chunk all pages
#
# Exit codes:
#   0 — success
#   2 — vault invalid / helper scripts missing
#   3 — Stage 1 (contextual prefix) failed
#   4 — Stage 2 (BM25 index build) failed
#   5 — Stage 3 (smoke query) failed

set -euo pipefail

CHECK=0
NO_LLM=0
REBUILD=0
VAULT_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --check)   CHECK=1; shift ;;
    --no-llm)  NO_LLM=1; shift ;;
    --rebuild) REBUILD=1; shift ;;
    -h|--help)
      sed -n '2,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      echo "ERR: unrecognized flag: $1" >&2
      exit 6
      ;;
    *)
      if [ -n "$VAULT_DIR" ]; then
        echo "ERR: multiple vault directories given: '$VAULT_DIR' and '$1'" >&2
        exit 6
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

if [ ! -d "$VAULT_DIR/wiki" ]; then
  echo "ERR: $VAULT_DIR does not look like a wiki vault (no wiki/ directory)." >&2
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERR: python3 is required by the retrieval pipeline but was not found on PATH." >&2
  exit 2
fi

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPERS=(contextual-prefix.py bm25-index.py retrieve.py rerank.py)

for helper in "${HELPERS[@]}"; do
  if [ ! -f "$SKILL_DIR/scripts/$helper" ]; then
    echo "ERR: bundled helper missing: $SKILL_DIR/scripts/$helper" >&2
    exit 2
  fi
done

echo "== wiki-retrieve setup =="
echo "vault: $VAULT_DIR"

# -- Stage 0: provision helpers + directories -------------------------------
mkdir -p "$VAULT_DIR/scripts" "$VAULT_DIR/.vault-meta/chunks" "$VAULT_DIR/.vault-meta/bm25"

for helper in "${HELPERS[@]}"; do
  cp -f "$SKILL_DIR/scripts/$helper" "$VAULT_DIR/scripts/$helper"
  chmod 0755 "$VAULT_DIR/scripts/$helper"
done
echo "[ok] provisioned ${#HELPERS[@]} helper scripts into scripts/"

# -- Stage 1: contextual prefix (gated; consent per SKILL.md privacy rules) --
# Without --allow-egress, contextual-prefix.py always runs the on-machine
# synthetic tier, so the default here never sends page bodies off-machine.
PREFIX_ARGS=(--all)
[ "$NO_LLM" -eq 1 ] && PREFIX_ARGS+=(--no-llm)
[ "$REBUILD" -eq 1 ] && PREFIX_ARGS+=(--rebuild)

echo "[..] stage 1: contextual prefix ($( [ "$NO_LLM" -eq 1 ] && echo 'synthetic (forced)' || echo 'tier auto, egress off' ))"
if [ "$CHECK" -eq 1 ]; then
  python3 "$VAULT_DIR/scripts/contextual-prefix.py" --peek || true
else
  if ! python3 "$VAULT_DIR/scripts/contextual-prefix.py" "${PREFIX_ARGS[@]}"; then
    echo "ERR: contextual-prefix.py failed; fix the error above and re-run." >&2
    exit 3
  fi
fi

# -- Stage 2: BM25 index ------------------------------------------------------
if [ "$CHECK" -eq 1 ]; then
  echo "[..] stage 2: BM25 index (check mode: skipped)"
else
  echo "[..] stage 2: BM25 index build"
  if ! python3 "$VAULT_DIR/scripts/bm25-index.py" build; then
    echo "ERR: bm25-index.py build failed." >&2
    exit 4
  fi
fi

# -- Stage 3: smoke query ------------------------------------------------------
if [ "$CHECK" -eq 1 ]; then
  echo "[..] stage 3: smoke query (check mode: skipped)"
  echo "== check complete: helpers present, no provisioning done =="
  exit 0
fi

echo "[..] stage 3: smoke query 'wiki'"
SMOKE_JSON="$(mktemp "${TMPDIR:-/tmp}/wiki-retrieve-smoke.XXXXXX")"
if python3 "$VAULT_DIR/scripts/retrieve.py" "wiki" --top 5 >"$SMOKE_JSON"; then
  echo "[ok] smoke query returned: $(python3 -c "import json;print(len(json.load(open(\"$SMOKE_JSON\")).get(\"candidates\",[])),'candidate(s)')" 2>/dev/null || echo "see $SMOKE_JSON")"
else
  rc=$?
  echo "ERR: smoke query failed (exit $rc)." >&2
  exit 5
fi

# -- Rerank prerequisite report ------------------------------------------------
echo "[..] rerank prerequisite: probing ollama at http://127.0.0.1:11434"
OLLAMA_PROBE="$(python3 - <<'PY'
import json, urllib.request
try:
    with urllib.request.urlopen("http://127.0.0.1:11434/api/tags", timeout=2) as r:
        tags = [m.get("name", "") for m in json.load(r).get("models", [])]
    if any(t.startswith("nomic-embed-text") for t in tags):
        print("ok")
    else:
        print("model-missing")
except Exception:
    print("no")
PY
)" || OLLAMA_PROBE="no"
case "$OLLAMA_PROBE" in
  ok)
    echo "[ok] rerank: ollama + nomic-embed-text available (dense rerank enabled)"
    ;;
  model-missing)
    echo "[note] rerank: ollama is up but 'nomic-embed-text' is missing — pipeline works BM25-only. Install with: ollama pull nomic-embed-text"
    ;;
  *)
    echo "[note] rerank: ollama unavailable — pipeline works BM25-only (rerank.py degrades to no-op). Install ollama and 'ollama pull nomic-embed-text' for dense rerank."
    ;;
esac

echo "== wiki-retrieve provisioned =="
echo "Try: python3 scripts/retrieve.py \"your question\" --top 5   (from the vault root)"
