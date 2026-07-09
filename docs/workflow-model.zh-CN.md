# 工作流模型

> 语言：[English](workflow-model.md) · [中文](workflow-model.zh-CN.md)

Wiki skills 围绕常见知识库操作组织：

- Ingest：把外部来源编译成结构化笔记。
- Retrieve：用 BM25 与可选 rerank 检索本地上下文。
- Query：带引用地查询 vault。
- Lint：检查元数据、链接、地址计数与结构约定。
- Save：写入可沉淀的会话笔记。
- Mode：按 vault 方法论路由新页面。
- Fold：把日志条目折叠成更高层页面。

每个工作流都应写明：是否读、写、抓取远程内容，或调用本机以外的模型。