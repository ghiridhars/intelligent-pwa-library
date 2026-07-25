import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/book.dart';
import 'screens/library_screen.dart';
import 'screens/login_screen.dart';
import 'screens/book_screen.dart';
import 'screens/pdf_screen.dart';
import 'services/catalog_service.dart';
import 'services/search_service.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
final userNotifier = ValueNotifier<String>('Guest');

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
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/library',
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
      catalog: CatalogService(),
      search: SearchService(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp.router(
            title: 'Library Manager',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0D47A1), // dark blue
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0D47A1), // dark blue
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
