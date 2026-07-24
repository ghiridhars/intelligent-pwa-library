import 'package:flutter/material.dart';
import 'app.dart';
import 'services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Hive for offline book index caching
  await CacheService.init();

  runApp(const LibraryApp());
}
