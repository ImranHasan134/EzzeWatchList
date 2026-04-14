// lib/ui/detail/detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // 🆕 Import url_launcher
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../utils/app_theme.dart';
import '../../data/network/tmdb_service.dart'; // 🆕 Import CastMember
import '../add_edit/add_edit_screen.dart';

class DetailScreen extends StatefulWidget {
  final int itemId;
  const DetailScreen({super.key, required this.itemId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  WatchItem? _item;
  String? _trailerUrl; // 🆕 Trailer URL state
  List<CastMember> _castMembers = []; // 🆕 Cast members state

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final item = await context.read<WatchProvider>().getItemById(widget.itemId);
    if (mounted) {
      setState(() {
        _item = item;
        _trailerUrl = null; // reset
        _castMembers = []; // reset
      });

      // Fetch trailers/cast if tmdbId exists 🆕
      if (_item != null && _item!.tmdbId != null) {
        final trailerUrl = await TmdbService().getTrailerUrl(_item!.tmdbId!, _item!.category == Category.movie);
        final castMembers = await TmdbService().getCast(_item!.tmdbId!, _item!.category == Category.movie);
        if (mounted) {
          setState(() {
            _trailerUrl = trailerUrl;
            _castMembers = castMembers;
          });
        }
      }
    }
  }

  // 🆕 Logic to instantly update status from the Detail Screen
  // ── 🆕 UPGRADED STATUS LOGIC WITH ERROR HANDLING ────────
  Future<void> _changeStatus(String newStatus) async {
    if (_item == null) return;

    try {
      final updatedItem = WatchItem(
        id: _item!.id,
        title: _item!.title,
        category: _item!.category,
        genres: _item!.genres,
        releaseYear: _item!.releaseYear,
        description: _item!.description,
        rating: _item!.rating,
        status: newStatus,
        posterPath: _item!.posterPath,
        seasons: _item!.seasons,
        episodes: _item!.episodes,
        createdAt: _item!.createdAt,
        hindiAvailable: _item!.hindiAvailable,
        watchSource: _item!.watchSource,
        tmdbId: _item!.tmdbId,
      );

      // Update the database & cloud
      await context.read<WatchProvider>().updateItem(updatedItem);

      // Refresh the UI
      await _loadItem();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Status Update Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete "${_item!.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final item = _item!;
    final showSeasonEp = item.category == Category.webSeries || item.category == Category.animeSeries;
    final genreDisplay = item.genres.replaceAll(',', ' • ');
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
                  Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _StatusChip(status: item.status),
                      Text(item.category, style: const TextStyle(color: Colors.grey)),
                      if (item.releaseYear.isNotEmpty) Text('· ${item.releaseYear}', style: const TextStyle(color: Colors.grey)),
                      if (isHindi) const Text('· Hindi', style: TextStyle(color: Colors.green)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.ratingGold, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${item.rating.toStringAsFixed(1)} / 10',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (genreDisplay.isNotEmpty) ...[
                    const Text('GENRES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(genreDisplay, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                  ],

                  if (showSeasonEp) ...[
                    Row(
                      children: [
                        Expanded(child: _StatCard(label: 'SEASONS', value: item.seasons?.toString() ?? '-')),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(label: 'EPISODES', value: item.episodes?.toString() ?? '-')),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text('DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(
                    item.description.isNotEmpty ? item.description : 'No description.',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),

                  const SizedBox(height: 16),

                  if ((item.watchSource ?? '').isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WATCH ON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Container(
                          height: 50,
                          width: 130,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            leading: _platformLogo(item.watchSource!),
                            title: Text(item.watchSource!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            dense: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // ── 🆕 STATUS ACTION BUTTONS (Start Watching / Mark Watched) ────────
                  if (item.status == WatchStatus.planned) ...[
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _changeStatus(WatchStatus.watching),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Watching'),
                            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _changeStatus(WatchStatus.watched),
                            icon: const Icon(Icons.check),
                            label: const Text('Mark Watched'),
                            style: FilledButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else if (item.status == WatchStatus.watching) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _changeStatus(WatchStatus.watched),
                        icon: const Icon(Icons.check),
                        label: const Text('Mark as Finished'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── 🆕 TRAILER BUTTON ──────────
                  if (_trailerUrl != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (!await launchUrl(Uri.parse(_trailerUrl!))) {
                            // Handle implicitly
                          }
                        },
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text('Watch Trailer'),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF4500)), // Deep Orange/Red
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── 🆕 CAST SECTION ──────────
                  if (_castMembers.isNotEmpty) ...[
                    const Text('TOP CAST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 130, // Adjust height
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _castMembers.length,
                        itemBuilder: (context, index) {
                          final member = _castMembers[index];
                          return _buildCastCard(member);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
      if (item.posterPath!.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: item.posterPath!,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _posterPlaceholder(),
        );
      }
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

  // 🆕 helper widget for cast
  Widget _buildCastCard(CastMember member) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: member.profilePath != null
                ? CachedNetworkImageProvider('https://image.tmdb.org/t/p/w200${member.profilePath}')
                : null,
            child: member.profilePath == null ? const Icon(Icons.person, size: 35) : null,
          ),
          const SizedBox(height: 6),
          Text(member.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          Text(member.character, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
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