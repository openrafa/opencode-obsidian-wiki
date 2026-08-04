# Changelog

## 0.2.0

- Rename every skill to the canonical `wiki-` prefix: `autoresearch` → `wiki-autoresearch`, `canvas` → `wiki-canvas`, `defuddle` → `wiki-defuddle`, `obsidian-bases` → `wiki-bases`, `obsidian-markdown` → `wiki-markdown`, `save` → `wiki-save`, `think` → `wiki-think`.
- Add five new skills: `wiki-anki` (Anki card generation), `wiki-history` (personal history KB), `wiki-network` (people/contact recording), `wiki-ops` (safe batch operations), `wiki-travel` (travel destinations + reviews).
- Sync all skill bodies with the live shared bundle used by OpenCode / pi / omp.
- Install target moved to `~/.agents/skills/` — one shared skill directory for every agent; `--prune` flag for clean upgrades.

## 0.1.1

- `wiki-ingest`: clarify `.raw/` immutability during processing; require explicit user approval before post-ingest cleanup; require full preservation of high-value artifacts (configs, code, schemas) instead of summary-only filing.
- Add `wiki-ocr` skill for document conversion / OCR toolchain selection (OpenCode vision → Tesseract → PaddleOCR → MinerU).
- `save`: replace hardcoded personal-vault path examples with `<personal-vault>` placeholders declared via `AGENTS.md`.
- `lint-opencode-compat.sh`: reject any hardcoded `/Users/<name>/` workstation path, not a single username.

## 0.1.0

- Initial OpenCode-compatible wiki skill bundle and vault helper scripts.
