---
name: wiki-retrieve
description: "Hybrid retrieval primitive for the Compound Vault. Replaces the v1.6 static hot→index→drill read order with contextual-prefix + BM25 + cosine-rerank, modeled on Anthropic's Sept 2024 Contextual Retrieval research. Opt-in via `bash bin/setup-retrieve.sh`; feature-detected by wiki-query and autoresearch. Triggers on: retrieve, hybrid retrieval, BM25, rerank, contextual retrieval, search the chunks, chunk search, vault search, semantic search, what chunks match, find relevant passages."
allowed-tools: Read Bash
---

# wiki-retrieve: Hybrid Retrieval over the Vault

The v1.6 query path was `Read(hot.md) → Read(index.md) → Read(3-5 pages) → synthesize`. It worked, but page-level granularity loses to chunk-level granularity any time the answer lives in a specific passage rather than a whole page. The v1.7 `wiki-retrieve` skill is the chunk-level upgrade, opt-in and feature-gated. It replaces nothing if you don't run the setup.

**Origin**: This skill is written for opencode-wiki. There is no upstream kepano equivalent. The technique is from [Anthropic's Sept 2024 Contextual Retrieval research](https://www.anthropic.com/news/contextual-retrieval) — we implement it as agent-skill plumbing.

---

## Data privacy (v1.7.1+)

The bundled public helper uses synthetic contextual prefixes by default, keeping page bodies on-machine. Projects that need remote contextualization should add a reviewed provider adapter and document its egress behavior.

## Setup

```bash
bash bin/setup-retrieve.sh
```

What it does, in order:
1. Sanity-checks the 4 scripts are present and executable.
2. Creates `.vault-meta/chunks/` and `.vault-meta/bm25/`.
3. Probes ollama at `http://127.0.0.1:11434` for `nomic-embed-text` (rerank prerequisite). Reports status; does not install.
4. Reports which contextual-prefix tier will be used. The legacy CLI tier requires the `legacy-agent` binary on PATH; if unavailable, falls back to synthetic.
5. Runs `contextual-prefix.py --all` to chunk + contextualize every wiki page.
6. Runs `bm25-index.py build`.
7. Smoke-tests `retrieve.py` against the query "wiki".

Flags:
- `--check` — diagnostics only, no provisioning.
- `--no-llm` — force tier-3 synthetic prefix (cheapest, zero LLM dependency).
- `--rebuild` — re-chunk every page even if body_hash matches.

---

## Cost ceiling

Per Anthropic's published research, contextual-prefix generation costs approximately **$12 per 1,000 documents** with Haiku + prompt caching. For a 100-page vault with ~3 chunks per page, that's ~$3.60 one-time, with incremental updates much cheaper.

If you want to validate cost before running on a large vault:

```bash
bash bin/setup-retrieve.sh --no-llm   # provision with tier-3 synthetic prefix
# inspect retrieval quality manually; if insufficient, re-run without --no-llm
```

The legacy CLI subprocess tier (no credential, requires `legacy-agent` binary on PATH) is free in $ terms but slower. Without the binary, falls back to synthetic prefix.

---

## Skill commands (recipe)

These are the commands wiki-query and autoresearch will execute when wiki-retrieve is feature-detected. Other skills should mirror this pattern.

### Standard retrieve
```bash
python3 scripts/retrieve.py "your question here" --top 5
```
Output: JSON with `candidates` array. Each candidate has `absolute_path` to the source page; caller reads that page (using the v1.7 transport selector) and synthesizes.

### BM25-only (skip rerank)
```bash
python3 scripts/retrieve.py "query" --top 5 --no-rerank
```
Faster (no ollama call); lower quality.

### Explain mode (debugging)
```bash
python3 scripts/retrieve.py "query" --top 5 --explain
```
Adds an `explain` block with per-stage diagnostics (BM25 candidate count, dedupe size, etc.).

### Direct BM25 inspection
```bash
python3 scripts/bm25-index.py query "query" --top 10
python3 scripts/bm25-index.py stats
```

### Rerank strategy probe
```bash
python3 scripts/rerank.py "query" --peek
```
Reports which strategy will run (cosine via ollama / no-op).

---

## Integration with wiki-query

After this skill is installed, `skills/wiki-query/SKILL.md` standard and deep modes will:

1. Read `wiki/hot.md` (always, quick context).
2. Call `python3 scripts/retrieve.py "<query>" --top 5`.
3. Read the candidate pages from the result's `absolute_path` field (using the v1.7 transport selector — `obsidian-cli read` or `Read` tool).
4. Synthesize with chunk-level citation.

Quick mode is unchanged, hot.md only, never invokes retrieval.

If `retrieve.py` exits 10 (feature not provisioned), `wiki-query` falls back to the legacy v1.6 `Read(index.md) → Read(N pages)` order. No user-visible breakage.

---

## Index maintenance

The index is NOT auto-refreshed when wiki pages change. Re-run after substantive ingest sessions:

```bash
python3 scripts/contextual-prefix.py --all      # incremental: only re-processes changed pages
python3 scripts/bm25-index.py build             # always full rebuild (cheap; pure Python)
```

A future v1.7.x patch will add an opt-in write-hook hook that triggers contextual-prefix + BM25 rebuild after every N writes. For v1.7.0, refresh is manual.

To wipe and start over:

```bash
rm -rf .vault-meta/chunks/ .vault-meta/bm25/ .vault-meta/embed-cache.json
bash bin/setup-retrieve.sh
```

---

## Future tiers (v1.7.x roadmap)

Documented for transparency; not implemented in v1.7.0:

| Stage | v1.7.0 | v1.7.x target |
|---|---|---|
| Contextual prefix | synthetic | + Voyage embed-based pseudo-prefix |
| Sparse retrieval | BM25 | + SPLADE learned-sparse |
| Dense retrieval | none, rerank-only | Separate vector candidate set fused with BM25 (true hybrid) |
| Rerank | nomic cosine / no-op | + sentence-transformers BGE-base, Cohere Rerank, Voyage Rerank |
| Multi-vault | single-vault | Federation via wiki-federate (backlog #15) |

---

## Cross-reference

- Decision tree for transports: [`wiki/references/transport-fallback.md`](../../wiki/references/transport-fallback.md)
- Concurrency policy: [`skills/wiki-ingest/SKILL.md`](../wiki-ingest/SKILL.md) §Concurrency
- DragonScale Memory: [`wiki/concepts/DragonScale Memory.md`](../../wiki/concepts/DragonScale%20Memory.md)
- published Contextual Retrieval research: https://www.anthropic.com/news/contextual-retrieval

---

## How to think (10-principle mapping)

When working on this skill, apply the 10-principle loop. See [`skills/think/SKILL.md`](../think/SKILL.md) for the canonical framework.

| # | Principle | Application here |
|---|-----------|-------------------|
| 1 | OBSERVE (ext) | Read the BM25 index state + embed cache state before issuing a query. Stale caches produce wrong answers. |
| 2 | OBSERVE (int) | Am I trusting the cache when it should have been invalidated by recent ingests? Check mtime against last ingest. |
| 3 | LISTEN | The user's query — what does it actually ask? Decompose into intent and terms before matching. |
| 4 | THINK | Which retrieval strategy fits this query? BM25-only / BM25 + rerank / contextual-prefix + BM25 + rerank. |
| 5 | CONNECT (lat) | How does this hybrid compare to v1.6 baseline? +32pp top-1 / +41% error reduction is the published delta. |
| 6 | CONNECT (sys) | `--allow-egress` consent gate for remote model API; ollama runs local-only; rerank caches under `.vault-meta/`. |
| 7 | FEEL | When not provisioned, exit 10 with a friendly "run `bash bin/setup-retrieve.sh` first" message — not a stack trace. |
| 8 | ACCEPT | When retrieval returns empty, say so honestly. Don't fabricate. Don't pad with low-confidence guesses. |
| 9 | CREATE | A ranked candidate list with `--explain` traceability for every score component. |
| 10 | GROW | Queries that consistently fail → content gaps in the wiki. Track those as autoresearch inputs. |
