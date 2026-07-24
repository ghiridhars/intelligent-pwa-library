import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/book.dart';
import '../models/song.dart';

/// Displays the song index for a single book with live search.
class BookScreen extends StatefulWidget {
  final Book book;
  const BookScreen({required this.book, super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  late Future<List<Song>> _indexFuture;
  List<Song> _allSongs = [];
  List<Song> _filtered = [];
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _indexFuture = AppServices.of(context)
        .catalog
        .fetchBookIndex(widget.book)
        .then((songs) {
      _allSongs = songs;
      _filtered = songs;
      return songs;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshIndex() async {
    setState(() {
      _indexFuture = AppServices.of(context)
          .catalog
          .fetchBookIndex(widget.book, forceRefresh: true)
          .then((songs) {
        _allSongs = songs;
        _filtered = songs;
        return songs;
      });
    });

    try {
      await _indexFuture;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Index refreshed from server.')),
      );
    } catch (_) {
      // FutureBuilder already renders the detailed error.
    }
  }

  void _onSearchChanged(String query) {
    final results = AppServices.of(context)
        .search
        .search(_allSongs, query);
    setState(() => _filtered = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Refresh index',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshIndex,
          ),
        ],
      ),
      body: FutureBuilder<List<Song>>(
        future: _indexFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load index:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          return Column(
            children: [
              _SearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(child: Text('No songs match your search.'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) =>
                            _SongTile(
                              song: _filtered[index],
                              book: widget.book,
                            ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by title or tag…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  final Book book;
  const _SongTile({required this.song, required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        song.titleNative.isNotEmpty ? song.titleNative : song.titleEn,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        song.titleEn.isNotEmpty && song.titleNative.isNotEmpty
            ? '${song.titleEn} · p.${song.pageNumber}'
            : 'p.${song.pageNumber}',
        style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
      ),
      trailing: song.category.isNotEmpty
          ? Chip(
              label: Text(
                song.category,
                style: const TextStyle(fontSize: 11),
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )
          : null,
      onTap: () => context.push('/pdf', extra: (book, song.pageNumber)),
    );
  }
}
