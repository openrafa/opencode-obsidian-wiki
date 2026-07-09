# OpenCode 改动说明

> 语言：[English](opencode-changes.md) · [中文](opencode-changes.zh-CN.md)

公开包移除或改写了其它 agent 运行时的假设：

- 工具名使用 OpenCode 兼容表述。
- 私有 hook 引用改为通用 write-hook 语言。
- 遗留运行时路径替换为 OpenCode 路径。
- Token 示例均为占位符。
- Vault 脚本以显式 helper 文件形式打包。
