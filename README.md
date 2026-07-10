# OpenCode Wiki Skills

[English](README.md) · [中文](README.zh-CN.md)

OpenCode-compatible **wiki / Obsidian** agent skills. Install from scratch into `~/.opencode/skills/` — no private vault and no live credentials included.

**Remote name:** [openrafa/opencode-obsidian-wiki](https://github.com/openrafa/opencode-obsidian-wiki) (local folder may still be called `opencode-wiki-skills`).

**Suite hub:** [opencode-methodology](https://github.com/openrafa/opencode-methodology) → [Install from scratch](https://github.com/openrafa/opencode-methodology/blob/main/docs/install-from-scratch.md).

## Attribution

This repo is a **fork** of [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian), adapted for OpenCode. It also **borrows ideas** from Karpathy / kepano — credit all of them:

| Kind | Upstream |
| --- | --- |
| **Fork of** — skill bundle | [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) |
| **Borrowed idea** — compounding wiki | [Karpathy llm-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) |
| **Borrowed idea / substrate** — Obsidian skills | [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) |
| **External CLI** — article extract | [kepano/defuddle](https://github.com/kepano/defuddle) |
| OpenCode packaging / transports | Maintained here by [Cyame](https://github.com/Cyame) |

Full notes: [`docs/upstream.md`](docs/upstream.md) · [中文](docs/upstream.zh-CN.md).

## Getting started

1. Install [OpenCode](https://opencode.ai). Optional: Obsidian desktop + [OMOS](https://github.com/code-yeongyu/oh-my-openagent).
2. Read [`docs/workflow-model.md`](docs/workflow-model.md) and [`docs/transport-model.md`](docs/transport-model.md) before enabling remote egress.
3. Clone and install:

```bash
git clone https://github.com/openrafa/opencode-obsidian-wiki.git
cd opencode-obsidian-wiki
bash scripts/install.sh --dry-run
bash scripts/install.sh
# → ~/.opencode/skills/opencode-wiki/
```

4. Point the Agent at your vault via project or vault **`AGENTS.md`** (see the `wiki` skill scaffold). Do not commit private vault paths to public repos.
5. Smoke-test on a non-sensitive vault: scaffold / `wiki-ingest` / `wiki-query` / `wiki-lint` / `save`.
6. Optional Python isolation for heavy helpers: [opencode-skill-runtime](https://github.com/openrafa/opencode-skill-runtime).

### What lands on disk

```text
~/.opencode/skills/opencode-wiki/
├── wiki/
├── wiki-ingest/
├── wiki-query/
├── save/
└── ...
```

## What this is / is not

**Is:** wiki / Obsidian skill bundle vendored from upstream + RAFA packaging; OpenCode transport docs (API / MCP / CLI / fs).

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
