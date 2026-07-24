/// Represents a single song/entry from a book's search index JSON.
class Song {
  final String songId;
  final String titleNative;
  final String titleEn;
  final String language;
  final String category;
  final int pageNumber;
  final List<String> tags;

  const Song({
    required this.songId,
    required this.titleNative,
    required this.titleEn,
    required this.language,
    required this.category,
    required this.pageNumber,
    required this.tags,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      songId: json['song_id'] as String,
      titleNative: json['title_native'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      language: json['language'] as String? ?? '',
      category: json['category'] as String? ?? '',
      pageNumber: json['page_number'] as int,
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  /// Combined searchable text — used by SearchService.
  String get searchableText =>
      '$titleNative $titleEn $category ${tags.join(' ')}'.toLowerCase();
}
