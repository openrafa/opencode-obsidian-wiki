---
name: wiki-network
description: >
  Network and contact recording rules. Standardizes network.md classification logic, field formats,
  and note writing conventions. For maintaining personal and professional connection pages.
  Triggers on: "人脉", "network", "联系人", "认识谁", "人脉记录", "人际关系".
allowed-tools: Read Write Edit Glob Grep Bash
---

# wiki-network: Network Recording Rules

> **NOTE: 2026-07-17 - Architecture changed.** 人脉数据已从 `wiki/personal/collection/network.md` 单一大表迁至每人一页的笔记库（`wiki/personal/collection/network/<名>.md`），通过 `wiki/meta/network.base`（Obsidian Bases）提供多层级查询。以下规则反映新架构。

---

## Data Model

Each person is a standalone note under `wiki/personal/collection/network/`, queried via `wiki/meta/network.base`.

- **Note path**: `wiki/personal/collection/network/<真名>.md` (use 圈名 or 称呼 if real name unknown)
- **Database view**: `wiki/meta/network.base` — 7 views (全部/同事/同学/朋友/家人/字幕组/鸟友)
- **Photos**: Drop into `_attachments/people/<笔记文件名>.<ext>` then run `.scripts/migrate_network.py --sync-photos` to auto-link
- **Migration script**: `.scripts/migrate_network.py` (stdlib, create-only, dry-run by default)

### Frontmatter Schema

| Field | Type | Description |
|-------|------|-------------|
| type | string | Fixed `person` |
| 真名 | string | Real name (optional) |
| 称呼 | string | Daily name / nickname |
| 圈名 | string | In-group name (e.g. fansub circles) |
| aliases | list | All known names for search/link completion (exclude the filename itself) |
| category | list | 同事/同学/朋友/家人 (multi-value, **YAML list**) |
| group | list | Secondary grouping (九天/北大附中/字幕组/鸟友…, multi-value, **YAML list**) |
| 来源 | string | Department / school / how you met |
| 办公地 | string | Office city (colleague-type) |
| 关系 | string | Relationship detail (family / partner's-family type) |
| 中间人 | string | Who introduced you (second-degree relationship) |
| 生日 | string | `MM-DD` or `YYYY-MM-DD` |
| 生日月 | number | Derived field, script auto-calculates, never fill manually |
| 离职 | boolean | True when 备注 contains "已离职", script auto |
| photo | string | `"[[_attachments/people/<name>.<ext>]]"`, script `--sync-photos` auto-fills |
| 备注 | string | Free-form note; also duplicated as first line of body |
| tags | list | At minimum `人脉` |

Omit empty fields (formula and base treat missing keys as falsy). Body first line = 备注 content if present, otherwise blank.

---

## Interactive Addition

When the user describes a person to add, follow this procedure.

**Example user prompts:**
- 「把张三加进 network，同事，九天团队，办公地西安」
- 「字幕组加了新人，圈名 misaka，真名不知道」
- 「帮我补上李四的生日，6 月 15」

**Sisyphus procedure:**
1. **Confirm classification**: Determine `category` and `group` (reference existing group names, never invent new ones)
2. **Determine filename**: Priority order 真名 → 圈名 → 称呼. Sanitize filesystem-forbidden characters. If collision, append ` (组名)` suffix
3. **Generate frontmatter**: `type=person`, omit empty fields, collect all known names ≠ filename into `aliases`, duplicate 备注 as body first line
4. **Write note**: `wiki/personal/collection/network/<key>.md` (create-only; if exists, mutate fields instead of overwriting)
5. **Report**: State the created/modified note path

**Important:**
- **group and category are always YAML lists**: write `group:\n  - 字幕组`, not `group: 字幕组`, even for single values
- **Never rename after creation**: later real-name discovery goes into `aliases` to keep wikilinks intact
- **Wikilink style**: vault-root absolute path, e.g. `[[wiki/personal/collection/network/严少飞]]`, never `../` relative
- **Batch additions**: edit `wiki/personal/collection/network.md` group tables then rerun `migrate_network.py --write`; single additions go straight to individual notes
- **Script never overwrites existing notes** (create-only write strategy), safe for manual edits

---

## Classification Logic (reference)

The following classification is preserved **for reference when determining `category` / `group` for new entries**. It describes the old single-table structure but the logic still applies.

Group headings by "where you met them", **not by relationship type**.

| Heading | Meaning |
|---------|---------|
| `## 九天` | Everyone met during 九天人工智能 (including model engineering R&D center, contractors, vendors) |
| `## 中移集团` | Everyone met at the group (research institute departments, party school, cooperation department, integration, branches) |
| `## 同学 / 朋友 & 网友` | Everyone met in non-work contexts |

- People who have left a company are not moved to a separate "former colleague" heading; keep them under their original organization heading with a note "已离职" (left company)

---

## Field Conventions

These conventions now apply to frontmatter fields in individual person notes (previously applied to table rows in network.md).

**来源 field**: Write the specific unit/department, e.g., "模型工程研发中心" (Model Engineering R&D Center), "战略所" (Strategy Institute), "科大讯飞" (iFlytek), "外协" (Contractor). Do not repeat the heading name.

**备注 field**: Do not write WeChat names (unmaintainable). Write scene information or stories:
- Colleague scenes: "同期" (same cohort), "聚智团队" (Juzhi team), "已离职去广发证券" (left for GF Securities), "产品经理" (product manager)
- Friend scenes: Concisely record how you met and the relationship, e.g., "西双版纳驴友，爬过茶马古道" (Xishuangbanna travel buddy, hiked Tea Horse Road), "通过老张介绍，偶尔一起打球" (Introduced by Lao Zhang, occasionally play ball together)
- All notes should be concise, one sentence

**All fields are optional**. Leave blank if unknown, do not force-fill.

---

## Real-Name Discipline

- **Use real names only in wiki documents and body text**; nicknames are reserved only in the 称呼 / 圈名 fields of the frontmatter
- Before writing any person's name, check `<VAULT_ROOT>/work/<Organization>/team.md` (or user's custom team roster file) to confirm the real name
- Do not write nicknames from memory (e.g., "老王", "大石总", "滢滢")
