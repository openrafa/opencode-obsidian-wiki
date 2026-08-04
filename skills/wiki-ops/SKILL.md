---
name: wiki-ops
description: >
  Wiki operations and batch processing rules. Covers work document archiving policies,
  batch modification iron rules, script writing checklists, Python package management,
  and filename character handling. For safe wiki maintenance at scale.
  Triggers on: "批量操作", "脚本", "批量修改", "整理", "工作文档", "uv tool",
  "批量脚本", "运维", "数据迁移", "正则替换".
allowed-tools: Read Write Edit Glob Grep Bash
---

# wiki-ops: Operations and Batch Processing Rules

This skill standardizes safe workflows for work document management, batch modifications, script writing, and execution in a wiki vault.

---

## Work Document Policy

- Original files under 工作/ are preserved and never deleted
- **Organization-first grouping**: Both `工作/` and `<VAULT_ROOT>/work/` use "organization" as the first grouping layer (e.g., `CMCC/`) to prevent content mixing after job changes
  - Example: `工作/CMCC/2026/AK3/` → wiki extraction to `<VAULT_ROOT>/work/cmcc/projects/ak3.md`
  - Future organization: `工作/<NewOrg>/` → `<VAULT_ROOT>/work/<NewOrg>/`
- Extract knowledge into wiki only, do not build source indexes
- Generic content (e.g., personal bio/resume) stays at `<VAULT_ROOT>/work/` root, not tied to any specific organization

---

## Batch Processing Iron Rules

**For any batch file modification (script rewrite, regex replacement, format conversion, etc.), you MUST:**

1. **Backup first to `/tmp/`**: `cp -r` the target files/directories to `/tmp/wiki_backup_<timestamp>/`
2. **Experiment in `/tmp`**: Run scripts on the backup first, verify results are correct
3. **Overwrite only after confirmation**: Manually spot-check results in the backup, confirm nothing is lost or added, then `cp` back to original location
4. **Leave script traces**: Batch scripts are uniformly placed in `.scripts/` directory for future traceability

Data loss from violating this discipline = unacceptable. Better slow by one round than lose a single line.

---

## Batch Script Writing Checklist

After writing any batch modification script, immediately run the following validations (do not rely on visual spot-checking):

- **Entry count**: `wc -l` or count entries before and after; counts must match (except for additions)
- **Orphaned sub-line scan**: Check if `    - #` sub-lines have corresponding `- ` main lines; output must be 0 to pass
- **Duplicate tag check**: No two identical `    - #xxx` sub-lines under the same main line
- **Fuzzy match vigilance**: Attraction name matching: `庐山` will hit `庐山西海`, `黄山` will hit `黄山市古徽州`. Either use full-name exact matching, or manually confirm diff after matching
- **Script bug self-check**: After writing a script, ask yourself — if an entry already has the correct value, does the script skip or overwrite? In the overwrite logic, is there an `append` back? Missing `append` = silent deletion

---

## Session Pitfalls (Do Not Repeat)

| Issue | Cause | Correct Approach |
|-------|-------|----------------|
| 5A categories all lost (344/359) | backfill_5a.py overwrote original files with overview data; overview had ratings but no categories | When merging, **preserve existing lines** and only add tags, do not replace entire lines |
| Walking routes silently disappeared | In add_descriptions.py, `has_desc=True` branch forgot `new_lines.append(line)`; entries with correct descriptions were silently dropped | Every branch must explicitly append; verify with orphaned sub-line scan after writing |
| `#大鹅` wrongly attached to 庐山西海 | Tag script used `keyword in line` fuzzy matching | Use full-name exact matching for attraction names, or use regex `^- 庐山\b` to match only line start |
| 3 duplicate `#个人收藏` under 天坛 | Walking route sub-lines merged into the previous 5A entry | Orphaned sub-line scan catches this — main and sub-line counts won't match |

---

## Mandatory Post-Script Commands

```bash
# 1. Orphaned sub-lines (sub-line without preceding main line)
python3 -c "
import os
for root,dirs,files in os.walk('TARGET_DIR'):
    for f in files:
        if not f.endswith('.md'): continue
        with open(os.path.join(root,f)) as fh: lines=fh.readlines()
        prev_main=False
        for i,l in enumerate(lines):
            s=l.strip()
            if s.startswith('- ') and not s.startswith('- #'): prev_main=True
            elif s.startswith('    - #') and not prev_main: print(f'ORPHAN {f}:{i+1}')
            elif not s: prev_main=False
"

# 2. Duplicate sub-line tags
python3 -c "
import os
for root,dirs,files in os.walk('TARGET_DIR'):
    for f in files:
        if not f.endswith('.md'): continue
        with open(os.path.join(root,f)) as fh: lines=fh.readlines()
        seen=set()
        for i,l in enumerate(lines):
            s=l.strip()
            if s.startswith('- ') and not s.startswith('- #'): seen=set()
            elif s.startswith('    - #'):
                tag=s.split()[0]
                if tag in seen: print(f'DUP {f}:{i+1} {tag}')
                seen.add(tag)
"
```

---

## Python Package Management

- Prefer `uv tool` for managing global tools, do not `pip3 install`
- View system-installed tools: `uv tool list`

---

## Filename Character Issues

Chinese filenames in `.raw/` may contain full-width quotation marks and other special characters. Shell direct argument passing will fail. Use Python `glob.glob()` + `subprocess.run()` to get correct paths before calling tools.
