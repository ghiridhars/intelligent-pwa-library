# Software Architecture Specification: Static PWA Library Manager

## 1. Project Overview
A lightweight, serverless library manager designed to index, search, and view traditional texts (Malayalam, Tamil, Hindi, and Sanskrit songbooks), PDFs, and scanned images. The system is built as a **cross-platform Flutter application** targeting Web, iOS, and Android from a single Dart codebase. The web version is hosted on GitHub Pages at zero cost. A static JSON architecture provides ultra-fast, offline-capable search without a backend server. PDFs are stored in the public repository and served via GitHub Pages.

## 2. Directory Structure
The repository is organized to separate the frontend application shell from the raw data and ingestion scripts.

├── .github/
│   └── workflows/
│       └── build-index.yml      # OCR on changed PDFs, Flutter Web build, deploy to gh-pages branch
├── lib/                         # Flutter/Dart application source
│   ├── main.dart                # App entry point
│   ├── models/
│   │   ├── book.dart            # Catalog entry model
│   │   └── song.dart            # Search index entry model
│   ├── screens/
│   │   ├── library_screen.dart  # Book catalog view
│   │   ├── book_screen.dart     # Per-book search and page list
│   │   └── pdf_screen.dart      # PDF viewer
│   └── services/
│       ├── catalog_service.dart # Fetches and caches catalog.json
│       └── search_service.dart  # Fuzzy search across title_native + title_en
├── web/                         # Flutter Web configuration
│   ├── index.html               # Entry point (base href injected by Flutter at build time)
│   ├── manifest.json            # PWA manifest
│   ├── admin/                   # Decap CMS (served at /admin after deployment)
│   │   └── index.html
│   └── icons/
├── data/                        # Generated JSON indices (fetched at runtime, not bundled)
│   ├── catalog.json             # Master library list
│   └── indices/
│       ├── bhajanamritam.json   # Processed index for Book 1
│       └── book_2.json
├── raw_assets/                  # PDFs served publicly via GitHub Pages (max 50MB per file)
│   ├── bhajanamritam.pdf
│   └── scanned_images/
├── scripts/                     # Python OCR pipeline (unchanged)
│   └── ingest.py                # Per-page OCR and JSON index generation
├── pubspec.yaml                 # Flutter dependencies
└── analysis_options.yaml        # Dart linting configuration

```

## 3. Database Schema (Static JSON)

Data is structured statically. `catalog.json` drives the main library view, while individual book indices are fetched dynamically only when a user searches or opens that specific book.

The schema is language-neutral to support Malayalam, Tamil, Hindi, and Sanskrit books. A book may contain a single language or multiple languages (e.g., Tamil songs with Sanskrit verses); the `languages` array and per-entry `language` field handle both cases.

**`catalog.json`** (Master List)

```json
[
  {
    "book_id": "bhajanamritam_01",
    "title": "Bhajanamritam",
    "primary_language": "ml",
    "languages": ["ml"],
    "script": "malayalam",
    "type": "pdf",
    "index_file": "data/indices/bhajanamritam.json",
    "asset_url": "raw_assets/bhajanamritam.pdf",
    "page_count": 425
  }
]

```

**`bhajanamritam.json`** (Search Index)

```json
[
  {
    "song_id": "b01_188",
    "title_native": "അഞ്ചേൽ",
    "title_en": "Anchel",
    "language": "ml",
    "category": "Subrahmanyan",
    "page_number": 188,
    "tags": ["murugan", "kuntalavarali", "adi"]
  }
]

```

For a mixed-language book, each entry carries its own `language` field (e.g., `"ml"`, `"ta"`, `"hi"`, `"sa"`). Fuse.js searches across both `title_native` and `title_en`, enabling users to find songs by typing either native script or English phonetic transliteration.

## 4. Ingestion & OCR Pipeline (Ubuntu Setup)

To extract text from non-indexed PDFs or image files, the processing pipeline utilizes Tesseract OCR. To set up the OCR engine and Malayalam language packs locally on an Ubuntu system, run the following via the package manager:

```bash
sudo apt update
sudo apt install tesseract-ocr tesseract-ocr-mal tesseract-ocr-tam tesseract-ocr-hin tesseract-ocr-san libtesseract-dev

```

Language pack reference: `tesseract-ocr-mal` (Malayalam), `tesseract-ocr-tam` (Tamil), `tesseract-ocr-hin` (Hindi/Devanagari), `tesseract-ocr-san` (Sanskrit/Devanagari). Hindi and Sanskrit share the Devanagari script; either pack can be used for both.

**Python Environment Setup:**

```bash
python3 -m venv library_env
source library_env/bin/activate
pip install pytesseract pdfplumber PyPDF2

```

The ingestion script (`ingest.py`) processes every page of the PDF individually. For each page it: (1) renders the page to an image via `pdfplumber`, (2) runs Tesseract with the language pack specified in the book's catalog entry (e.g., `--lang mal` for Malayalam, `--lang tam` for Tamil), and (3) extracts the topmost non-whitespace text block as the song title, associating it with the page number.

Generated JSON index files are written to `/data/indices/`. **A human review step is required before committing the output**: OCR may misread complex or traditional typography, and overflow pages (where a song from the previous page continues with no title) will produce incorrect entries. The review step should be done locally before pushing to `main`.

## 5. Application Management Interface

**Decap CMS** (formerly Netlify CMS) is the admin interface for this library. It provides a browser-based visual dashboard at `yourdomain.com/admin`. Admins log in with their GitHub account, upload PDFs to `raw_assets/`, and fill in book metadata through visual forms — no command line required. Each save in the CMS creates a Git commit, which triggers the `build-index.yml` workflow to regenerate JSON indices and redeploy.

**One-time setup required:** Create a GitHub OAuth App in GitHub Developer Settings, setting the callback URL to `https://api.netlify.com/auth/done`. Decap CMS routes its auth token exchange through Netlify's free auth proxy — no Netlify hosting is required, only the proxy endpoint. The OAuth App credentials are stored in `web/admin/index.html`.

**PDF files must be added via git, not via the CMS.** Uploading a 50MB binary through a browser-based CMS commits it via the GitHub Contents API, which is unreliable at that file size and frequently times out. Use the CMS only for metadata (catalog entries). Add PDFs by committing them locally:

```bash
git add raw_assets/newbook.pdf
git commit -m "Add new book PDF"
git push origin main
```

**Admin workflow for adding a new book:**
1. Copy the PDF to `raw_assets/` locally and push via git (see above).
2. Log in at `/admin` with your GitHub account.
3. Create a new catalog entry in the CMS with:
   - **Title** — free text
   - **Primary Language** — dropdown (select widget): Malayalam, Tamil, Hindi, Sanskrit
   - **Additional Languages** — multi-select (for mixed-language books, e.g. Tamil + Sanskrit)
   - **Page Count** — number field
4. Click **Save** — this commits the catalog change to `main` and triggers GitHub Actions.
5. The Actions workflow reads `primary_language` from `catalog.json`, runs `ingest.py` with the correct Tesseract language flag, builds Flutter Web, and deploys.
6. Pull the branch locally, review `data/indices/<book>.json` for OCR errors, push corrections if needed.

## 6. Frontend Implementation (Flutter)

The frontend is a Flutter application compiled to three targets from a single Dart codebase.

**Target Platforms**
- **Web**: `flutter build web --base-href /repo-name/` — deployed to GitHub Pages as a PWA (installable, offline catalog and search).
- **iOS**: `flutter build ios` — distributed via TestFlight initially; App Store submission when ready.
- **Android**: `flutter build appbundle` — distributed via Google Play or direct APK.

**Key Flutter Packages (`pubspec.yaml`)**
```yaml
dependencies:
  http: ^1.2.0                   # Fetching catalog.json and book JSON indices
  pdfx: ^2.6.0                   # Cross-platform PDF rendering (iOS, Android, Web)
  go_router: ^13.0.0             # Declarative routing and deep linking to specific pages
  hive_flutter: ^1.1.0           # Offline cache for downloaded JSON indices
  flutter_cache_manager: ^3.3.0  # HTTP-level response caching
```

**Search**: `search_service.dart` loads the book's JSON index on first open and performs fuzzy matching across `title_native` and `title_en` using a Dart-native implementation. No external JS library. Users can type in either native script or English phonetics (e.g., "Anchel" matches "അഞ്ചേൽ"). Search is scoped per-book; the index is held in memory and persisted to Hive for offline reuse.

**PDF Viewer**: `pdfx` renders PDFs natively on iOS and Android. On Web, it renders via a browser-managed iframe pointing to the PDF URL in `raw_assets/`. The `page_number` from a search result is passed to the viewer to open at the correct page. An active internet connection is required for PDF loading on all platforms.

**Offline Support**: Flutter Web generates a versioned `flutter_service_worker.js` automatically at build time — no manual `sw.js` required. The app shell (compiled Dart JS, fonts, icons) and `catalog.json` are precached. Book JSON indices are cached in Hive after first load. **PDFs are not cached** — offline mode covers catalog browsing and search only.

**Bundle size note**: The initial Flutter Web download is approximately 8–12 MB (Dart runtime + compiled app). Subsequent loads are served from the service worker cache. This is a known tradeoff of Flutter Web versus a plain HTML/JS build, acceptable for a repeat-visitor app.

## 7. Deployment Workflow

1. **Commit:** Code and scripts are pushed to `main` via CLI. PDFs are added to `raw_assets/` via git only (not the CMS). Catalog metadata changes can be made via Decap CMS at `/admin`.

2. **GitHub Actions (`build-index.yml`) pipeline:**
   ```
   a. Detect changed PDFs: git diff --name-only HEAD~1 HEAD -- raw_assets/
   b. Run ingest.py only on changed books → writes to data/indices/
   c. flutter build web --base-href /repo-name/
   d. Assemble deployment: copy build/web/ + data/ + raw_assets/ into dist/
   e. Push dist/ to the gh-pages branch (peaceiris/actions-gh-pages)
   ```
   OCR only runs on books whose PDFs changed, preventing unnecessary compute on unrelated pushes.

3. **GitHub Pages** serves the `gh-pages` branch root. Flutter Web, JSON indices, and PDFs are all co-located under the same origin — no CORS issues, no multi-directory serving complexity.

4. **Path resolution**: `--base-href /repo-name/` injects the correct base path into `web/index.html` at build time. All Dart HTTP requests construct URLs relative to this base, so `raw_assets/bhajanamritam.pdf` correctly resolves to `https://username.github.io/repo-name/raw_assets/bhajanamritam.pdf`.

5. **PDFs are publicly accessible URLs** — anyone with the link can download them directly. This is an accepted constraint of the static hosting model.