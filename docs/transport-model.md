# Transport Model

> Language: [English](transport-model.md) · [中文](transport-model.zh-CN.md)

A wiki workflow prefers the best available transport transparently.

Recommended order:

1. Obsidian REST or local API when configured.
2. MCP tools when available.
3. CLI helpers if present.
4. Filesystem access as fallback.

Transport detection is visible to the user and cached in local vault
metadata, not in this public repository.