#!/usr/bin/env python3
"""contextual-prefix.py - chunk wiki pages and generate per-chunk contextual prefixes.

This public OpenCode version defaults to an on-machine synthetic prefix. It keeps
retrieval indexing useful without sending private wiki page bodies to a remote
model. Projects that want remote contextualization should add their own explicit,
reviewed provider adapter behind an opt-in flag.

Chunk schema written to .vault-meta/chunks/<page-address>/chunk-NNN.json:
{
  "schema_version": 1,
  "page_path": "wiki/concepts/Foo.md",
  "page_address": "c-000042",
  "chunk_index": 3,
  "raw_text": "...",
  "contextualized_text": "<prefix> <raw_text>",
  "prefix_source": "synthetic" | "skipped",
  "char_count": 487,
  "body_hash": "sha256:...",
  "page_body_hash": "sha256:...",
  "created_at": "2026-05-17T..."
}

Usage:
  contextual-prefix.py PATH
  contextual-prefix.py --all
  contextual-prefix.py PATH --no-llm
  contextual-prefix.py PATH --rebuild
  contextual-prefix.py PATH --peek
"""

import argparse
import hashlib
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

VAULT_ROOT = Path(__file__).resolve().parent.parent
WIKI_DIR = VAULT_ROOT / "wiki"
META_DIR = VAULT_ROOT / ".vault-meta"
CHUNKS_DIR = META_DIR / "chunks"

CHUNK_TARGET_TOKENS = 500  # rough; we approximate via chars/4
CHUNK_TARGET_CHARS = CHUNK_TARGET_TOKENS * 4
CHUNK_OVERLAP_CHARS = 200


EXIT_OK = 0
EXIT_USAGE = 2
EXIT_PAGE_MISSING = 3
EXIT_CHUNK_DIR = 4

FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)
ADDRESS_RE = re.compile(r"^address:\s*(c-\d{6})\s*$", re.MULTILINE)
TITLE_RE = re.compile(r"^title:\s*['\"]?(.+?)['\"]?\s*$", re.MULTILINE)


def log(msg):
    print(msg, file=sys.stderr)


def sha256(text):
    return "sha256:" + hashlib.sha256(text.encode("utf-8")).hexdigest()


def read_page(path):
    if not path.is_file():
        raise SystemExit(EXIT_PAGE_MISSING)
    return path.read_text(encoding="utf-8", errors="replace")


def parse_frontmatter(body):
    m = FRONTMATTER_RE.match(body)
    if not m:
        return {}, body
    fm_text = m.group(1)
    rest = body[m.end():]
    addr_m = ADDRESS_RE.search(fm_text)
    title_m = TITLE_RE.search(fm_text)
    return {
        "address": addr_m.group(1) if addr_m else None,
        "title": title_m.group(1) if title_m else None,
        "raw": fm_text,
    }, rest


def derive_synthetic_address(page_path):
    """Stable per-path address-shaped string when no real address is set.
    Format: c-NNNNNN derived from a hash of the relative path (deterministic).
    Distinct from allocator addresses; used only for chunk filing.
    """
    rel = page_path.relative_to(VAULT_ROOT)
    h = hashlib.sha1(str(rel).encode("utf-8")).hexdigest()
    return "syn-" + h[:6]


def chunk_body(body, target_chars=CHUNK_TARGET_CHARS, overlap=CHUNK_OVERLAP_CHARS):
    """Split body into overlapping chunks on paragraph boundaries when possible.
    Heuristic: walk the body, accumulate paragraphs until len exceeds target,
    flush, then keep the trailing `overlap` chars as the seed of the next chunk.
    Empty paragraphs collapse to single boundaries.
    """
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", body) if p.strip()]
    chunks = []
    cur = []
    cur_len = 0
    for p in paragraphs:
        cur.append(p)
        cur_len += len(p) + 2
        if cur_len >= target_chars:
            chunk_text = "\n\n".join(cur)
            chunks.append(chunk_text)
            # seed next chunk with the tail
            tail = chunk_text[-overlap:] if overlap > 0 else ""
            cur = [tail] if tail else []
            cur_len = len(tail)
    if cur and "".join(cur).strip():
        chunks.append("\n\n".join(cur))
    if not chunks and body.strip():
        # tiny page — single chunk
        chunks = [body.strip()]
    return chunks


def synthetic_prefix(fm, body, chunk_text):
    """Tier-3 prefix: page title + first sentence of the page body.
    Free, hermetic, deterministic. Provides modest BM25 lift via title-word
    re-injection into the chunk corpus.
    """
    title = (fm.get("title") or "").strip() or "(untitled)"
    # First sentence of the body (not the chunk — gives the chunk a page-level frame)
    first_sentence = re.split(r"(?<=[.!?])\s+", body.strip(), maxsplit=1)
    first = first_sentence[0][:300] if first_sentence else ""
    return f"This passage is from the wiki page \"{title}\". The page opens: {first}"


def pick_prefix_tier(force_synthetic, allow_egress=False):
    """The public portable version always uses synthetic prefixes."""
    return "synthetic"


def generate_prefix(tier, fm, body, chunk_text):
    title = fm.get("title") or "(untitled)"
    return synthetic_prefix(fm, body, chunk_text), "synthetic"


def process_page(page_path, force_synthetic=False, rebuild=False, peek=False,
                 allow_egress=False, progress_label=""):
    body = read_page(page_path)
    fm, content = parse_frontmatter(body)
    address = fm.get("address") or derive_synthetic_address(page_path)
    page_body_hash = sha256(body)

    chunk_dir = CHUNKS_DIR / address
    if not peek:
        try:
            chunk_dir.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            log(f"ERR: cannot create chunk dir {chunk_dir}: {e}")
            raise SystemExit(EXIT_CHUNK_DIR)

    chunks = chunk_body(content)
    tier = pick_prefix_tier(force_synthetic, allow_egress=allow_egress)

    progress = (progress_label + " ") if progress_label else ""
    if not chunks:
        # v1.7.2 / closes audit M6: previously this logged "chunks=0" with no
        # explanation and silently produced no index entries. Now: explicit WARN
        # so the user notices empty-body pages (often frontmatter-only stubs).
        log(f"{progress}WARN: {page_path.relative_to(VAULT_ROOT)} has no chunkable body content "
            f"(empty after frontmatter strip). Skipping; no chunks written.")
        return {"address": address, "written": [], "skipped": 0, "tier": tier}

    log(f"{progress}-> {page_path.relative_to(VAULT_ROOT)}  address={address}  chunks={len(chunks)}  tier={tier}")

    written = []
    skipped = 0
    # Keep this loop sequential. The tier-1 published path caches the page body;
    # a cache entry is only readable after the first response begins (published
    # prompt-caching concurrency rule), so chunk 0 warms the prefix and chunks
    # 1..N read it. Parallelizing here would silently zero every cache read.
    for idx, raw in enumerate(chunks):
        chunk_path = chunk_dir / f"chunk-{idx:03d}.json"
        body_hash = sha256(raw)

        if chunk_path.exists() and not rebuild:
            try:
                existing = json.loads(chunk_path.read_text(encoding="utf-8"))
                if existing.get("body_hash") == body_hash and \
                   existing.get("page_body_hash") == page_body_hash:
                    skipped += 1
                    continue
            except (json.JSONDecodeError, OSError):
                pass  # corrupted; overwrite

        if peek:
            log(f"   would write {chunk_path.name} ({len(raw)} chars)")
            continue

        prefix, prefix_source = generate_prefix(tier, fm, content, raw)
        contextualized = f"{prefix}\n\n{raw}" if prefix else raw

        record = {
            "schema_version": 1,
            "page_path": str(page_path.relative_to(VAULT_ROOT)),
            "page_address": address,
            "chunk_index": idx,
            "raw_text": raw,
            "contextualized_text": contextualized,
            "prefix": prefix or "",
            "prefix_source": prefix_source,
            "char_count": len(raw),
            "body_hash": body_hash,
            "page_body_hash": page_body_hash,
            "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
        tmp = chunk_path.with_suffix(f".{os.getpid()}.tmp")
        try:
            tmp.write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding="utf-8")
            os.replace(tmp, chunk_path)
        finally:
            if tmp.exists():
                tmp.unlink(missing_ok=True)
        written.append(chunk_path.name)

    log(f"   wrote={len(written)}  skipped(unchanged)={skipped}")
    return {"address": address, "written": written, "skipped": skipped, "tier": tier}


def collect_pages(target):
    if target == "--all" or target is None:
        return sorted(p for p in WIKI_DIR.rglob("*.md")
                      if not any(part.startswith(".") for part in p.parts))
    p = Path(target)
    if not p.is_absolute():
        p = VAULT_ROOT / p
    return [p]


def main():
    parser = argparse.ArgumentParser(description="Chunk + contextualize wiki pages.")
    parser.add_argument("path", nargs="?",
                        help="Page path relative to vault root. Omit (or pass --all) "
                             "to process every wiki page.")
    parser.add_argument("--all", action="store_true",
                        help="Process every wiki page (equivalent to omitting path).")
    parser.add_argument("--no-llm", action="store_true",
                        help="Force tier-3 synthetic prefix (skip LLM calls).")
    parser.add_argument("--allow-egress", action="store_true",
                        help="Allow tier-1 (remote model API) or tier-2 (legacy-agent CLI "
                             "subprocess) prefix generation. Without this flag, page "
                             "bodies stay on-machine and only the tier-3 synthetic "
                             "prefix is used. Mirror of tiling-check.py's "
                             "--allow-remote-ollama guard.")
    parser.add_argument("--rebuild", action="store_true",
                        help="Re-process chunks even if body_hash matches.")
    parser.add_argument("--peek", action="store_true",
                        help="Print plan, write nothing.")
    args = parser.parse_args()

    if args.all and not args.path:
        args.path = "--all"
    elif not args.path:
        # No path and no --all: default to all (matches the help text)
        args.path = "--all"

    pages = collect_pages(args.path)
    # Explicit single-path invocations must point at a readable file inside the
    # vault. --all only ever yields in-vault files, so this guard is explicit-only.
    # Without it a typo'd path exited 0 silently, and an out-of-vault path raised
    # a raw ValueError from relative_to().
    if args.path != "--all":
        target = pages[0].resolve()
        if not target.is_relative_to(VAULT_ROOT):
            log(f"ERR: {args.path} resolves outside the vault ({VAULT_ROOT}).")
            return EXIT_USAGE
        if not target.is_file():
            log(f"ERR: {args.path} is not a readable file.")
            return EXIT_PAGE_MISSING
    # Filter to actual files up front so progress counter is meaningful
    # (v1.7.2; closes audit L2: tier-2 over 47 pages can take 5+ min — the
    # user needs a count, not just per-page log lines).
    files = [p for p in pages if p.is_file()]
    skipped_non_files = len(pages) - len(files)
    if skipped_non_files:
        log(f"({skipped_non_files} non-file paths skipped)")
    total = len(files)
    total_written = 0
    total_skipped = 0
    for i, page in enumerate(files, 1):
        result = process_page(
            page,
            force_synthetic=args.no_llm,
            rebuild=args.rebuild,
            peek=args.peek,
            allow_egress=args.allow_egress,
            progress_label=f"[{i}/{total}]",
        )
        total_written += len(result["written"])
        total_skipped += result["skipped"]

    log(f"\nDone. pages={total}  chunks_written={total_written}  chunks_unchanged={total_skipped}")
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
