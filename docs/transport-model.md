# Transport Model

> Language: [English](transport-model.md) · [中文](transport-model.zh-CN.md)

A wiki workflow should prefer the best available transport while remaining clear
about what is happening.

Recommended order:

1. Obsidian REST or local API when explicitly configured.
2. MCP tools when available in the agent environment.
3. CLI helpers when present in the vault.
4. Filesystem access as a fallback.

Transport detection should be visible to the user and cached in local vault
metadata, not in this public repository.
