# OpenCode 兼容性

> 语言：[English](compatibility.md) · [中文](compatibility.zh-CN.md)

面向 OpenCode 发布的 skill 已做脱敏与清理。

兼容性检查应拒绝：

- 其它 agent 运行时的遗留 MCP 前缀工具名；
- 其它运行时的遗留 web-fetch / web-search 工具大小写；
- 其它工具的私有 hook 名；
- 遗留运行时家目录路径；
- 其它旧项目规则文件名（OpenCode 标准仅为 `AGENTS.md`）；
- 把厂商 / 模型产品名当作 Agent 身份（应使用 Agent）；
- 遗留 model / turn-limit 字段；
- 硬编码本机路径；
- 私有 vault 绝对路径、雇主/组织专属 vault 布局，或其它个人 Mixed-wiki 约定；
- 真实 token 或凭证。

发布改动前运行 `scripts/lint-opencode-compat.sh`。