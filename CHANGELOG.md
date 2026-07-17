# Changelog

## 0.1.1

- `wiki-ingest`: clarify `.raw/` immutability during processing; require explicit user approval before post-ingest cleanup; require full preservation of high-value artifacts (configs, code, schemas) instead of summary-only filing.
- Add `wiki-ocr` skill for document conversion / OCR toolchain selection (OpenCode vision → Tesseract → PaddleOCR → MinerU).
- `save`: replace hardcoded personal-vault path examples with `<personal-vault>` placeholders declared via `AGENTS.md`.
- `lint-opencode-compat.sh`: reject any hardcoded `/Users/<name>/` workstation path, not a single username.

## 0.1.0

- Initial OpenCode-compatible wiki skill bundle and vault helper scripts.
