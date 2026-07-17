# OpenCode Compatibility

> Language: [English](compatibility.md) · [中文](compatibility.zh-CN.md)

The copied skills have been sanitized for OpenCode-facing publication.

Compatibility checks should reject:

- legacy MCP-prefixed tool names from other agent runtimes;
- legacy web-fetch and web-search tool casing from other runtimes;
- private hook names from other tools;
- legacy runtime home-directory paths;
- legacy alternate project-rules filenames (OpenCode standard is `AGENTS.md` only);
- legacy vendor/model product names used as agent identity (use Agent);
- legacy model and turn-limit fields;
- hardcoded workstation paths;
- private vault absolute paths, employer/org-specific vault layouts, or other personal Mixed-wiki conventions;
- live tokens or credentials.

Run `scripts/lint-opencode-compat.sh` before publishing changes.