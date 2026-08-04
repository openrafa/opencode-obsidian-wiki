---
name: wiki-travel
description: >
  Travel destination management and review rules. Covers domestic/overseas destination file formats,
  travel plan ingestion and review workflows, #todo tagging, and birdwatching spot logging.
  For organizing and archiving travel-related wiki content.
  Triggers on: "旅行", "目的地", "复盘", "旅行计划", "拾遗", "景区", "游记",
  "国内旅行", "海外旅行", "观鸟".
allowed-tools: Read Write Edit Glob Grep Bash
---

# wiki-travel: Travel Destination Management

This skill standardizes the format and workflow for destination files, travel plans, and review archiving under `<VAULT_ROOT>/wiki/personal/travel/` (or the user's custom travel directory).

---

## Directory Structure

```
<VAULT_ROOT>/wiki/personal/travel/
├── destinations/
│   ├── domestic/<Province>/<City or District>.md
│   └── overseas/<Country>/<First-level Division>/<City>.md
├── birdwatching.md
└── [Travel Plan Files].md
```

---

## Domestic Destinations

**Path**: `<VAULT_ROOT>/wiki/personal/travel/destinations/domestic/<Province>/<City or District>.md` (or user's custom travel directory)

- One folder per province, one `.md` per prefecture-level city; municipalities split by district
- City files use unordered lists, format:
  ```
  - Attraction Name  One-line description  [YYYYMM]
      - #5A景区  ★★★★  Natural landscape  Mountain
      - #SourceTag  Video link (optional)
  ```
- One attraction can have multiple tags: `#5A景区` `#三山五岳` `#个人收藏` etc.
- Recommendation source: one tag only, optional link: `#呆呆不吃喵推荐` `#北洛推荐` `#影视飓风推荐`
- Visited mark `[YYYYMM]` follows the attraction name, records **first visit time**, not updated for revisit

---

## Overseas Destinations

**Path**: `<VAULT_ROOT>/wiki/personal/travel/destinations/overseas/<Country>.md` as country index, `<Country>/` directory for sub-content (or user's custom travel directory)

- **Directory structure**: First-level divisions (prefecture/state/province) as folders, subordinate cities as `.md` files
- **Filenames**: Use native script (e.g., `関東地方.md`, `缅因州.md`)
- **H1 title**: Use `<ruby>` for original text + reading/translation: `# <ruby>東京都<rt>とうきょう</rt></ruby>`
- Example: `日本/関東地方.md` → `日本/東京都/` → `日本/東京都/新宿区.md`
- **Remove `<rt>` in wikilinks**: Obsidian wikilinks do not support `<rt>` rendering; use plain text for link text, keep reading only in the title

---

## Travel Plan Ingestion

### Iron Rules

**Rule 1: Never delete plan content.** When the user reviews a trip, whether via natural language or by pasting an actual execution checklist (with ✅ marks), always **keep the original plan + append actual execution**, creating a "Plan / Actual" dual-section comparison. Do not replace the original plan with actual execution.

**Rule 2: Extract locations from every sentence.** During review, extract as many locations as possible from the user's natural language description — not just main attractions, but also passed-by spots, photographed places, visited streets/buildings/commercial facilities, temporary shop visits. Write all into the corresponding regional `.md` with `[YYYYMM]`. More locations is better for future #todo extraction.

**Rule 3: Always tag #todo.** Places planned but not visited, and newly discovered but not visited, must all be written into the corresponding regional index `.md` and explicitly tagged `#拾遗`. During review of each plan item, simultaneously check for any missed #todo entries.

### Workflow

1. **After plan ingestion, supplement surrounding areas**: After the user's travel plan is ingested into the wiki, fill in stub entries for neighboring administrative divisions at the same level (cities under the same prefecture/state) as the planned cities/regions, and add wikilinks for mentioned place names in the plan document; **plan attractions are written directly into the corresponding regional `.md`** (no need to wait for review), with impressions added later during review or moved to #todo
2. **Archive #todo during review**: When the user reviews a plan:
   - Supplement actual execution, **impressions and evaluations** (good/bad experience, worth it or not, pitfalls) next to corresponding attractions in the plan document
   - **Newly discovered but not visited**: write into the regional index `.md` under the corresponding directory, tag `#拾遗`
   - **Planned but not visited**: same as above, write into regional index `.md`, tag `#拾遗`
   - `#拾遗` format: `- Place Name  #拾遗  One-line note` (same level as attraction entries)
   - **Note**: Unplanned short trips (rule #4) do not need this step, just handle locations
3. **Add visited attractions during review**: All actually visited places during the trip (whether planned or unplanned) must be supplemented into the corresponding regional attraction `.md`, with `[YYYYMM]` visited mark and one-line description, format consistent with existing entries
4. **Unplanned short trips also get reviewed**: Nearby or short-period trips may not have a formal plan document; user oral description suffices — still supplement visited attractions and `#拾遗`, no need to create a plan file
5. **Sync birdwatching spots**: For birdwatching-related locations, in addition to the regional attraction `.md`, also sync to `<VAULT_ROOT>/wiki/personal/travel/birdwatching.md` (or user's custom birdwatching file), format: `- Location  Note  [YYYYMMDD]  #Province/City #Birdwatching #Season`

---

## Index Pages

Grouped by source (Personal Collection / 呆呆不吃喵 / 北洛 / 影视飓风 / 三山五岳 / 五湖四海), only link to city files, no body text.
