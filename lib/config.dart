import 'package:flutter/foundation.dart' show kIsWeb;

/// Central configuration.
///
/// Before building mobile (iOS/Android) releases, update [githubPagesUrl]
/// to match your actual GitHub Pages deployment URL.
class AppConfig {
  AppConfig._();

  /// Your GitHub Pages site URL — no trailing slash.
  /// Used by mobile builds to fetch catalog and book index JSON.
  static const String githubPagesUrl =
      'https://username.github.io/library-manager';

  /// Resolves a path (e.g. "data/catalog.json") to a full URL.
  ///
  /// On web, paths are resolved relative to the current page's base href,
  /// which Flutter sets via --base-href at build time.
  /// On mobile, paths are resolved against [githubPagesUrl].
  static Uri resolveUrl(String path) {
    if (kIsWeb) {
      // Uri.base respects the <base href> injected by `flutter build web`
      return Uri.base.resolve(path);
    }
    return Uri.parse('$githubPagesUrl/$path');
  }
}
