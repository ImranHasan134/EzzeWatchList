// lib/ui/detail/detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // 🆕 Import the new player
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../utils/app_theme.dart';
import '../../data/network/tmdb_service.dart';
import '../add_edit/add_edit_screen.dart';

class DetailScreen extends StatefulWidget {
  final int itemId;
  const DetailScreen({super.key, required this.itemId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  WatchItem? _item;
  List<CastMember> _castMembers = [];
  bool _isFetchingExtras = false;

  YoutubePlayerController? _ytController; // 🆕 Controller for the inline player

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void dispose() {
    _ytController?.dispose(); // 🆕 Always dispose the controller to prevent memory leaks
    super.dispose();
  }

  Future<void> _loadItem() async {
    final item = await context.read<WatchProvider>().getItemById(widget.itemId);
    if (mounted && item != null) {
      setState(() {
        _item = item;
        _castMembers = [];
        _isFetchingExtras = true;
      });

      int? activeTmdbId = item.tmdbId;

      try {
        // ── AUTO-HEAL: Fix old movies ──
        if (activeTmdbId == null) {
          final searchResults = await TmdbService().searchContent(item.title);
          if (searchResults.isNotEmpty) {
            activeTmdbId = searchResults.first['tmdbId'] as int?;
            if (activeTmdbId != null) {
              final updatedItem = WatchItem(
                id: item.id, title: item.title, category: item.category,
                genres: item.genres, releaseYear: item.releaseYear,
                description: item.description, rating: item.rating,
                status: item.status, posterPath: item.posterPath,
                seasons: item.seasons, episodes: item.episodes,
                createdAt: item.createdAt, hindiAvailable: item.hindiAvailable,
                watchSource: item.watchSource, tmdbId: activeTmdbId,
              );
              context.read<WatchProvider>().updateItem(updatedItem);
            }
          }
        }

        // ── FETCH TRAILER & CAST IN PARALLEL ──
        if (activeTmdbId != null) {
          final isMovie = item.category == Category.movie || item.category == 'Anime Movie';
          final results = await Future.wait([
            TmdbService().getTrailerUrl(activeTmdbId, isMovie),
            TmdbService().getCast(activeTmdbId, isMovie),
          ]);

          if (mounted) {
            final trailerUrl = results[0] as String?;

            // 🆕 Initialize the YouTube Player if a trailer exists
            if (trailerUrl != null) {
              final videoId = YoutubePlayer.convertUrlToId(trailerUrl);
              if (videoId != null) {
                _ytController = YoutubePlayerController(
                  initialVideoId: videoId,
                  flags: const YoutubePlayerFlags(
                    autoPlay: false, // Don't blast audio immediately
                    mute: false,
                    disableDragSeek: false,
                    loop: false,
                    isLive: false,
                    forceHD: true,
                  ),
                );
              }
            }

            setState(() {
              _castMembers = results[1] as List<CastMember>;
            });
          }
        }
      } finally {
        if (mounted) setState(() => _isFetchingExtras = false);
      }
    }
  }

  // ── STATUS LOGIC ──
  Future<void> _changeStatus(String newStatus) async {
    if (_item == null) return;
    try {
      final updatedItem = WatchItem(
        id: _item!.id, title: _item!.title, category: _item!.category,
        genres: _item!.genres, releaseYear: _item!.releaseYear,
        description: _item!.description, rating: _item!.rating,
        status: newStatus, posterPath: _item!.posterPath,
        seasons: _item!.seasons, episodes: _item!.episodes,
        createdAt: _item!.createdAt, hindiAvailable: _item!.hindiAvailable,
        watchSource: _item!.watchSource, tmdbId: _item!.tmdbId,
      );
      await context.read<WatchProvider>().updateItem(updatedItem);
      await _loadItem();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent));
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
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
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
    if (_item == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final item = _item!;
    final showSeasonEp = item.category == 'Web Series' || item.category == 'Anime Series';
    final genreDisplay = item.genres.replaceAll(',', ' • ');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPoster(item),
                  DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5)]))),
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
                  Text(item.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8, runSpacing: 4,
                    children: [
                      _StatusChip(status: item.status),
                      Text(item.category, style: const TextStyle(color: Colors.grey)),
                      if (item.releaseYear.isNotEmpty) Text('· ${item.releaseYear}', style: const TextStyle(color: Colors.grey)),
                      if ((item.hindiAvailable ?? 'No') == 'Yes') const Text('· Hindi', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 22),
                      const SizedBox(width: 6),
                      Text('${item.rating.toStringAsFixed(1)} / 10', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (genreDisplay.isNotEmpty) ...[
                    Text(genreDisplay, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                  ],

                  // ── 🆕 INLINE YOUTUBE PLAYER ──
                  if (_isFetchingExtras)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))))
                  else if (_ytController != null) ...[
                    const Text('OFFICIAL TRAILER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: YoutubePlayer(
                        controller: _ytController!,
                        showVideoProgressIndicator: true,
                        progressColors: const ProgressBarColors(
                          playedColor: Color(0xFFFFD700),
                          handleColor: Color(0xFFFFD700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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

                  const Text('STORYLINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(item.description.isNotEmpty ? item.description : 'No description available.', style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white70)),
                  const SizedBox(height: 24),

                  if ((item.watchSource ?? '').isNotEmpty) ...[
                    const Text('AVAILABLE ON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _platformLogo(item.watchSource!),
                          const SizedBox(width: 12),
                          Text(item.watchSource!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── ACTION BUTTONS ──
                  if (item.status == WatchStatus.planned) ...[
                    Row(
                      children: [
                        Expanded(child: FilledButton.icon(onPressed: () => _changeStatus(WatchStatus.watching), icon: const Icon(Icons.play_arrow), label: const Text('Start Watching'), style: FilledButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 12)))),
                        const SizedBox(width: 12),
                        Expanded(child: FilledButton.icon(onPressed: () => _changeStatus(WatchStatus.watched), icon: const Icon(Icons.check), label: const Text('Mark Watched'), style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)))),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else if (item.status == WatchStatus.watching) ...[
                    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _changeStatus(WatchStatus.watched), icon: const Icon(Icons.check), label: const Text('Mark as Finished'), style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)))),
                    const SizedBox(height: 16),
                  ],

                  if (_castMembers.isNotEmpty) ...[
                    const Text('TOP CAST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _castMembers.length,
                        itemBuilder: (context, index) => _buildCastCard(_castMembers[index]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Edit / Delete ──
                  Row(
                    children: [
                      Expanded(child: OutlinedButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditScreen(itemId: item.id))); _loadItem(); }, icon: const Icon(Icons.edit, color: Color(0xFFFFD700)), label: const Text('Edit', style: TextStyle(color: Color(0xFFFFD700))), style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFFD700)), padding: const EdgeInsets.symmetric(vertical: 12)))),
                      const SizedBox(width: 12),
                      Expanded(child: OutlinedButton.icon(onPressed: _delete, icon: const Icon(Icons.delete_outline, color: Colors.redAccent), label: const Text('Delete', style: TextStyle(color: Colors.redAccent)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(vertical: 12)))),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPER METHODS ──
  Widget _buildPoster(WatchItem item) {
    if (item.posterPath != null && item.posterPath!.isNotEmpty) {
      if (item.posterPath!.startsWith('http')) return CachedNetworkImage(imageUrl: item.posterPath!, fit: BoxFit.cover, alignment: Alignment.topCenter);
      else return Image.file(File(item.posterPath!), fit: BoxFit.cover, alignment: Alignment.topCenter);
    }
    return Container(color: Colors.grey.shade900, child: const Icon(Icons.movie, size: 80, color: Colors.white24));
  }

  Widget _platformLogo(String platform) {
    const logoMap = {'MLWBD': 'assets/platform/logo/mlwbd.png', 'MovieBox': 'assets/platform/logo/moviebox.png', 'HiAnime': 'assets/platform/logo/hianime.png'};
    final path = logoMap[platform];
    if (path != null) return Image.asset(path, width: 24, height: 24, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.play_circle_fill, size: 24));
    return const Icon(Icons.play_circle_fill, size: 24);
  }

  Widget _buildCastCard(CastMember member) {
    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey.shade800,
            backgroundImage: member.profilePath != null ? CachedNetworkImageProvider('https://image.tmdb.org/t/p/w200${member.profilePath}') : null,
            child: member.profilePath == null ? const Icon(Icons.person, size: 30, color: Colors.white54) : null,
          ),
          const SizedBox(height: 8),
          Text(member.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, height: 1.1)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    Color color = status == WatchStatus.watched ? Colors.green : status == WatchStatus.watching ? Colors.blue : Colors.orange;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)), child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]));
  }
}