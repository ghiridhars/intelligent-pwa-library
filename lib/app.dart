import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/book.dart';
import 'screens/library_screen.dart';
import 'screens/book_screen.dart';
import 'screens/pdf_screen.dart';
import 'services/catalog_service.dart';
import 'services/cache_service.dart';
import 'services/search_service.dart';

/// Makes [CatalogService] and [SearchService] available to the whole widget tree.
class AppServices extends InheritedWidget {
  final CatalogService catalog;
  final SearchService search;

  const AppServices({
    required this.catalog,
    required this.search,
    required super.child,
    super.key,
  });

  static AppServices of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppServices>();
    assert(result != null, 'AppServices not found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppServices old) => false;
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  static final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/book/:bookId',
        builder: (_, state) {
          final book = state.extra as Book;
          return BookScreen(book: book);
        },
      ),
      GoRoute(
        path: '/pdf',
        builder: (_, state) {
          final extra = state.extra as (Book, int);
          return PdfScreen(book: extra.$1, initialPage: extra.$2);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return AppServices(
      catalog: CatalogService(cache: CacheService()),
      search: SearchService(),
      child: MaterialApp.router(
        title: 'Library Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6B3FA0), // deep purple
          ),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
