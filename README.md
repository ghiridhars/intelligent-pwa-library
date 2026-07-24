# Library Manager

A cross-platform app for searching and reading traditional Indian language songbooks (Malayalam, Tamil, Hindi, Sanskrit). Built with Flutter — runs as a PWA in the browser and as a native app on iOS and Android. Hosted for free on GitHub Pages.

## Documentation

| Document | What it covers |
|---|---|
| [Architecture](docs/architecture.md) | System design, tech stack decisions, data flow |
| [Setup](docs/setup.md) | Local development environment setup |
| [Data Schema](docs/data-schema.md) | JSON schema for catalog and book indices |
| [OCR Pipeline](docs/ocr-pipeline.md) | How to process a new PDF and generate its search index |
| [Admin Guide](docs/admin-guide.md) | Developer-managed content operations (current production workflow) |
| [Deployment](docs/deployment.md) | GitHub Pages deployment, CI/CD workflow |

## Quick start (web, local)

```bash
# Install Flutter dependencies
flutter pub get

# Serve the whole project on localhost:8000 so data/ and raw_assets/ are reachable
python3 -m http.server 8000 &

# Run Flutter web against the local server
flutter run -d chrome --web-port 5000
```

See [docs/setup.md](docs/setup.md) for full prerequisites and platform-specific instructions.

## Tech stack

- **Frontend**: Flutter 3.x (Web · iOS · Android)
- **Search**: Dart fuzzy search over static JSON indices
- **PDF viewer**: pdfx (PDF.js on web, native PDFKit/Android API on mobile)
- **Offline cache**: Hive (JSON indices); PDFs require internet
- **Content ops**: Developer-managed via git
- **OCR**: Python + Tesseract (Malayalam, Tamil, Hindi, Sanskrit)
- **Hosting**: GitHub Pages (free, public repo)
- **CI/CD**: GitHub Actions — change-detected OCR → Flutter build → deploy

## Current Operating Mode

The project currently runs in **developer-managed mode**:

1. PDF is added via git to `raw_assets/`
2. OCR index is generated and reviewed manually
3. `data/catalog.json` is updated directly in git
4. Push to `main` triggers deployment

## Next Action Plan

1. Stabilize content ingestion in developer-managed mode for the first 2-3 books.
2. Add workflow guardrails that fail CI if any `asset_url` file is missing.
3. Add OCR post-processing checks (duplicate page detection, empty-title detection).
4. Add an OCR quality artifact (`ocr_report.json`) to each workflow run.
5. Add optional language fallback for mixed-language books.
