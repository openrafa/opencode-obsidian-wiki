---
name: wiki-travel
description: >
  Manage travel destinations, trip plans, spot files, and travel reviews in a wiki vault.
  Covers one-file-per-spot layout, city index pages, theme libraries (birding, stargazing,
  skyline, hiking), plan ingestion, and review archives.
  Triggers on: "旅行", "目的地", "复盘", "旅行计划", "拾遗", "景区", "游记",
  "国内旅行", "海外旅行", "观鸟", "spot", "travel".
allowed-tools: Read Write Edit Glob Grep Bash
---

# wiki-travel: Travel Destination Management

Standardize spot files, travel plans, and review archives under a travel tree in the vault. The default convention below is a starting layout — override the root in `AGENTS.md` if the vault uses a different travel directory.

Default root: `<VAULT_ROOT>/wiki/personal/travel/`

This skill describes a **generic** schema (spot files + indexes + tags). Recommendation sources, region names, and example places belong to the vault owner; never copy another person's source tags or itineraries into a public repo.

---

## Directory Structure

```
<VAULT_ROOT>/wiki/personal/travel/
├── spots/                       # one file per physical place
│   ├── <region>/                # domestic: large-region folders (customize)
│   └── <country>/               # overseas: one folder per country
├── destinations/
│   ├── domestic/<Province>/<City or District>.md   # link-only indexes → spots
│   └── overseas/<Country>/…                        # link-only indexes
├── birdwatching.md              # activity log (links to spots), optional
├── <theme>/<region>.md          # theme libraries (birding / stargazing / skyline / …)
├── trips/                       # trip journals
└── destinations.md              # hub page; may embed a Bases view
```

Optional database view (Obsidian Bases): `wiki/meta/destinations.base` filtered on `type == "spot"`. Useful views: visited / planned / missed; per-type (attraction / birding / stargazing / trail / restaurant); per-source **tags**; overseas grouped by country.

Recommendation sources are **tags on spot files**, not standalone list notes.

---

## Spot File Format

```markdown
---
type: spot
spot_type: attraction            # primary: attraction | birding | stargazing | skyline | trail | restaurant | …
types: [attraction]              # all applicable types
status: visited                  # visited | planned | missed   (vault may use local-language equivalents)
visited: 2024-10                 # first visit YYYY-MM (omit if not visited)
rating: 4.5                      # optional
region: <large-region>           # domestic grouping, optional
province: <province>
city: <city>
country: <country>               # overseas
admin: <country>/<subdivision>
season: summer                   # best season when known
bortle: "3"                      # stargazing spots
tags: [travel, spot, rec/<source-id>]
---

# Place name
# Overseas titles may keep ruby: # <ruby>伏見稲荷大社<rt>ふしみいなりたいしゃ</rt></ruby>

One-line summary

## Details
```

Rules:

- One physical place = one file, even if it is both a trail and a viewpoint (`types` lists all)
- Folder = large region (domestic) or country (overseas); admin details live in frontmatter, not in the path
- `visited` records the **first** visit only (`YYYY-MM`); do not update on revisit
- Wikilinks use vault-absolute paths: `[[wiki/personal/travel/spots/<region>/<SpotName>|<SpotName>]]`; no `<rt>` inside link text
- Overseas H1 may keep ruby; the filename stays plain
- Source / checklist membership is tags only, for example `#rec/<source-id>`, plus any public taxonomy tags the vault uses. Do not recreate standalone “recommendation list” files
- Keep source ids generic (`blog`, `channel`, `friend`, or a short slug). Do not bake a specific creator, employer, or private nickname into this skill

Status / type values in the vault may be localized (for example 去过 / 待去 / 拾遗, 景点 / 鸟点 / 观星). Match the vault's existing vocabulary; the English keys above are the portable aliases.

---

## Index & Theme Pages

- City files (`destinations/**`): link-only lists; keep frontmatter and H1. One line per spot: `- [[…|Name]]  [YYYYMM]` (visited mark optional). A `## Planned` (or local equivalent) section collects spots not yet in the main list
- Theme libraries: keep methodology / intro prose; replace long per-spot writeups with links. Details live in the spot file
- Never recreate standalone recommendation lists — sources stay as tags

---

## Travel Plan Ingestion

### Iron Rules

**Rule 1: Never delete plan content.** On review, keep the original plan and append actual execution (“Plan / Actual” dual sections).

**Rule 2: Extract locations from every sentence.** Main attractions, pass-by spots, photographed places, streets, buildings, shops. More is better for later missed-spot extraction.

**Rule 3: Always record missed spots.** Planned-but-not-visited and newly discovered-but-not-visited: create a spot file (`status: missed`) in the right region folder, and add a link under the city file's planned section.

### Workflow

1. **After plan ingestion**: create spot files for planned attractions (`status: planned`), link them from the city index; stub neighboring city indexes when useful
2. **During review**:
   - Update spot frontmatter: `status` → visited, `visited` → YYYY-MM; append impressions to the spot body
   - Newly discovered but not visited: new spot with `status: missed`
   - Update the trip journal and optional activity logs with links
3. **Unplanned short trips** get the same review without creating a plan file
4. **Themed spots** (birding, stargazing, …): put type in `types` and keep species / habitat / viewpoint notes in the spot body

---

## Naming & Placement Quick Reference

| Case | Folder | Notes |
|---|---|---|
| Domestic spot | `spots/<region>/` | region / province / city in frontmatter |
| Overseas spot | `spots/<country>/` | country / admin in frontmatter; ruby in H1 optional |
| Same place, multiple types | one file | primary `spot_type` + `types` list |
| Name collision in a folder | prefix with city | e.g. `<City>·<Place>` |
| Walking / trekking route | one spot | `spot_type: trail`, segments in the body |
