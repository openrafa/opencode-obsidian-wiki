---
name: wiki-ocr
description: >
  Document conversion and OCR toolchain guide. Covers MinerU, PaddleOCR, Tesseract, and pandoc:
  installation, usage, and selection strategy. For extracting text from PDFs/screenshots/images,
  structured table output, and LaTeX conversion.
  Triggers on: "OCR", "识别图片", "文档转换", "mineru", "tesseract", "paddleocr", "pandoc",
  "提取文字", "截图转文字", "PDF 转 markdown".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# wiki-ocr: Document Conversion and OCR Toolchain

This skill standardizes OCR and document conversion workflows for opencode-wiki vaults when processing images, PDFs, screenshots, and Office documents.

---

## OCR Strategy Priority (when encountering images/screenshots)

1. **First choice: OpenCode built-in multimodal/vision capability** — zero extra cost, zero latency. Works well for clear images with text, supports table structure understanding. Fallback only if results are poor.
2. **Second choice: Tesseract** — 1-2 seconds per image. Good for quick tests, English text, and clean printed screenshots.
3. **Third choice: PaddleOCR** — ~10 seconds per image. General-purpose OCR with coordinate output, requires post-processing for tables.
4. **Last choice: MinerU** — ~90 seconds per image. Suitable for batch processing large numbers of screenshots or complex structured table output (e.g., contact lists, rosters).

> **Agent note**: Do not start MinerU service or download PaddleOCR models immediately. Ask the user if the image is clear, or try OpenCode's multimodal capability first. Only escalate to dedicated tools if quality is insufficient.

---

## 1. mineru (Document Conversion + OCR Primary Tool)

Installed via `uv tool install mineru` (v3.2.2).

### A. Document Conversion (PDF/DOCX/PPTX/XLSX → Markdown)

```bash
# Convert files under .raw/ (use Python to handle filenames with special characters):
python3 -c "
import subprocess, os, glob
os.chdir('<VAULT_ROOT>/.raw')
for f in glob.glob('articles/*.pdf'):  # or *.docx
    result = subprocess.run(['mineru', '-p', os.path.abspath(f), '-o', '/tmp/mineru_out', '-b', 'pipeline', '-m', 'auto'],
                          capture_output=True, text=True, timeout=300)
    print(f'{f}: RC={result.returncode}')
"
# Output at /tmp/mineru_out/<filename>/auto/*.md (PDF) or /tmp/mineru_out/<filename>/office/*.md (Office)
```

### B. OCR and Table Structure Extraction (Screenshots → HTML/Tables)

MinerU supports two usage paths. Choose based on scenario:

#### Path 1: CLI Mode (Single/Batch, No Service Needed)

For one-off processing or batch screenshots already merged into a single PDF.

```bash
# Merge multiple screenshots into a single PDF first
python3 -c "
from PIL import Image
import glob
imgs = [Image.open(f) for f in sorted(glob.glob('/path/to/*.png'))]
imgs[0].save('/tmp/batch.pdf', save_all=True, append_images=imgs[1:])
"

# Process directly via CLI
mineru -p /tmp/batch.pdf -o /tmp/mineru_out -b pipeline -m auto
```

- **Pros**: No service startup needed, single command completes
- **Best for**: Small number of screenshots, or when per-image waiting is acceptable

#### Path 2: API Mode (Reuse Service, Per-Image Processing)

Local API runs at `http://127.0.0.1:13800`, **not persistent**, must be started manually. Best for structured table output with many screenshots to process individually.

- **Pros**: Direct HTML table output with intact row/column structure; reusing the service avoids repeated cold-start and model-loading overhead
- **Cons**: Slower per image (~90s for dense table screenshots)
- **Reuse strategy**: Start a long-running agent session to keep the service alive; have other sessions call the API via that instance

```bash
# 1. Submit to MinerU API
curl -s -X POST "http://127.0.0.1:13800/file_parse" \
  -F "files=@/path/to/image.png" \
  -F "is_ocr=true" \
  -F "return_format=html" | jq -r '.task_id'

# 2. Poll status (replace TASK_ID)
curl -s "http://127.0.0.1:13800/tasks/TASK_ID"

# 3. Fetch result
curl -s "http://127.0.0.1:13800/tasks/TASK_ID/result" | jq '.results[].md_content'
```

> **Agent note**: When the user says "lots of screenshots need OCR", first determine if table structure is needed:
> - No table structure needed → CLI mode, merge PDF and run once
> - Table structure needed and many images → API mode, keep a persistent agent running
>
> For vault-specific tool notes, follow that vault's AGENTS.md or wiki meta pages.

---

## 2. PaddleOCR (Fast General-Purpose OCR)

Installed via `uv tool install paddleocr` (v3.7.0), with `paddlepaddle` installed for local inference.

- **Positioning**: Quick text extraction from single images, layout analysis requiring text coordinates
- **Pros**: ~10 seconds per image, coordinate box output, no persistent service needed
- **Cons**: Output is scattered text boxes, no table structure, requires post-processing to stitch together
- **Model**: Auto-downloads PP-OCRv6 to `~/.paddlex/official_models/` on first run (~200MB)

```bash
# One-liner quick recognition
~/.local/share/uv/tools/paddleocr/bin/python3 -c "
from paddleocr import PaddleOCR
ocr = PaddleOCR(use_angle_cls=True, lang='ch')
r = ocr.ocr('/path/to/image.png')
for line in r[0]:
    print(f\"[{line['rec_scores']:.3f}] {line['rec_texts']}\")
"
```

> **Agent note**: If the user has "one or two images to quickly read text", or needs "coordinates for each character", use PaddleOCR. For extracting "table-type content" (contact lists, rosters, reports), use MinerU.

---

## 3. Tesseract (Ultra-Lightweight Fast OCR)

Installed via Homebrew (v5.5.2 + leptonica-1.87.0).

- **Positioning**: Extremely fast text extraction for clear, simple-layout images
- **Pros**: ~1-2 seconds per image, zero model downloads, no persistent service needed
- **Cons**: Lower Chinese accuracy than PaddleOCR/MinerU, poor for complex tables, multi-column layouts, low-quality screenshots
- **Best for**: Clean printed screenshots, single-column plain text, English content, quick previews

```bash
# Basic usage (plain text output)
tesseract /path/to/image.png stdout -l chi_sim+eng

# Output to file
tesseract /path/to/image.png output -l chi_sim+eng

# Coordinate info (TSV format)
tesseract /path/to/image.png stdout -l chi_sim+eng tsv
```

> **Agent note**: If the user says "quick OCR", "try text on this image", or "tesseract", run tesseract first. If quality is poor (garbled, missing characters), switch to PaddleOCR or MinerU.

---

## 4. pandoc (LaTeX and Other Formats)

Installed via Homebrew (v3.10). For `.tex` and other formats not supported by mineru.

```bash
pandoc input.tex -t markdown --wrap=none -o output.md
```
