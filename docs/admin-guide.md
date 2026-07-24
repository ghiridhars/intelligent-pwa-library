# Admin Guide

## Status

The active workflow is **developer-managed content operations**.

This means:

- Non-technical admin sends source PDFs and metadata by message/email/drive.
- Developer performs OCR, review, catalog updates, and deployment via git.
- GitHub Actions publishes the result to GitHub Pages.

## Roles

| Person | What they do |
|---|---|
| **Admin** (non-technical) | Sends PDF + metadata (title, language, optional tags) via WhatsApp/email/Drive. Reviews published output in the app. |
| **Developer** | Receives PDF, runs OCR, reviews/fixes index JSON, updates catalog JSON, commits and pushes to `main`. |

---

## Admin workflow — adding a new book (current)

### Step 1: Send the PDF to the developer

Share the PDF via WhatsApp, email, Google Drive, or any convenient method. Along with the PDF, provide:

- Full title of the book
- Language (Malayalam, Tamil, Hindi, or Sanskrit)
- Approximate page count (visible in any PDF viewer)
- Any known category or tag information (deity names, raga names, etc.)

### Step 2: Wait for developer processing and review

Developer runs OCR, reviews the output, updates catalog, and deploys. Admin validates the live app output and shares corrections.

### Step 3: Verify the published book

Admin checks:

- Book appears in library list
- Search results are sensible
- PDF opens and page jump works

If anything is wrong, admin reports the exact song/page to developer for correction.

---

## Developer workflow — processing a received PDF

### Step 1: Save the PDF

```bash
cp ~/Downloads/received_book.pdf raw_assets/your_book_id.pdf
```

Choose a `book_id` that is lowercase with underscores (e.g. `bhajanamritam_01`). This ID is permanent — do not change it after committing.

### Step 2: Run OCR

```bash
source library_env/bin/activate

python scripts/ingest.py \
  --book-id   your_book_id \
  --pdf       raw_assets/your_book_id.pdf \
  --lang      mal \
  --output    data/indices/your_book_id.json
```

Replace `--lang mal` with `tam`, `hin`, or `san` for Tamil, Hindi, or Sanskrit.

### Step 3: Review the OCR output

Open `data/indices/your_book_id.json` and:

- Delete overflow page entries (pages with no song title — they show a lyric fragment).
- Correct OCR misreads in `title_native`.
- Fill in `title_en` (English phonetic transliteration) for each song.
- Fill in `category` and `tags` where known.

See [OCR Pipeline — review checklist](ocr-pipeline.md#the-human-review-step--mandatory-before-committing) for the full list.

### Step 4: Commit and push

```bash
git add raw_assets/your_book_id.pdf
git add data/indices/your_book_id.json
git commit -m "Add book: Book Title Here"
git push origin main
```

Then add/update `data/catalog.json` (top-level `books` list) in the same commit.

### Step 5: Push and notify admin

After push, send admin the published URL and ask for validation.

---

## Other operations

### Correcting OCR errors after deployment

```bash
code data/indices/your_book_id.json  # edit, then:
git add data/indices/your_book_id.json
git commit -m "Fix OCR errors in your_book_id"
git push origin main
```

GitHub Actions redeploys with the corrected index. No OCR re-run (PDF unchanged).

### Editing existing metadata

Edit `data/catalog.json` in git, then commit and push.

### Removing a book

```bash
git rm raw_assets/your_book_id.pdf
git rm data/indices/your_book_id.json
git commit -m "Remove book: Book Title"
git push origin main
```

Then remove the corresponding entry from `data/catalog.json` and push.
