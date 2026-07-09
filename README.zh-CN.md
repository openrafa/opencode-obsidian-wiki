# OpenCode Wiki Skills

[English](README.md) · [中文](README.zh-CN.md)

OpenCode 兼容的 **wiki / Obsidian** agent skills。从零安装到 `~/.opencode/skills/`，不附带私有 vault 或 live 凭证。

**远程仓库名：** [openrafa/opencode-obsidian-wiki](https://github.com/openrafa/opencode-obsidian-wiki)。本地目录仍可能叫 `opencode-wiki-skills`。

**套件入口：** [opencode-methodology](https://github.com/openrafa/opencode-methodology) → [从零安装](https://github.com/openrafa/opencode-methodology/blob/main/docs/install-from-scratch.zh-CN.md)。

## 归属说明

本仓库是 [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) 的 **fork**，适配到 OpenCode。同时 **借用思路** 自 Karpathy / kepano — 请一并致谢：

| 类型 | 上游 |
| --- | --- |
| **Fork 自** — skill 包 | [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) |
| **借用思路** — compounding wiki | [Karpathy llm-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) |
| **借用思路 / substrate** — Obsidian skills | [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) |
| **外部 CLI** — 文章提取 | [kepano/defuddle](https://github.com/kepano/defuddle) |
| OpenCode 打包 / transport | 由 [Cyame](https://github.com/Cyame) 在本仓库维护 |

完整说明：[`docs/upstream.zh-CN.md`](docs/upstream.zh-CN.md) · [English](docs/upstream.md)。

## 许可

MIT — Copyright (c) 2026 [Cyame](https://github.com/Cyame)。见 [`LICENSE`](LICENSE)。

## 快速开始

1. 安装 [OpenCode](https://opencode.ai)。可选：Obsidian 桌面版 + [OMOS](https://github.com/code-yeongyu/oh-my-openagent)。
2. 启用远程出口前先读 [`docs/workflow-model.zh-CN.md`](docs/workflow-model.zh-CN.md) 与 [`docs/transport-model.zh-CN.md`](docs/transport-model.zh-CN.md)。
3. 克隆并安装：

```bash
git clone https://github.com/openrafa/opencode-obsidian-wiki.git
cd opencode-obsidian-wiki
bash scripts/install.sh --dry-run
bash scripts/install.sh
# → ~/.opencode/skills/opencode-wiki/
```

4. 通过项目或 vault 的 **`AGENTS.md`** 告诉 Agent vault 路径，见 `wiki` skill 脚手架。不要把私有 vault 路径提交到公开仓库。
5. 先在非敏感 vault 上冒烟：scaffold / `wiki-ingest` / `wiki-query` / `wiki-lint` / `save`。
6. 重型 helper 可选 [opencode-skill-runtime](https://github.com/openrafa/opencode-skill-runtime) 做 Python 隔离。

### 会落到磁盘的内容

```text
~/.opencode/skills/opencode-wiki/
├── wiki/
├── wiki-ingest/
├── wiki-query/
├── save/
└── ...
```

## 这是什么 / 不是什么

**是：** 可复用 skill bundle；OpenCode transport 文档，含 API / MCP / CLI / fs。

**不是：** 私有 vault 导出；凭证替代品；默认保证所有远程模型调用都安全。

## 文档

| 主题 | English | 中文 |
| --- | --- | --- |
| 上游 / fork | [upstream.md](docs/upstream.md) | [upstream.zh-CN.md](docs/upstream.zh-CN.md) |
| 工作流 | [workflow-model.md](docs/workflow-model.md) | [workflow-model.zh-CN.md](docs/workflow-model.zh-CN.md) |
| Transport | [transport-model.md](docs/transport-model.md) | [transport-model.zh-CN.md](docs/transport-model.zh-CN.md) |
| 兼容性 | [compatibility.md](docs/compatibility.md) | [compatibility.zh-CN.md](docs/compatibility.zh-CN.md) |
| OpenCode 改动 | [opencode-changes.md](docs/opencode-changes.md) | [opencode-changes.zh-CN.md](docs/opencode-changes.zh-CN.md) |

## 隐私

Wiki 工作流可能读取私有笔记、抓取网页或调用远程模型。逐个 review skill，远程出口保持 opt-in。
