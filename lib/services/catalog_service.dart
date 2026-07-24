import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/book.dart';
import '../models/song.dart';
import 'cache_service.dart';

/// Fetches and caches the book catalog and per-book song indices.
class CatalogService {
  final CacheService _cache;

  // In-memory catalog — fetched once per app session.
  List<Book>? _catalog;

  CatalogService({CacheService? cache})
      : _cache = cache ?? CacheService();

  /// Returns the full book catalog. Fetched fresh on first call per session;
  /// subsequent calls return the in-memory copy.
  Future<List<Book>> fetchCatalog() async {
    if (_catalog != null) return _catalog!;

    final uri = AppConfig.resolveUrl('data/catalog.json');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load catalog (HTTP ${response.statusCode}): $uri',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    List<dynamic> raw;

    if (decoded is List<dynamic>) {
      // Backward compatibility with older catalog.json shape.
      raw = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['books'] is List<dynamic>) {
      // Supported shape: { "books": [ ... ] }
      raw = decoded['books'] as List<dynamic>;
    } else {
      throw Exception(
        'Invalid catalog format. Expected a list or an object with a "books" list.',
      );
    }

    _catalog = raw.cast<Map<String, dynamic>>().map(Book.fromJson).toList();

    return _catalog!;
  }

  /// Returns the song index for [book].
  ///
  /// Checks the persistent Hive cache first (unless [forceRefresh] is true).
  /// Falls back to an HTTP fetch and writes the result to cache for offline
  /// use on subsequent opens.
  Future<List<Song>> fetchBookIndex(Book book, {bool forceRefresh = false}) async {
    // Check offline cache first unless a network refresh is explicitly requested.
    if (!forceRefresh) {
      final cached = await _cache.loadBookIndex(book.bookId);
      if (cached != null) return cached;
    }

    // Fetch from network
    final uri = AppConfig.resolveUrl(book.indexFile);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load book index (HTTP ${response.statusCode}): $uri',
      );
    }

    final List<dynamic> raw = jsonDecode(response.body) as List<dynamic>;
    final songs = raw
        .cast<Map<String, dynamic>>()
        .map(Song.fromJson)
        .toList();

    // Persist to cache for offline access
    await _cache.saveBookIndex(book.bookId, response.body);

    return songs;
  }

  /// Clears the in-memory catalog cache. Useful for pull-to-refresh.
  void invalidateCatalog() => _catalog = null;
}
