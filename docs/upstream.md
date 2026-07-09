# Upstream and License Notes

> Language: [English](upstream.md) · [中文](upstream.zh-CN.md)

This repository is an **OpenCode fork / adaptation** of
[AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian)
(the skill bundle commonly installed as `claude-obsidian`). The skill workflows
here come from that project and are rewritten for OpenCode (`AGENTS.md`, OpenCode
transports, sanitized tool names).

Separately, this lineage (and claude-obsidian itself) **borrows ideas** from the
references below. Prefer kepano's Obsidian substrate when it is installed
alongside this bundle.

## Fork of (highlight)

| Upstream | Relationship | URL |
| --- | --- | --- |
| [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) | **Fork source** — wiki / ingest / query / lint / save / canvas / autoresearch / mode-style vault skill bundle, adapted for OpenCode | https://github.com/AgriciDaniel/claude-obsidian |

## Borrowed ideas (also credit)

| Upstream | What we borrow | URL |
| --- | --- | --- |
| Andrej Karpathy — llm-wiki gist | Compounding markdown wiki pattern (ingest / index / query instead of one-shot RAG) | https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f |
| [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) | Canonical Obsidian markdown, CLI, Bases, and JSON Canvas skill substrate | https://github.com/kepano/obsidian-skills |
| [kepano/defuddle](https://github.com/kepano/defuddle) | Article-extraction CLI used by the `defuddle` skill | https://github.com/kepano/defuddle |
| Contextual retrieval research (Anthropic) | Technique behind optional `wiki-retrieve` chunk retrieval | https://www.anthropic.com/news/contextual-retrieval |

## OpenCode-specific in this fork

OpenCode transport wording, `AGENTS.md`-only project rules, compatibility lint,
and packaging under `~/.opencode/skills/` are maintained here. Skills that
overlap kepano's marketplace **defer to kepano** when that plugin is present
(see individual `SKILL.md` files).

## License

This repository is released under the MIT License — Copyright (c) 2026
[Cyame](https://github.com/Cyame). Upstream projects keep their own licenses;
preserve their notices when redistributing derived material.

Related: [`opencode-changes.md`](opencode-changes.md) · [中文](opencode-changes.zh-CN.md).
