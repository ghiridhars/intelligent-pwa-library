# Admin Guide

This guide covers everything needed to manage the library: adding books, editing the catalog, and configuring the Decap CMS admin panel.

---

## Overview: two tools, two roles

| Task | Tool | Why |
|---|---|---|
| Add a PDF to the library | `git` (command line) | PDFs are binary files up to 50 MB. Uploading them via the browser-based CMS uses the GitHub API, which is unreliable at that file size and frequently times out. Always use git for PDF files. |
| Edit book metadata (titles, language, page count) | Decap CMS at `/admin` | The CMS provides a visual form that commits changes to `catalog.json` directly, triggering the CI pipeline without needing a terminal. |

---

## Adding a new book — step by step

### Step 1: Add the PDF via git

```bash
# Copy your PDF into raw_assets/
cp /path/to/your/book.pdf raw_assets/your_book_id.pdf

# Stage and commit
git add raw_assets/your_book_id.pdf
git commit -m "Add PDF: Your Book Title"
```

Do **not** push yet. You need the OCR index first.

### Step 2: Run OCR locally

Activate the Python environment and run `ingest.py`:

```bash
source library_env/bin/activate

python scripts/ingest.py \
  --book-id   your_book_id \
  --pdf       raw_assets/your_book_id.pdf \
  --lang      mal \
  --output    data/indices/your_book_id.json
```

Replace `--lang mal` with `tam`, `hin`, or `san` depending on the book's language. See [OCR Pipeline](ocr-pipeline.md) for details.

### Step 3: Review the generated index

Open `data/indices/your_book_id.json` in a text editor and:

- Delete overflow page entries (pages with no song title — they show a lyric fragment as the title).
- Correct OCR misreads in `title_native`.
- Fill in `title_en` (English phonetic transliteration) for each song.
- Fill in `category` and `tags` as appropriate.

See [OCR Pipeline — human review](ocr-pipeline.md#the-human-review-step--mandatory-before-committing) for a full checklist.

### Step 4: Add the catalog entry

Log in to the Decap CMS at `https://username.github.io/library-manager/admin` (or edit `data/catalog.json` directly) and add:

```json
{
  "book_id": "your_book_id",
  "title": "Your Book Title",
  "primary_language": "ml",
  "languages": ["ml"],
  "script": "malayalam",
  "type": "pdf",
  "index_file": "data/indices/your_book_id.json",
  "asset_url": "raw_assets/your_book_id.pdf",
  "page_count": 300
}
```

If editing manually, `page_count` can be found with:
```bash
python3 -c "import pdfplumber; print(len(pdfplumber.open('raw_assets/your_book_id.pdf').pages))"
```

### Step 5: Commit and push everything

```bash
git add data/indices/your_book_id.json data/catalog.json
git commit -m "Add book: Your Book Title"
git push origin main
```

GitHub Actions picks up the push, detects the new PDF in `raw_assets/`, runs `ingest.py` again (as a CI validation — its output matches what you committed locally), builds Flutter Web, and deploys.

> **Note:** The CI also runs OCR on the PDF. If your local index and the CI-generated index differ significantly, it means you may have edited the local output without those changes being reproducible. That is expected — the local review is the source of truth. The CI OCR output is written to `data/indices/` in the `dist/` folder and deployed, overwriting your manually reviewed version.
>
> **To prevent this**, update the workflow to skip OCR if an index file already exists for that book, or have the workflow commit the reviewed index from the `main` branch rather than re-running OCR. This refinement can be done in a future workflow update.

---

## Decap CMS setup (one time)

### 1. Create a GitHub OAuth App

1. Go to **GitHub → Settings → Developer settings → OAuth Apps → New OAuth App**.
2. Fill in:
   - **Application name**: Library Manager Admin
   - **Homepage URL**: `https://username.github.io/library-manager`
   - **Authorization callback URL**: `https://api.netlify.com/auth/done`
3. Click **Register application**.
4. Copy the **Client ID**.
5. Click **Generate a new client secret** and copy it too (you will not see it again).

> The callback URL routes through Netlify's free OAuth proxy — this is how Decap CMS works with GitHub Pages without a custom backend. No Netlify account or hosting is required; only the proxy endpoint is used.

### 2. Configure the CMS

Open `web/admin/index.html` and replace the placeholder values:

```js
backend: {
  name: "github",
  repo: "username/library-manager",       // ← your GitHub username/repo
  branch: "main",
  base_url: "https://api.netlify.com",
  auth_endpoint: "auth",
  client_id: "YOUR_GITHUB_OAUTH_CLIENT_ID" // ← from step 4 above
},
```

The client secret is **not stored here**. Decap CMS handles the OAuth token exchange via the Netlify proxy — the secret is entered in Netlify's environment (or not needed at all, depending on the OAuth flow version). Check [Decap CMS GitHub backend docs](https://decapcms.org/docs/github-backend/) for the current setup instructions if the proxy flow changes.

### 3. Deploy and test

Push the updated `web/admin/index.html` to `main`. After the deploy completes, visit:

```
https://username.github.io/library-manager/admin
```

Click **Login with GitHub**. You should be redirected to GitHub's OAuth consent screen, then back to the CMS.

---

## Using the CMS day-to-day

The CMS is for **metadata only**. Do not upload PDFs through the CMS file widget.

**To edit an existing book's metadata:**
1. Log in at `/admin`.
2. Click **Book Catalog** → **catalog.json**.
3. Find the book entry in the list and update fields as needed.
4. Click **Save** → the CMS commits the change to `main` → GitHub Actions deploys.

**Fields available in the CMS form:**

| Field | Widget type | Notes |
|---|---|---|
| Book ID | Text | Must match the existing `book_id`. Do not change after the index is committed. |
| Title | Text | Display name shown in the app. |
| Primary Language | Dropdown | `ml`, `ta`, `hi`, `sa` |
| All Languages in Book | Multi-select | For books with mixed languages |
| Script | Dropdown | `malayalam`, `tamil`, `devanagari` |
| Index File Path | Text | e.g. `data/indices/bhajanamritam_01.json` |
| PDF Path | Text | e.g. `raw_assets/bhajanamritam_01.pdf` — add PDF via git first |
| Page Count | Number | Physical page count of the PDF |

---

## Editing the book index directly

For corrections after the initial OCR review, edit the JSON directly:

```bash
# Open the index in your editor
code data/indices/your_book_id.json

# Make corrections, then commit
git add data/indices/your_book_id.json
git commit -m "Fix OCR errors in your_book_id index"
git push origin main
```

GitHub Actions will deploy the updated index without re-running OCR (since the PDF has not changed).

---

## Removing a book

1. Remove the PDF: `git rm raw_assets/your_book_id.pdf`
2. Remove the index: `git rm data/indices/your_book_id.json`
3. Remove the entry from `data/catalog.json`.
4. Commit and push. GitHub Actions deploys the updated catalog without the book.
