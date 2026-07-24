/// Represents a single book entry from catalog.json.
class Book {
  final String bookId;
  final String title;
  final String primaryLanguage;
  final List<String> languages;
  final String script;
  final String type;
  final String indexFile;
  final String assetUrl;
  final int pageCount;

  const Book({
    required this.bookId,
    required this.title,
    required this.primaryLanguage,
    required this.languages,
    required this.script,
    required this.type,
    required this.indexFile,
    required this.assetUrl,
    required this.pageCount,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      bookId: json['book_id'] as String,
      title: json['title'] as String,
      primaryLanguage: json['primary_language'] as String,
      languages: List<String>.from(json['languages'] as List),
      script: json['script'] as String,
      type: json['type'] as String? ?? 'pdf',
      indexFile: json['index_file'] as String,
      assetUrl: json['asset_url'] as String,
      pageCount: json['page_count'] as int,
    );
  }

  /// Human-readable label for the primary language code.
  String get languageLabel {
    const labels = {
      'ml': 'Malayalam',
      'ta': 'Tamil',
      'hi': 'Hindi',
      'sa': 'Sanskrit',
    };
    return labels[primaryLanguage] ?? primaryLanguage.toUpperCase();
  }
}
