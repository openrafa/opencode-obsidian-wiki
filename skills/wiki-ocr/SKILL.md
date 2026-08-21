---
name: wiki-ocr
description: >
  Document conversion and OCR toolchain guide. Covers anydoc, MinerU, PaddleOCR, Tesseract, and pandoc:
  installation, usage, and selection strategy. For extracting text from PDFs/screenshots/images,
  structured table output, and LaTeX conversion.
  Triggers on: "OCR", "识别图片", "文档转换", "anydoc", "mineru", "tesseract", "paddleocr", "pandoc",
  "提取文字", "截图转文字", "PDF 转 markdown", "word 转 markdown".
allowed-tools: Read Write Edit Glob Grep Bash
---

# wiki-ocr: Document Conversion and OCR Toolchain

This skill standardizes OCR and document conversion workflows for wiki vaults when processing images, PDFs, screenshots, and Office documents.

Do not assume a tool is installed. Prefer the current agent's built-in vision for a single clear screenshot; escalate only when that is not enough. Every command below is a public install recipe — run the matching install (or the `npx` / `uvx` fallback) rather than inventing a one-off script.

---

## OCR Strategy Priority (when encountering images/screenshots)

1. **First choice: the current agent's vision / multimodal capability** — no extra install. Works well for clear images with text and simple tables. Fallback only if results are poor.
2. **Second choice: Tesseract** — 1–2 seconds per image. Good for quick tests, English text, and clean printed screenshots. Install: [tesseract-ocr/tesseract](https://github.com/tesseract-ocr/tesseract) (`brew install tesseract` or `sudo apt install tesseract-ocr tesseract-ocr-chi-sim`).
3. **Third choice: PaddleOCR** — ~10 seconds per image. General-purpose OCR with coordinate output; tables need post-processing. Install via [uv](https://docs.astral.sh/uv/) as below.
4. **Last choice: MinerU** — slower, best for scanned PDFs and dense tables. Install via uv as below. Prefer the `pipeline` backend; the default VLM backend is much slower.

> **Agent note**: Do not start a MinerU API server or download PaddleOCR models immediately. Ask whether the image is clear, or try the runtime's vision first. Only escalate to dedicated tools if quality is insufficient.

Related optional skill (not shipped in this bundle): [firecrawl/anydoc](https://github.com/firecrawl/anydoc) publishes `convert-documents-to-markdown`. You can install that skill from upstream, or just call the CLI recipes in §2.

---

## 1. mineru (Document Conversion + OCR)

Install: [`uv tool install mineru`](https://opendatalab.github.io/MinerU/).

**Backend choice (critical for speed):**

| Backend | Relative speed (CPU) | Quality | When to use |
|---|---|---|---|
| `pipeline` (default in this skill) | fastest | Good for text/tables | **Default for most cases** |
| `hybrid` | medium | Better layout | Need VLM layout + specialized OCR |
| `vlm-transformers` / `vlm-mlx-engine` | slowest | Best | Last resort, one-off quality-critical pages |

**Install recipe:** the `mineru` base install may lack `pipeline` extras. Declare everything with `--with` — do **not** `uv pip install` extras into the tool env afterwards. `uv tool upgrade --all` rebuilds the env from the original declaration and silently drops packages added by hand.

```bash
uv tool install mineru --force \
  --with "mineru[pipeline]" \
  --with six --with pyclipper --with shapely
```

`six` / `pyclipper` / `shapely` are imported by `pipeline` but not always bundled in the extra — declare them explicitly.

Verify before use:

```bash
# uv places tool envs under ~/.local/share/uv/tools/ by default
python3 -c "import shutil,sys; p=shutil.which('mineru'); print(p or 'MISSING')"
"$(dirname "$(dirname "$(command -v mineru)")")/bin/python3" -c "import torch, torchvision; print('pipeline OK')"
```

If the second line fails, re-run the `uv tool install` command above.

### A. Document Conversion (PDF/DOCX/PPTX/XLSX → Markdown)

```bash
# Convert files under the vault's .raw/ directory (Python handles special characters in names):
python3 -c "
import subprocess, os, glob
os.chdir('<VAULT_ROOT>/.raw')
for f in glob.glob('articles/*.pdf'):  # or *.docx
    result = subprocess.run(
        ['mineru', '-p', os.path.abspath(f), '-o', '/tmp/mineru_out', '-b', 'pipeline', '-m', 'auto'],
        capture_output=True, text=True, timeout=300)
    print(f'{f}: RC={result.returncode}')
"
# Output: /tmp/mineru_out/<filename>/auto/*.md (PDF) or .../office/*.md (Office)
```

Replace `<VAULT_ROOT>` with the vault path from `AGENTS.md`. Never hardcode a workstation home directory.

### B. OCR and Table Structure Extraction

#### Path 1: CLI (single/batch, no service)

Merge screenshots into one PDF, then run MinerU once. Pillow is **not** in a typical system Python — use a venv that has it (`uvx --from pillow python`, or the PaddleOCR tool env if you already created one):

```bash
uvx --from pillow python -c "
from PIL import Image
import glob
imgs = [Image.open(f) for f in sorted(glob.glob('/path/to/*.png'))]
imgs[0].save('/tmp/batch.pdf', save_all=True, append_images=imgs[1:])
"

mineru -p /tmp/batch.pdf -o /tmp/mineru_out -b pipeline -m auto
```

- **Best for**: a small set of screenshots, or when waiting per image is fine

#### Path 2: API (reuse a local server)

MinerU's local API (default `http://127.0.0.1:13800`) is **not persistent**. Start it yourself when you need per-image HTML tables. Pass `-b pipeline` on server start; the server otherwise may default to a slow VLM backend.

Start command (see current MinerU CLI help if flags drift):

```bash
mineru-api  # or: mineru -p --server … — check `mineru --help`
```

```bash
# 1. Submit
curl -s -X POST "http://127.0.0.1:13800/file_parse" \
  -F "files=@/path/to/image.png" \
  -F "is_ocr=true" \
  -F "return_format=html" | python3 -c "import sys,json; print(json.load(sys.stdin).get('task_id',''))"

# 2. Poll status (replace TASK_ID)
curl -s "http://127.0.0.1:13800/tasks/TASK_ID"

# 3. Fetch result
curl -s "http://127.0.0.1:13800/tasks/TASK_ID/result"
```

> **Agent note**: Many screenshots?
> - No table structure needed → CLI, merge PDF, run once
> - Table structure needed → API mode, keep one process running
>
> `jq` is optional; the `python3 -c` one-liner above is enough if `jq` is missing ([stedolan/jq](https://jqlang.github.io/jq/)).

---

## 2. anydoc (Lightweight Text-Layer Conversion)

CLI for documents that already have a text layer (text PDFs, DOCX, PPTX, XLSX, RTF, EPUB, CSV → GitHub-Flavored Markdown). No model download, no service.

- Package: [`@firecrawl/anydoc`](https://www.npmjs.com/package/@firecrawl/anydoc) · [github.com/firecrawl/anydoc](https://github.com/firecrawl/anydoc)
- Requires [Node.js 20+](https://nodejs.org/)
- **No OCR.** Scanned / image-only PDFs fail with `anydoc: ...unsupported` — use MinerU or PaddleOCR

Install globally, or skip install and use `npx`:

```bash
# optional global
pnpm add -g @firecrawl/anydoc
# or: npm install -g @firecrawl/anydoc

anydoc <file>                          # Markdown to stdout
anydoc <file> -o out.md                # write to a file
anydoc - --format csv < f              # CSV from stdin (format detection cannot infer stdin)
```

Fallback when `anydoc` is not on PATH:

```bash
npx -y @firecrawl/anydoc <file>
npx -y @firecrawl/anydoc <file> -o out.md
```

Prefer anydoc for text-layer Office/PDF when you just need readable markdown fast. Use MinerU when you need HTML table structure or OCR of scans. Format is auto-detected from file content; pass `--format <name>` only for CSV stdin or missing/wrong extensions. Exit codes: 0 success, 1 conversion failed (`anydoc: <message>` on stderr), 2 usage error.

---

## 3. PaddleOCR (Fast General-Purpose OCR)

Install via [uv](https://docs.astral.sh/uv/). `torch` and `paddlepaddle` are **not** hard dependencies of paddlex (backend-agnostic), but the default path needs both.

```bash
uv tool install paddleocr --force --python 3.13 \
  --with torch \
  --with "paddlepaddle>=3.3.0" \
  --index https://www.paddlepaddle.org.cn/packages/stable/cpu/ \
  --index-strategy unsafe-best-match
```

- Official CPU wheels live on the PaddlePaddle index, not PyPI. Use `--index` as above ([PaddlePaddle install](https://www.paddlepaddle.org.cn/install/quick)).
- On macOS, PaddlePaddle is **CPU-only** (no official Metal/MPS wheel).
- Same `--with` rule as MinerU: do not `uv pip install` into the tool env if you still run `uv tool upgrade --all`.
- First run downloads PP-OCRv6 under `~/.paddlex/official_models/` (~200MB).

```bash
# One-liner (PaddleOCR 3.x API). Run with the tool's interpreter:
uv tool run paddleocr python -c "
from paddleocr import PaddleOCR
ocr = PaddleOCR(use_doc_orientation_classify=False, use_doc_unwarping=False, use_textline_orientation=False)
result = ocr.predict('/path/to/image.png')
for res in result:
    for text in res['rec_texts']:
        print(text)
"
```

If `uv tool run paddleocr python` is not supported on your uv version, call `~/.local/share/uv/tools/paddleocr/bin/python3` instead.

Use PaddleOCR for a couple of images or when you need character coordinates. For dense tables (rosters, reports), use MinerU.

---

## 4. Tesseract (Ultra-Lightweight Fast OCR)

- Project: [tesseract-ocr/tesseract](https://github.com/tesseract-ocr/tesseract)
- macOS: `brew install tesseract`
- Debian/Ubuntu: `sudo apt install tesseract-ocr tesseract-ocr-chi-sim`

Fast (~1–2s) on clear, simple-layout images. Weaker than PaddleOCR/MinerU on Chinese, complex tables, multi-column layouts, and low-quality screenshots.

```bash
tesseract /path/to/image.png stdout -l chi_sim+eng
tesseract /path/to/image.png output -l chi_sim+eng
tesseract /path/to/image.png stdout -l chi_sim+eng tsv
```

If `chi_sim` is missing, install the language pack (`tesseract-lang` / `tesseract-ocr-chi-sim`) or drop to `-l eng`.

---

## 5. pandoc (LaTeX and Other Formats)

- Project: [pandoc.org](https://pandoc.org) · install: `brew install pandoc` or [github.com/jgm/pandoc/releases](https://github.com/jgm/pandoc/releases)
- Use for `.tex` and formats MinerU does not cover

```bash
pandoc input.tex -t markdown --wrap=none -o output.md
```

---

## 6. Tool Availability Check

Versions drift. Before trusting a tool, verify it is callable:

```bash
echo "anydoc:    $(anydoc --version 2>&1 || echo MISSING — install @firecrawl/anydoc or use npx -y)"
echo "mineru:    $(mineru --version 2>&1 | head -1 || echo MISSING — uv tool install mineru)"
echo "tesseract: $(tesseract --version 2>&1 | head -1 || echo MISSING)"
echo "pandoc:    $(pandoc --version 2>&1 | head -1 || echo MISSING)"
echo "paddleocr: $(uv tool run paddleocr python -c 'import paddleocr; print("OK")' 2>/dev/null || echo MISSING)"
```

If a binary is missing, install it with the recipe in that section. Do not skip to a weaker tool without saying so.
