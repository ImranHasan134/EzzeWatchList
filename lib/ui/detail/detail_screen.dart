// lib/ui/detail/detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../utils/app_theme.dart';
import '../add_edit/add_edit_screen.dart';

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
        item.category == Category.webSeries || item.category == Category.anime;
    final genreDisplay = item.genres.replaceAll(',', ' • ');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Collapsing header with poster ──────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPoster(item),
                  // Gradient scrim
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

          // ── Body content ───────────────────────────────────────────────
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

                  // Status chip + category + year
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
                    Text(genreDisplay,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                  ],

                  // Season / Episode cards
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
                  const SizedBox(height: 24),

                  // Action buttons
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
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
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

  Widget _buildPoster(WatchItem item) {
    if (item.posterPath != null && item.posterPath!.isNotEmpty) {
      return Image.file(File(item.posterPath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _posterPlaceholder());
    }
    return _posterPlaceholder();
  }

  Widget _posterPlaceholder() => Container(
        color: Colors.grey.shade400,
        child: const Icon(Icons.movie, size: 80, color: Colors.white54),
      );
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color => switch (status) {
        WatchStatus.watched  => Colors.green,
        WatchStatus.watching => Colors.blue,
        _                    => Colors.orange,
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
