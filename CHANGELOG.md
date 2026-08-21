# Changelog

## 0.3.0

- Wiki skills default to the opt-in profile directory `~/.agents/profiles/wiki/skills/` (`scripts/install.sh --profile wiki`). `--prune-shared` removes leftover `wiki-*` from `~/.agents/skills`.
- `wiki-anki`: English rewrite of the workflow; interactive model published as `交互题`; Anki MCP/AnkiConnect called without vendor tool URIs.
- `wiki-ocr`: add [anydoc](https://github.com/firecrawl/anydoc) as the text-layer path; MinerU `pipeline` extras via `uv tool install --with`; PaddleOCR CPU index recipe; no workstation-specific paths.
- `wiki-travel`: one-file-per-spot layout with generic source tags (`rec/<source-id>`). Personal creator names and private spots are not part of the published skill.
- `wiki-ops` / `wiki-network`: replace employer, school, project, and personal-name examples with placeholders.

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
