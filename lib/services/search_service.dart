import '../models/song.dart';

/// Performs fuzzy search over a book's song index.
///
/// Searches across [Song.titleNative], [Song.titleEn], [Song.category],
/// and [Song.tags]. Results are ranked: title prefix matches score highest,
/// followed by title substring matches, then tag/category matches.
class SearchService {
  /// Filters and ranks [songs] by [query].
  ///
  /// Returns all songs if [query] is blank.
  /// All query words must appear somewhere in the song's searchable text.
  List<Song> search(List<Song> songs, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return songs;

    final words = q.split(RegExp(r'\s+'));
    final results = <_ScoredSong>[];

    for (final song in songs) {
      final searchable = song.searchableText;

      // Every word in the query must appear somewhere — no partial word order
      if (!words.every(searchable.contains)) continue;

      results.add(_ScoredSong(song, _score(song, q)));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.map((s) => s.song).toList();
  }

  int _score(Song song, String q) {
    int score = 0;
    final native = song.titleNative.toLowerCase();
    final en = song.titleEn.toLowerCase();

    // Prefix matches on title score highest
    if (native.startsWith(q) || en.startsWith(q)) score += 20;

    // Full substring match on title
    if (native.contains(q) || en.contains(q)) score += 10;

    // Match in category or tags
    if (song.category.toLowerCase().contains(q)) score += 3;
    if (song.tags.any((t) => t.toLowerCase().contains(q))) score += 2;

    return score;
  }
}

class _ScoredSong {
  final Song song;
  final int score;
  const _ScoredSong(this.song, this.score);
}
