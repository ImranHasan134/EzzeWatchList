// lib/ui/detail/detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../utils/app_theme.dart';
import '../add_edit/add_edit_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DetailScreen extends StatefulWidget {
  final int itemId;
  const DetailScreen({super.key, required this.itemId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  WatchItem? _item;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final item =
    await context.read<WatchProvider>().getItemById(widget.itemId);
    if (mounted) setState(() => _item = item);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete "${_item!.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<WatchProvider>().deleteItem(_item!.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_item == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final item = _item!;
    final showSeasonEp =
        item.category == Category.webSeries || item.category == Category.animeSeries;
    final genreDisplay = item.genres.replaceAll(',', ' • ');

    // Hindi available check
    final isHindi = (item.hindiAvailable ?? 'No') == 'Yes';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPoster(item),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Status + Category + Year + Hindi
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _StatusChip(status: item.status),
                      Text(item.category,
                          style: const TextStyle(color: Colors.grey)),
                      if (item.releaseYear.isNotEmpty)
                        Text('· ${item.releaseYear}',
                            style: const TextStyle(color: Colors.grey)),
                      if (isHindi)
                        const Text('· Hindi',
                            style: TextStyle(color: Colors.green)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: AppTheme.ratingGold, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${item.rating.toStringAsFixed(1)} / 10',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Genres
                  if (genreDisplay.isNotEmpty) ...[
                    const Text('GENRES',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(genreDisplay, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                  ],

                  // Season / Episode
                  if (showSeasonEp) ...[
                    Row(
                      children: [
                        Expanded(
                            child: _StatCard(
                                label: 'SEASONS',
                                value: item.seasons?.toString() ?? '-')),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _StatCard(
                                label: 'EPISODES',
                                value: item.episodes?.toString() ?? '-')),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  const Text('DESCRIPTION',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(
                    item.description.isNotEmpty
                        ? item.description
                        : 'No description.',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),

                  const SizedBox(height: 16),

                  // ── WATCH ON BOX WITH LOGOS ───────────────
                  if ((item.watchSource ?? '').isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WATCH ON',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 50,
                          width: 130,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10),
                            leading: _platformLogo(item.watchSource!),
                            title: Text(
                              item.watchSource!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            dense: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // Buttons: Edit / Delete
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      AddEditScreen(itemId: item.id)),
                            );
                            _loadItem();
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _delete,
                          icon:
                          const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPER METHODS ─────────────────────────────────────

  Widget _buildPoster(WatchItem item) {
    if (item.posterPath != null && item.posterPath!.isNotEmpty) {
      // 🆕 Check if the path is a Web URL from TMDB
      if (item.posterPath!.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: item.posterPath!,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _posterPlaceholder(),
        );
      }
      // Fallback for your existing local images
      else {
        return Image.file(File(item.posterPath!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _posterPlaceholder());
      }
    }
    return _posterPlaceholder();
  }

  Widget _posterPlaceholder() => Container(
    color: Colors.grey.shade400,
    child: const Icon(Icons.movie, size: 80, color: Colors.white54),
  );

  Widget _platformLogo(String platform) {
    const logoMap = {
      'MLWBD': 'assets/platform/logo/mlwbd.png',
      'MovieBox': 'assets/platform/logo/moviebox.png',
      'HiAnime': 'assets/platform/logo/hianime.png',
    };

    final path = logoMap[platform];

    if (path != null) {
      return Image.asset(
        path,
        width: 25,
        height: 25,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
        const Icon(Icons.play_circle_fill, size: 25),
      );
    }

    return const Icon(Icons.play_circle_fill, size: 25);
  }
}

// ── SMALL REUSABLE WIDGETS ─────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color => switch (status) {
    WatchStatus.watched => Colors.green,
    WatchStatus.watching => Colors.blue,
    _ => Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(status,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
