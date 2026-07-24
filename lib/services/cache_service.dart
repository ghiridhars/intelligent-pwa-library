import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';

/// Manages persistent offline caching of book song indices using Hive.
///
/// Call [CacheService.init] once at app startup before creating instances.
class CacheService {
  static const _boxName = 'book_indices';

  /// Must be called once in main() before any CacheService is used.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_boxName);
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  /// Returns the cached song index for [bookId], or null if not cached.
  Future<List<Song>?> loadBookIndex(String bookId) async {
    final raw = _box.get(bookId);
    if (raw == null) return null;

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(Song.fromJson)
        .toList();
  }

  /// Saves [rawJson] (the raw HTTP response body) for [bookId].
  Future<void> saveBookIndex(String bookId, String rawJson) async {
    await _box.put(bookId, rawJson);
  }

  /// Removes the cached index for [bookId].
  Future<void> clearBookIndex(String bookId) async {
    await _box.delete(bookId);
  }

  /// Clears all cached book indices.
  Future<void> clearAll() async {
    await _box.clear();
  }
}
