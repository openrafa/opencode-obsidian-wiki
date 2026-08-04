# Wiki Skills (shared agent bundle)

[English](README.md) · [中文](README.zh-CN.md)

Agent **wiki / Obsidian** skills, installed into `~/.agents/skills/` so any agent — OpenCode, pi, omp, or anything else that reads the shared skill directory — loads the same bundle. No private vault, no live credentials.

**Remote name:** [openrafa/opencode-obsidian-wiki](https://github.com/openrafa/opencode-obsidian-wiki) (local folder may still be called `opencode-wiki-skills`).

**Suite hub:** [opencode-methodology](https://github.com/openrafa/opencode-methodology) → [Get started](https://github.com/openrafa/RAFA#get-started).

## Attribution

This repo is a **fork** of [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian), adapted for agent use. It also **borrows ideas** from Karpathy / kepano — credit all of them:

| Kind | Upstream |
| --- | --- |
| **Fork of** — skill bundle | [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) |
| **Borrowed idea** — compounding wiki | [Karpathy llm-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) |
| **Borrowed idea / substrate** — Obsidian skills | [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) |
| **External CLI** — article extract | [kepano/defuddle](https://github.com/kepano/defuddle) |
| Agent packaging / transports | Maintained here by [Cyame](https://github.com/Cyame) |

Full notes: [`docs/upstream.md`](docs/upstream.md) · [中文](docs/upstream.zh-CN.md).

## Getting started

1. Pick an agent runtime that loads skills from `~/.agents/skills/` (OpenCode, pi, omp — see [tool layering](https://github.com/openrafa/opencode-methodology/blob/main/docs/tool-layering.md)).
2. Read [`docs/workflow-model.md`](docs/workflow-model.md) and [`docs/transport-model.md`](docs/transport-model.md) before enabling remote egress.
3. Clone and install:

```bash
git clone https://github.com/openrafa/opencode-obsidian-wiki.git
cd opencode-obsidian-wiki
bash scripts/install.sh --dry-run
bash scripts/install.sh
# → ~/.agents/skills/  (wiki-* skills, merge-only)
```

Upgrades: `bash scripts/install.sh --prune` removes previously-installed `wiki-*` skills before copying the fresh bundle.

4. Point the Agent at your vault via project or vault **`AGENTS.md`** (see the `wiki` skill scaffold). Do not commit private vault paths to public repos.
5. Smoke-test on a non-sensitive vault: scaffold / `wiki-ingest` / `wiki-query` / `wiki-lint` / `wiki-save`.
6. Optional Python isolation for heavy helpers: [opencode-skill-runtime](https://github.com/openrafa/opencode-skill-runtime).

### What lands on disk

```text
~/.agents/skills/
├── wiki/                    # vault scaffold + core conventions
├── wiki-anki/               # generate Anki cards from notes
├── wiki-autoresearch/       # autonomous iterative research loop
├── wiki-bases/              # Obsidian Bases (.base files)
├── wiki-canvas/             # Obsidian canvas composition
├── wiki-cli/                # vault read/write via Obsidian CLI
├── wiki-defuddle/           # web page cleanup before ingest
├── wiki-fold/               # log rollups into meta-pages
├── wiki-history/            # personal history KB conventions
├── wiki-ingest/             # source ingestion + entity extraction
├── wiki-lint/               # vault health checks
├── wiki-markdown/           # Obsidian Flavored Markdown rules
├── wiki-mode/               # vault methodology (LYT / PARA / Zettel / generic)
├── wiki-network/            # people / contact recording
├── wiki-ocr/                # document conversion / OCR toolchain
├── wiki-ops/                # safe batch operations on the vault
├── wiki-query/              # answer questions from the vault
├── wiki-retrieve/           # hybrid retrieval (BM25 + rerank)
├── wiki-save/               # file sessions / insights into the vault
├── wiki-think/              # 10-principle thinking loop
└── wiki-travel/             # travel destinations + trip reviews
```

## What this is / is not

**Is:** wiki / Obsidian skill bundle vendored from upstream + RAFA packaging; transport docs for API / MCP / CLI / fs.

**Is not:** a private vault export; a substitute for your credentials; a promise that every remote-model call is safe by default.

## Docs

| Topic | English | 中文 |
| --- | --- | --- |
| Upstream / fork | [upstream.md](docs/upstream.md) | [upstream.zh-CN.md](docs/upstream.zh-CN.md) |
| Workflows | [workflow-model.md](docs/workflow-model.md) | [workflow-model.zh-CN.md](docs/workflow-model.zh-CN.md) |
| Transports | [transport-model.md](docs/transport-model.md) | [transport-model.zh-CN.md](docs/transport-model.zh-CN.md) |
| Compatibility | [compatibility.md](docs/compatibility.md) | [compatibility.zh-CN.md](docs/compatibility.zh-CN.md) |
| OpenCode changes | [opencode-changes.md](docs/opencode-changes.md) | [opencode-changes.zh-CN.md](docs/opencode-changes.zh-CN.md) |

## Privacy

Wiki workflows may read private notes, fetch the web, or call remote models. Review each skill; keep remote egress opt-in.

## License

MIT — Copyright (c) 2026 [Cyame](https://github.com/Cyame). See [`LICENSE`](LICENSE).
