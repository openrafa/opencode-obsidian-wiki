# Transport 模型

> 语言：[English](transport-model.md) · [中文](transport-model.zh-CN.md)

Wiki 工作流应优先使用当前可用的最佳 transport，并对用户保持透明。

推荐顺序：

1. 已显式配置时：Obsidian REST 或本地 API。
2. Agent 环境可用时：MCP 工具。
3. vault 中存在时：CLI 辅助。
4. 回退：直接 filesystem 访问。

Transport 探测应对用户可见，并缓存在本机 vault 元数据中，而不是写进本公开仓库。
