# Library Manager

A cross-platform app for searching and reading traditional Indian language songbooks (Malayalam, Tamil, Hindi, Sanskrit). Built with Flutter — runs as a PWA in the browser and as a native app on iOS and Android. Hosted for free on GitHub Pages.

## Documentation

| Document | What it covers |
|---|---|
| [Architecture](docs/architecture.md) | System design, tech stack decisions, data flow |
| [Setup](docs/setup.md) | Local development environment setup |
| [Data Schema](docs/data-schema.md) | JSON schema for catalog and book indices |
| [OCR Pipeline](docs/ocr-pipeline.md) | How to process a new PDF and generate its search index |
| [Admin Guide](docs/admin-guide.md) | How to add books, configure Decap CMS |
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
- **Admin UI**: Decap CMS at `/admin`
- **OCR**: Python + Tesseract (Malayalam, Tamil, Hindi, Sanskrit)
- **Hosting**: GitHub Pages (free, public repo)
- **CI/CD**: GitHub Actions — change-detected OCR → Flutter build → deploy
