#!/usr/bin/env python3
"""
ingest.py — Per-page OCR and JSON index generator for the library.

Usage:
    python scripts/ingest.py --book-id bhajanamritam_01 \
                             --pdf raw_assets/bhajanamritam_01.pdf \
                             --lang mal \
                             --output data/indices/bhajanamritam_01.json

Language codes (must match Tesseract pack names):
    mal  — Malayalam
    tam  — Tamil
    hin  — Hindi / Devanagari
    san  — Sanskrit / Devanagari

After running, REVIEW the output JSON before committing:
    - Overflow pages (no song title, just continuation) produce incorrect entries.
    - Complex or traditional typography may cause OCR misreads.
    - Edit the JSON manually to correct any errors, then push to main.
"""

import argparse
import json
import re
import sys
from pathlib import Path

import pdfplumber
import pytesseract
from pytesseract import Output
from PIL import Image


# ── Tesseract language code → display name mapping ────────────────────────────
LANG_LABELS = {
    "mal": "ml",
    "tam": "ta",
    "hin": "hi",
    "san": "sa",
}


def extract_title_from_page(page_image: Image.Image, lang: str) -> str:
    """
    Run Tesseract OCR on a page image and return the text line with the largest font
    as the presumed song title.

    The largest text on a songbook page is typically the song title.
    Empty string is returned for blank or unreadable pages.
    """
    data = pytesseract.image_to_data(page_image, lang=lang, config="--psm 3", output_type=Output.DICT)
    
    lines_data = {}
    
    n_boxes = len(data['level'])
    for i in range(n_boxes):
        if data['level'][i] == 5:  # Level 5 corresponds to a word
            text = data['text'][i].strip()
            if not text:
                continue
                
            block_num = data['block_num'][i]
            par_num = data['par_num'][i]
            line_num = data['line_num'][i]
            height = data['height'][i]
            
            line_key = (block_num, par_num, line_num)
            if line_key not in lines_data:
                lines_data[line_key] = {
                    'text_parts': [],
                    'max_height': 0
                }
            
            lines_data[line_key]['text_parts'].append(text)
            if height > lines_data[line_key]['max_height']:
                lines_data[line_key]['max_height'] = height

    if not lines_data:
        return ""

    # Sort lines by their maximum word height in descending order
    sorted_lines = sorted(lines_data.values(), key=lambda x: x['max_height'], reverse=True)
    
    # Return the text from the line with the largest height
    best_line = sorted_lines[0]
    return " ".join(best_line['text_parts'])


def slugify(text: str) -> str:
    """Convert a string to a safe slug for use in song_id fields."""
    text = text.lower()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "_", text)
    return text.strip("_")[:40]


def process_pdf(
    book_id: str,
    pdf_path: Path,
    lang: str,
    output_path: Path,
    dpi: int = 200,
) -> None:
    """
    Process every page of the PDF:
      1. Render page to an image at [dpi] DPI.
      2. Run Tesseract OCR with the specified language pack.
      3. Extract the topmost text line as the song title.
      4. Write a JSON array of song entries to [output_path].

    Pages with no extractable title are skipped with a warning.
    """
    language_code = LANG_LABELS.get(lang, lang[:2])
    entries = []
    skipped = 0

    print(f"Processing: {pdf_path.name}  |  lang={lang}  |  dpi={dpi}")

    with pdfplumber.open(pdf_path) as pdf:
        total = len(pdf.pages)
        for i, page in enumerate(pdf.pages, start=1):
            print(f"  Page {i}/{total}", end="\r", flush=True)

            # Render page to PIL image
            page_image = page.to_image(resolution=dpi).original

            title = extract_title_from_page(page_image, lang)

            if not title:
                skipped += 1
                continue

            # Build a stable song_id from the book_id and page number
            slug = slugify(title) or f"page_{i}"
            song_id = f"{book_id}_{i:04d}_{slug}"

            entries.append(
                {
                    "song_id": song_id,
                    "title_native": title,
                    "title_en": "",          # Fill in manually or via transliteration
                    "language": language_code,
                    "category": "",          # Fill in manually
                    "page_number": i,
                    "tags": [],              # Fill in manually
                }
            )

    print(f"\nDone. {len(entries)} entries written, {skipped} pages skipped.")
    print("REVIEW the output before committing — check for OCR errors and")
    print("overflow pages (pages without a song title).\n")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)

    print(f"Output: {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="OCR a PDF and generate a song index JSON file."
    )
    parser.add_argument(
        "--book-id",
        required=True,
        help="Unique book identifier (e.g. bhajanamritam_01). "
             "Must match the book_id in catalog.json.",
    )
    parser.add_argument(
        "--pdf",
        required=True,
        type=Path,
        help="Path to the source PDF file (e.g. raw_assets/book.pdf).",
    )
    parser.add_argument(
        "--lang",
        required=True,
        choices=list(LANG_LABELS.keys()),
        help="Tesseract language pack: mal, tam, hin, san.",
    )
    parser.add_argument(
        "--output",
        required=True,
        type=Path,
        help="Output path for the JSON index (e.g. data/indices/book.json).",
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=200,
        help="DPI for PDF page rendering (default: 200). "
             "Higher DPI improves OCR accuracy but increases runtime.",
    )

    args = parser.parse_args()

    if not args.pdf.exists():
        print(f"Error: PDF not found: {args.pdf}", file=sys.stderr)
        sys.exit(1)

    process_pdf(
        book_id=args.book_id,
        pdf_path=args.pdf,
        lang=args.lang,
        output_path=args.output,
        dpi=args.dpi,
    )


if __name__ == "__main__":
    main()
