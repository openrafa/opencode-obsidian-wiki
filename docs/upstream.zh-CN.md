# 上游与许可说明

> 语言：[English](upstream.md) · [中文](upstream.zh-CN.md)

本仓库是 [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian)
（常以 `claude-obsidian` 目录安装的 skill 包）的 OpenCode fork / 适配版。这里的
skill 工作流来自该项目，并改写为 OpenCode 可用：`AGENTS.md`、OpenCode transport、脱敏工具名。

另外，这一谱系（以及 claude-obsidian 本身）还借用了下表中的思路。若本机同时安装了
kepano 的 Obsidian substrate，请优先使用上游。

## Fork 自（请突出致谢）

| 上游 | 关系 | URL |
| --- | --- | --- |
| [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) | Fork 来源 — wiki / ingest / query / lint / save / canvas / autoresearch / mode 类 vault skill 包，适配到 OpenCode | https://github.com/AgriciDaniel/claude-obsidian |

## 借用的思路（一并致谢）

| 上游 | 借用内容 | URL |
| --- | --- | --- |
| Andrej Karpathy — llm-wiki gist | 可复利的 markdown wiki 模式（ingest / index / query，而非一次性 RAG） | https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f |
| [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) | Obsidian markdown、CLI、Bases、JSON Canvas 的权威 skill substrate | https://github.com/kepano/obsidian-skills |
| [kepano/defuddle](https://github.com/kepano/defuddle) | `defuddle` skill 使用的文章抽取 CLI | https://github.com/kepano/defuddle |
| Contextual retrieval 研究（Anthropic） | 可选 `wiki-retrieve` 分块检索背后的技术 | https://www.anthropic.com/news/contextual-retrieval |

## 本 fork 中的 OpenCode 专属部分

OpenCode transport 表述、仅 `AGENTS.md` 的项目规则、兼容性 lint，以及安装到
`~/.opencode/skills/` 的打包方式，由本仓库维护。与 kepano marketplace 重叠的
skill，在检测到 kepano 插件时让位于 kepano（见各 `SKILL.md`）。

## 许可

本仓库以 MIT License 发布 — Copyright (c) 2026
[Cyame](https://github.com/Cyame)。上游项目保留各自许可；再分发衍生材料时请保留其声明。

相关：[`opencode-changes.zh-CN.md`](opencode-changes.zh-CN.md) · [English](opencode-changes.md)。