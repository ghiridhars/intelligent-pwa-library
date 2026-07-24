import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import '../config.dart';
import '../models/book.dart';

/// Renders the PDF for [book], opening at [initialPage].
///
/// Downloads the PDF via HTTP on first open. On web, the browser caches the
/// response automatically. On mobile, add flutter_cache_manager for
/// persistent disk caching in a future optimisation pass.
class PdfScreen extends StatefulWidget {
  final Book book;
  final int initialPage;

  const PdfScreen({
    required this.book,
    required this.initialPage,
    super.key,
  });

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  late PdfController _controller;
  int _currentPage = 1;
  late String _pdfUrl;

  @override
  void initState() {
    super.initState();
    _pdfUrl = AppConfig.resolveUrl(widget.book.assetUrl).toString();
    _controller = PdfController(
      document: PdfDocument.openData(_fetchPdfBytes(_pdfUrl)),
      initialPage: widget.initialPage,
    );
    _currentPage = widget.initialPage;
  }

  static Future<Uint8List> _fetchPdfBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load PDF (HTTP ${response.statusCode}) at $url',
      );
    }
    return response.bodyBytes;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Page $_currentPage of ${widget.book.pageCount}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.navigate_before),
            tooltip: 'Previous page',
            onPressed: _currentPage > 1
                ? () => _controller.previousPage(
                      curve: Curves.ease,
                      duration: const Duration(milliseconds: 200),
                    )
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            tooltip: 'Next page',
            onPressed: _currentPage < widget.book.pageCount
                ? () => _controller.nextPage(
                      curve: Curves.ease,
                      duration: const Duration(milliseconds: 200),
                    )
                : null,
          ),
        ],
      ),
      body: PdfView(
        controller: _controller,
        onPageChanged: (page) => setState(() => _currentPage = page),
        builders: PdfViewBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          pageLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, error) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Could not load PDF.'),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _pdfUrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
                if (kIsWeb)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'If HTTP 404 is shown above, commit the PDF file to raw_assets/ and redeploy.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


