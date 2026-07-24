# Admin Guide

## Roles

| Person | What they do |
|---|---|
| **Admin** (non-technical) | Sends the PDF via file sharing. Fills in book metadata using the browser-based CMS panel at `/admin`. No terminal, no GitHub account required beyond a one-time collaborator invite. |
| **Developer** | Receives the PDF, runs OCR, reviews the output, commits everything, and pushes to `main`. Notifies the admin when ready. |

---

## Admin workflow — adding a new book

### Step 1: Send the PDF to the developer

Share the PDF via WhatsApp, email, Google Drive, or any convenient method. Along with the PDF, provide:

- Full title of the book
- Language (Malayalam, Tamil, Hindi, or Sanskrit)
- Approximate page count (visible in any PDF viewer)
- Any known category or tag information (deity names, raga names, etc.)

### Step 2: Wait for the developer to process it

The developer runs OCR, reviews the output, and commits the PDF and its search index. They will send back:

- **Book ID** (e.g. `bhajanamritam_01`)
- **Index File Path** (e.g. `data/indices/bhajanamritam_01.json`)
- **PDF Path** (e.g. `raw_assets/bhajanamritam_01.pdf`)

### Step 3: Add book metadata via the admin panel

1. Go to `https://username.github.io/library-manager/admin` in a browser.
2. Click **Login with GitHub** and complete the login.
3. Click **Book Catalog** → **catalog.json**.
4. Click **Add item**.
5. Fill in the form using the values the developer provided:

| Field | Where it comes from |
|---|---|
| Book ID | Developer provides |
| Title | You know this |
| Primary Language | Select from dropdown: Malayalam / Tamil / Hindi / Sanskrit |
| All Languages in Book | Multi-select if the book has mixed languages |
| Script | Select: Malayalam / Tamil / Devanagari |
| Index File Path | Developer provides (e.g. `data/indices/bhajanamritam_01.json`) |
| PDF Path | Developer provides (e.g. `raw_assets/bhajanamritam_01.pdf`) |
| Page Count | Visible in any PDF viewer |

6. Click **Save**.

The CMS commits the catalog change to `main`. GitHub Actions redeploys the site automatically. The new book appears in the library within a few minutes.

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

Do not add a `catalog.json` entry — the admin fills that in via the CMS.

### Step 5: Notify the admin

Send the admin:
- Book ID: `your_book_id`
- Index File Path: `data/indices/your_book_id.json`
- PDF Path: `raw_assets/your_book_id.pdf`

---

## Decap CMS setup (developer, one time)

### 1. Create a GitHub OAuth App

1. Go to **GitHub → Settings → Developer settings → OAuth Apps → New OAuth App**.
2. Fill in:
   - **Application name**: Library Manager Admin
   - **Homepage URL**: `https://username.github.io/library-manager`
   - **Authorization callback URL**: `https://api.netlify.com/auth/done`
3. Click **Register application** and copy the **Client ID**.

### 2. Configure the CMS

Open `web/admin/index.html` and update:

```js
backend: {
  name: "github",
  repo: "username/library-manager",        // ← your GitHub username/repo
  client_id: "YOUR_GITHUB_OAUTH_CLIENT_ID"  // ← from step above
},
```

### 3. Add the admin as a repo collaborator

Go to repo **Settings → Collaborators → Add people**.
Enter the admin's GitHub username and set role to **Write**.

The admin can now log in to the CMS panel and save catalog entries.

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

Log in at `/admin` → **Book Catalog** → **catalog.json** → find the book → edit fields → **Save**.

### Removing a book

```bash
git rm raw_assets/your_book_id.pdf
git rm data/indices/your_book_id.json
git commit -m "Remove book: Book Title"
git push origin main
```

Then remove the catalog entry via the CMS.
