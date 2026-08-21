# Wiki Skills（共享 Agent Skill 包）

[English](README.md) · [中文](README.zh-CN.md)

Agent **wiki / Obsidian** skills。默认装到 **按需 profile**（`~/.agents/profiles/wiki/skills/`），OpenCode / Pi / OMP 不会在未选择 profile 时加载它们。始终启用安装到 `~/.agents/skills/` 仍然可用。不附带私有 vault，不含 live 凭证。

**远程仓库名：** [openrafa/opencode-obsidian-wiki](https://github.com/openrafa/opencode-obsidian-wiki)。本地目录仍可能叫 `opencode-wiki-skills`。

**套件入口：** [opencode-methodology](https://github.com/openrafa/opencode-methodology) → [快速开始](https://github.com/openrafa/RAFA#get-started)。

## 归属说明

本仓库是 [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) 的 **fork**，适配到多 agent 场景。同时 **借用思路** 自 Karpathy / kepano — 请一并致谢：

| 类型 | 上游 |
| --- | --- |
| **Fork 自** — skill 包 | [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) |
| **借用思路** — compounding wiki | [Karpathy llm-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) |
| **借用思路 / substrate** — Obsidian skills | [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) |
| **外部 CLI** — 文章提取 | [kepano/defuddle](https://github.com/kepano/defuddle) |
| Agent 打包 / transport | 由 [Cyame](https://github.com/Cyame) 在本仓库维护 |

完整说明：[`docs/upstream.zh-CN.md`](docs/upstream.zh-CN.md) · [English](docs/upstream.md)。

## 快速开始

1. 选择一个 agent 运行时（OpenCode、pi、omp — 见[工具分层](https://github.com/openrafa/opencode-methodology/blob/main/docs/tool-layering.zh-CN.md) 与 [skill profiles](https://github.com/openrafa/opencode-methodology/blob/main/docs/skill-profiles.zh-CN.md)）。
2. 启用远程出口前先读 [`docs/workflow-model.zh-CN.md`](docs/workflow-model.zh-CN.md) 与 [`docs/transport-model.zh-CN.md`](docs/transport-model.zh-CN.md)。
3. 克隆并安装 **wiki profile**（推荐）：

```bash
git clone https://github.com/openrafa/opencode-obsidian-wiki.git
cd opencode-obsidian-wiki
bash scripts/install.sh --dry-run --profile wiki
bash scripts/install.sh --profile wiki
# → ~/.agents/profiles/wiki/skills/
python3 /path/to/opencode-methodology/bin/agentctl install
agentctl --profile wiki opencode
```

始终启用（每个默认扫描 `~/.agents/skills` 的 runtime 都会加载 wiki）：

```bash
bash scripts/install.sh
# → ~/.agents/skills/wiki-*
```

升级：`bash scripts/install.sh --profile wiki --prune` 刷新 profile 拷贝。加上 `--prune-shared` 可清掉 `~/.agents/skills` 里残留的 `wiki-*`。

4. 通过项目或 vault 的 **`AGENTS.md`** 告诉 Agent vault 路径，见 `wiki` skill 脚手架。不要把私有 vault 路径提交到公开仓库。
5. 先在非敏感 vault 上冒烟：scaffold / `wiki-ingest` / `wiki-query` / `wiki-lint` / `wiki-save`。
6. 重型 helper 可选 [opencode-skill-runtime](https://github.com/openrafa/opencode-skill-runtime) 做 Python 隔离。

### 会落到磁盘的内容

```text
# 推荐：bash scripts/install.sh --profile wiki
~/.agents/profiles/wiki/skills/
├── wiki/                    # vault 脚手架 + 核心约定
├── wiki-anki/               # 从笔记生成 Anki 卡片
├── wiki-autoresearch/       # 自主迭代式调研循环
├── wiki-bases/              # Obsidian Bases（.base 文件）
├── wiki-canvas/             # Obsidian canvas 编排
├── wiki-cli/                # 通过 Obsidian CLI 读写 vault
├── wiki-defuddle/           # 入库前清理网页内容
├── wiki-fold/               # 日志归并成 meta 页面
├── wiki-history/            # 个人历史知识库约定
├── wiki-ingest/             # 来源入库 + 实体提取
├── wiki-lint/               # vault 健康检查
├── wiki-markdown/           # Obsidian Flavored Markdown 规范
├── wiki-mode/               # vault 方法论（LYT / PARA / Zettel / generic）
├── wiki-network/            # 人脉 / 联系人记录
├── wiki-ocr/                # 文档转换 / OCR 工具链
├── wiki-ops/                # vault 安全批量操作
├── wiki-query/              # 基于 vault 回答问题
├── wiki-retrieve/           # 混合检索（BM25 + 重排）
├── wiki-save/               # 会话 / 洞察归档进 vault
├── wiki-think/              # 十原则思考循环
└── wiki-travel/             # 旅行目的地 + 行程复盘
```

旧布局 / 始终启用：同样的树在 `~/.agents/skills/` 下（不带 `--profile` 的 `bash scripts/install.sh`）。

## 这是什么 / 不是什么

**是：** 上游 vendored + RAFA 打包的 wiki / Obsidian skill bundle；API / MCP / CLI / fs transport 文档。

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

## 许可

MIT — Copyright (c) 2026 [Cyame](https://github.com/Cyame)。见 [`LICENSE`](LICENSE)。
