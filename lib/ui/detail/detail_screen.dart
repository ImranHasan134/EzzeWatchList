// lib/ui/detail/detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

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

  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  // ── REFINED LOGIC: AUTOMATIC TMDB FETCHING PRESERVED ──
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
        if (activeTmdbId == null) {
          final searchResults = await TmdbService().searchContent(item.title);
          if (searchResults.isNotEmpty) {
            activeTmdbId = searchResults.first['tmdbId'] as int?;
            if (activeTmdbId != null) {
              final updatedItem = item.copyWith(tmdbId: activeTmdbId);
              context.read<WatchProvider>().updateItem(updatedItem);
            }
          }
        }

        if (activeTmdbId != null) {
          final isMovie = item.category == Category.movie || item.category == 'Anime Movie';
          final results = await Future.wait([
            TmdbService().getTrailerUrl(activeTmdbId, isMovie),
            TmdbService().getCast(activeTmdbId, isMovie),
          ]);

          if (mounted) {
            final trailerUrl = results[0] as String?;

            if (trailerUrl != null) {
              final videoId = YoutubePlayer.convertUrlToId(trailerUrl);
              if (videoId != null) {
                _ytController = YoutubePlayerController(
                  initialVideoId: videoId,
                  flags: const YoutubePlayerFlags(
                    autoPlay: false,
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

  Future<void> _changeStatus(String newStatus) async {
    if (_item == null) return;
    try {
      final updatedItem = _item!.copyWith(status: newStatus);
      await context.read<WatchProvider>().updateItem(updatedItem);
      await _loadItem();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _delete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Remove Item?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${_item!.title}" from your watchlist? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      backgroundColor: isDark ? const Color(0xFF0B0B0E) : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        // ── 🆕 BOUNCING PHYSICS ──
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            // ── 🆕 STRETCHY APP BAR ──
            stretch: true,
            backgroundColor: isDark ? const Color(0xFF0B0B0E) : const Color(0xFFF5F5F5),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              // ── 🆕 STRETCHY CINEMATIC BACKDROP ──
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // ── 🆕 LINKED HERO ANIMATION ──
                  Hero(
                    tag: 'hero_poster_${item.tmdbId}',
                    child: _buildPoster(item),
                  ),
                  DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.4, 1.0],
                            colors: [Colors.transparent, isDark ? const Color(0xFF0B0B0E) : const Color(0xFFF5F5F5)],
                          )
                      )
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1)),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8, runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusChip(status: item.status),
                      Text(item.category, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                      if (item.releaseYear.isNotEmpty) Text('·  ${item.releaseYear}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                      if ((item.hindiAvailable ?? 'No') == 'Yes')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text('HINDI', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 28),
                      const SizedBox(width: 6),
                      Text('${item.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text(' / 10', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (genreDisplay.isNotEmpty) ...[
                    Text(genreDisplay, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                  ],

                  if (_isFetchingExtras)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))))
                  else if (_ytController != null) ...[
                    const Text('OFFICIAL TRAILER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: YoutubePlayer(
                          controller: _ytController!,
                          showVideoProgressIndicator: true,
                          progressColors: const ProgressBarColors(playedColor: Color(0xFFFFD700), handleColor: Color(0xFFFFD700)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  if (showSeasonEp) ...[
                    Row(
                      children: [
                        Expanded(child: _StatCard(label: 'SEASONS', value: item.seasons?.toString() ?? '-')),
                        const SizedBox(width: 16),
                        Expanded(child: _StatCard(label: 'EPISODES', value: item.episodes?.toString() ?? '-')),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text('STORYLINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Text(
                      item.description.isNotEmpty ? item.description : 'No description available.',
                      style: TextStyle(fontSize: 15, height: 1.6, color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87)
                  ),
                  const SizedBox(height: 32),

                  if ((item.watchSource ?? '').isNotEmpty && item.watchSource != 'None') ...[
                    const Text('AVAILABLE ON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                    const SizedBox(height: 12),

                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          if (item.showLink == null || item.showLink!.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No show link found!'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
                            return;
                          }
                          final Uri url = Uri.parse(item.showLink!);
                          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link.')));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.watchSource == 'Watch Here')
                                const Icon(Icons.play_circle_fill, color: Color(0xFFFFD700), size: 28)
                              else
                                _platformLogo(item.watchSource!),
                              const SizedBox(width: 12),
                              Text(item.watchSource!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 12),
                              const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── 🆕 ACTION BUTTON GRADIENTS & SHADOWS ──
                  if (item.status == WatchStatus.planned) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              // ── 🆕 SIGNATURE GRADIENT ──
                              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                              borderRadius: BorderRadius.circular(24),
                              // ── 🆕 SOFT SHADOW ──
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: FilledButton.icon(
                                onPressed: () => _changeStatus(WatchStatus.watching),
                                icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                                label: const Text('Start Watching', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                )
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: FilledButton.icon(
                                onPressed: () => _changeStatus(WatchStatus.watched),
                                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                label: const Text('Mark Watched', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                )
                            )
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ] else if (item.status == WatchStatus.watching) ...[
                    Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF2E7D32).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4)
                            )
                          ],
                        ),
                        child: FilledButton.icon(
                            onPressed: () => _changeStatus(WatchStatus.watched),
                            icon: const Icon(Icons.check_circle_rounded, size: 22, color: Colors.white),
                            label: const Text('Mark as Finished', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            )
                        )
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_castMembers.isNotEmpty) ...[
                    const Text('TOP CAST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(), // Bouncing cast list
                        itemCount: _castMembers.length,
                        itemBuilder: (context, index) => _buildCastCard(_castMembers[index]),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  Row(
                    children: [
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditScreen(itemId: item.id))); _loadItem(); },
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFFFFD700), size: 18),
                              label: const Text('Edit', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.5), width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              )
                          )
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: _delete,
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              )
                          )
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
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
      if (item.posterPath!.startsWith('http')) return CachedNetworkImage(imageUrl: item.posterPath!, fit: BoxFit.cover, alignment: Alignment.topCenter);
      else return Image.file(File(item.posterPath!), fit: BoxFit.cover, alignment: Alignment.topCenter);
    }
    return Container(color: Colors.grey.shade900, child: const Icon(Icons.movie, size: 80, color: Colors.white24));
  }

  Widget _platformLogo(String platform) {
    const logoMap = {'MLWBD': 'assets/platform/logo/mlwbd.png', 'MovieBox': 'assets/platform/logo/moviebox.png', 'HiAnime': 'assets/platform/logo/hianime.png'};
    final path = logoMap[platform];
    if (path != null) return Image.asset(path, width: 28, height: 28, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.play_circle_fill, size: 28));
    return const Icon(Icons.play_circle_fill, size: 28);
  }

  Widget _buildCastCard(CastMember member) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12, width: 2),
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Colors.grey.shade800,
              backgroundImage: member.profilePath != null ? CachedNetworkImageProvider('https://image.tmdb.org/t/p/w200${member.profilePath}') : null,
              child: member.profilePath == null ? const Icon(Icons.person, size: 30, color: Colors.white54) : null,
            ),
          ),
          const SizedBox(height: 10),
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
    Color color = status == WatchStatus.watched ? Colors.green : status == WatchStatus.watching ? Colors.blueAccent : const Color(0xFFFFD700);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5))),
        child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5))
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))
            ]
        )
    );
  }
}