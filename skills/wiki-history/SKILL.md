---
name: wiki-history
description: >
  History knowledge base management rules. Covers directory structure, document templates,
  writing style, H1 title localization, cross-referencing, and iterative enrichment workflows
  for the personal history wiki under `<VAULT_ROOT>/wiki/personal/history/`.
  Triggers on: "history", "historical", "历史", "整理历史", "历史文档", "history wiki",
  "history skill", "历史规则", "历史方法论", "历史笔记",
  "补充", "完善", "添加", "充实", "深化", "丰富" + "历史" or "wiki".
allowed-tools: Read Write Edit Glob Grep Bash
---

# wiki-history: History Knowledge Base Rules

This skill standardizes the format, structure, and workflow for the personal history wiki.
History is vast — these rules ensure consistency so that enrichment can happen incrementally
without rewriting earlier work.

---

## Directory Structure

```
<VAULT_ROOT>/wiki/personal/history/
├── _index.md                          # Master index with 3 dimensions
├── civilizations/                     # Non-national ancient civilizations
│   ├── <civilization>/
│   │   ├── _index.md
│   │   ├── events/
│   │   └── people/
├── regions/                           # National/regional histories
│   ├── <region>/
│   │   ├── _index.md
│   │   ├── events/<era>/              # Grouped by historical era
│   │   └── subjects/
│   │       ├── people/
│   │       ├── places/
│   │       └── nations/               # Indigenous nations, tribes, ethnic groups
└── themes/                            # Cross-civilization, cross-regional topics
    ├── <theme>/
    │   ├── _index.md
    │   ├── events/
    │   └── people/
```

### Dimension Rules

- **Regions** — Modern nation-states or geographic regions. Use for political, social, cultural evolution of a specific area.
- **Civilizations** — Non-national cultural spheres (e.g., "ancient Greece" was not one country). Use for understanding pre-modern, pre-national histories.
- **Themes** — Global horizontal topics spanning multiple civilizations/regions. Use for understanding transnational processes.

### File Naming

- **Directory names**: lowercase with underscores, e.g., `america_indigenous`, `ancient_greece`
- **File names**: Use the local/English name in Title Case with Spaces, e.g., `Punic Wars.md`, `Washington, George.md`
- **Chinese/Japanese content**: Chinese files use Chinese filenames; Japanese files use Japanese filenames with `<ruby>` in H1 only
- **Never use kebab-case** for new files: ~~`punic-wars.md`~~ → `Punic Wars.md`

---

## Document Types & Frontmatter

All history documents use YAML frontmatter with this minimum set:

```yaml
---
type: event|person|nation
status: active|draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [history, <domain>, <subdomain>]
---
```

| Field | Values | Notes |
|-------|--------|-------|
| `type` | `event`, `person`, `nation` | Required. No other types. |
| `status` | `active`, `draft` | `draft` = skeleton/placeholder needing enrichment |
| `created` | ISO date | Creation date, never changed |
| `updated` | ISO date | Last modification date |
| `tags` | Array | Always starts with `history`. Second tag = domain (`america`, `civilizations`, `cold_war`, etc.) |

---

## H1 Title Localization Rule

**The document filename stays in its original language. The H1 heading MUST be in Chinese or use `<ruby>` annotation.**

### Event Titles

Use standard Chinese historical translations:

```markdown
# 布匿战争
# 伯罗奔尼撒战争
# 古巴导弹危机
# 明治维新与日本帝国主义
```

### Person Titles

Format: `中文名（Original Name，生卒年）`

```markdown
# 华盛顿（George Washington，1732–1799）
# 毛泽东（Mao Zedong，1893–1976）
# 阿育王（Ashoka，约前304–前232）
```

If lifespan is unknown, omit it:
```markdown
# 塞阔雅（Sequoyah）
```

### Nation/Tribe Titles

Use the most common Chinese transliteration or descriptive name:

```markdown
# 拉科塔
# 豪德诺索尼
# 梅蒂人
```

### Ruby Annotation for Foreign Terms

When the title contains foreign terms that need pronunciation/translation guidance, use `<ruby>`:

```markdown
# <ruby>東京都<rt>とうきょう</rt></ruby>
# <ruby>漢字<rt>かんじ</rt></ruby>
```

**Note**: Obsidian wikilinks do NOT support `<rt>` rendering. Use plain text in wikilink targets:
```markdown
[[東京都]]  <!-- correct -->
[[<ruby>東京都<rt>とうきょう</rt></ruby>]]  <!-- wrong -->
```

---

## Writing Style

### Tone

- **冷静、克制、分析性** — Present complexity without moralizing. Avoid "伟大" "辉煌" "罪恶" without qualification.
- **多视角** — When appropriate, note how different groups experienced the same event.
- **具体而非抽象** — Use dates, names, places, numbers. Avoid vague generalizations.
- **因果链** — Explain "为什么发生" and "为什么重要", not just "发生了什么".

### Language

- Main text in **Chinese**.
- Proper nouns (names, places, technical terms) keep their **original language** and use `<ruby>` for the first occurrence:
  ```markdown
  <ruby>Carthage<rt>迦太基</rt></ruby> 的雇佣兵
  ```
- Date format: Chinese numerals + Gregorian/BC year:
  ```markdown
  前 264 年、1972 年 6 月、18 世纪
  ```
- Currency, measurements: Keep original with conversion in parentheses if helpful.

### Prohibited Patterns

- ❌ **Moral absolutism**: "X was evil" → "X's policies resulted in Y deaths"
- ❌ **Presentism**: Judging past actors by modern standards without noting the anachronism
- ❌ **Great man theory alone**: Acknowledge structural factors alongside individual agency
- ❌ **National mythologizing**: Note contested narratives

---

## Document Templates

### Event Document (`type: event`)

```markdown
---
type: event
status: draft
created: 2026-07-15
updated: 2026-07-15
tags: [history, america, modern-america]
---

# 水门事件

> 1972 年 6 月，五人闯入民主党全国委员会水门大厦办公室装窃听器...

## 概览

- **时间**：1972 年 6 月 17 日 – 1974 年 8 月 9 日
- **地点**：华盛顿水门大厦
- **关键人物**：[[Richard Nixon]]、[[Bob Woodward]]、[[Carl Bernstein]]
- **前事**：[[越南战争]]与反文化不信任
- **后事**：竞选财务改革；总统权力制衡讨论

## 历史背景

[Context leading to the event. Include structural factors, not just immediate triggers.]

## 事件经过

[Chronological narrative. Use sub-headings for phases if complex.]

### 第一阶段（1972）

### 第二阶段（1973–1974）

## 影响与意义

[Short-term and long-term consequences. Note unintended effects.]

## 关联事件

- [[Related Event A]]
- [[Related Event B]]

## 关联人物

- [[Person A]] — role description
- [[Person B]] — role description
```

**Required sections**: 概览、历史背景、事件经过、影响与意义
**Optional sections**: 关联事件、关联人物（if not covered elsewhere)

### Person Document (`type: person`)

```markdown
---
type: person
status: draft
created: 2026-07-15
updated: 2026-07-15
tags: [history, america, people]
---

# 华盛顿（George Washington，1732–1799）

> 大陆军总司令、制宪会议主席、首任总统...

## 生平

[Chronological biography with analytical commentary.]

## 关键事实

- Appointed Chancellor on January 30, 1933
- Orchestrated remilitarization...

## 关联事件

- [[Event A]]
- [[Event B]]

## 关联人物

- [[Person A]] — relationship description
```

**Required sections**: 生平
**Optional sections**: 关键事实、关联事件、关联人物

### Nation Document (`type: nation`)

```markdown
---
type: nation
status: draft
created: 2026-07-15
updated: 2026-07-15
tags: [history, america_indigenous, nations]
---

# 拉科塔

> Teton 三支占大平原中心舞台...

## 族源与社会结构

[Origins, language family, social organization, religion.]

## 历史节点

[Key historical moments in chronological order.]

## 当代地位

[Current situation, challenges, revitalization efforts.]

## 关联事件

- [[Event A]]

## 关联民族/部落

- [[Nation A]] — relationship
```

**Required sections**: 族源与社会结构、历史节点
**Optional sections**: 当代地位、关联事件、关联民族/部落

---

## Cross-Referencing Rules

### Wikilink Format

Always use **vault-relative paths** from the history root:

```markdown
[[wiki/personal/history/regions/america/events/Modern America/Watergate|水门事件]]
[[wiki/personal/history/civilizations/ancient_rome/events/Punic Wars|布匿战争]]
```

For same-region links, use relative paths within the region:
```markdown
[[events/Modern America/Watergate|水门事件]]
[[subjects/people/Washington, George|华盛顿]]
```

### Link Text

- Use **Chinese** for link text (the part after `|`)
- Keep the target path in **original language** (matching the filename)

### Bidirectional Linking

When creating a new event/person page, check existing pages for references and add backlinks:

```markdown
## 关联事件
- [[Event A]] — 前因
- [[Event B]] — 后果
```

---

## Iterative Enrichment Workflow

History is too vast to capture in one pass. The workflow is **skeleton → context → detail → connection**:

### Phase 1: Skeleton

Create the document with:
- Correct frontmatter
- H1 title in Chinese
- One-sentence quote-block summary
- 概览 section with basic metadata
- Status: `draft`

### Phase 2: Context

Add:
- 历史背景 section
- Basic chronology in 事件经过
- Key figures mentioned

### Phase 3: Detail

Enrich with:
- Specific dates, numbers, quotes
- Sub-phases for complex events
- Multiple perspectives (victor vs. vanquished, colonizer vs. colonized)
- Status update to `active`

### Phase 4: Connection

Add:
- Wikilinks to related events and people
- Backlinks from related pages
- Tags for thematic indexing
- Cross-dimensional links (e.g., link a regional event to its theme entry)

### Enrichment Triggers

When the user says "reinforce", "enrich", "deepen", "add detail to", or mentions a specific person/event in conversation:

1. Read the existing page
2. Identify what phase it's in
3. Ask what aspect to deepen (or propose based on conversation context)
4. Enrich that aspect while maintaining existing style
5. Update `updated` field in frontmatter
6. Add new wikilinks for any newly mentioned entities

---

## Quality Checklist

Before marking a page as `active`:

- [ ] H1 is in Chinese or uses `<ruby>`
- [ ] Frontmatter has all required fields
- [ ] Quote-block summary exists and is ≤ 2 sentences
- [ ] All proper nouns have `<ruby>` on first occurrence
- [ ] All dates use consistent format (中文数字 + 公元纪年)
- [ ] Wikilinks use vault-relative paths
- [ ] No moral absolutism without qualification
- [ ] Page is linked from at least one `_index.md` or related page
- [ ] `updated` field is current

---

## Index Maintenance

Each subdirectory has an `_index.md` that serves as:
1. **Directory listing** — All child pages with brief descriptions
2. **Narrative overview** — How the pieces fit together
3. **Navigation hub** — Links to related dimensions

When adding a new page, update the relevant `_index.md`:

```markdown
## 现代美国 Modern America

- [[Watergate|水门事件]] — 宪政危机与总统辞职
- [[Civil Rights Movement|民权运动]] — 种族平等斗争
```

---

## Special Cases

### Indigenous History

For First Nations, Native American, Aboriginal, and other indigenous histories:

- Use **self-designated names** when known (e.g., `Haudenosaunee` not `Iroquois`)
- Note colonial naming in parentheses on first use: `Haudenosaunee（欧洲人称为 "Iroquois"）`
- Include both indigenous and colonial perspectives where records exist
- Acknowledge gaps in the historical record due to colonial erasure

### Multi-Region Events

Events that span multiple regions (e.g., World War I, Cold War):

- Create the primary entry under `themes/`
- Create regional perspectives under each `regions/<region>/events/`
- Link them bidirectionally
- Regional entries should note the local experience, not repeat global narrative

### Living Persons

For contemporary historical figures still living:

- Use `（YYYY–）` format for open-ended lifespan
- Keep `status: draft` until their historical significance stabilizes
- Focus on completed actions, not speculation
