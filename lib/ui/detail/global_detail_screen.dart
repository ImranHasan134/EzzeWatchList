// lib/ui/detail/global_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../data/network/tmdb_service.dart';

class GlobalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item; // Receives data directly from Home/Explore/Search

  const GlobalDetailScreen({super.key, required this.item});

  @override
  State<GlobalDetailScreen> createState() => _GlobalDetailScreenState();
}

class _GlobalDetailScreenState extends State<GlobalDetailScreen> {
  final TmdbService _tmdbService = TmdbService();

  bool _isLoading = true;
  YoutubePlayerController? _ytController;
  List<CastMember> _castMembers = [];
  int? _seasons;
  int? _episodes;

  @override
  void initState() {
    super.initState();
    _fetchExtraDetails();
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  Future<void> _fetchExtraDetails() async {
    final tmdbId = widget.item['tmdbId'];
    if (tmdbId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final isMovie = widget.item['category'] == 'Movie' || widget.item['category'] == 'Anime Movie';

    // Fetch Trailer, Cast, and (if it's a TV show) Season details all at once!
    final results = await Future.wait([
      _tmdbService.getTrailerUrl(tmdbId, isMovie),
      _tmdbService.getCast(tmdbId, isMovie),
      if (!isMovie) _tmdbService.getTvSeasonEpisode(tmdbId) else Future.value(null),
    ]);

    if (mounted) {
      final trailerUrl = results[0] as String?;

      if (trailerUrl != null) {
        final videoId = YoutubePlayer.convertUrlToId(trailerUrl);
        if (videoId != null) {
          _ytController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(autoPlay: false, forceHD: true),
          );
        }
      }

      setState(() {
        _castMembers = results[1] as List<CastMember>;
        if (!isMovie && results[2] != null) {
          final tvData = results[2] as Map<String, int>;
          _seasons = tvData['seasons'];
          _episodes = tvData['episodes'];
        }
        _isLoading = false;
      });
    }
  }

  // ── 1-CLICK SAVE TO WATCHLIST ──
  Future<void> _addToWatchlist() async {
    final newItem = WatchItem(
      title: widget.item['title'] ?? 'Unknown',
      category: widget.item['category'] ?? 'Movie',
      genres: (widget.item['genres'] as List<String>).join(', '),
      releaseYear: widget.item['releaseYear'] ?? '',
      description: widget.item['description'] ?? '',
      rating: (widget.item['rating'] as num?)?.toDouble() ?? 0.0,
      status: WatchStatus.planned, // Defaults to planned!
      posterPath: widget.item['posterPath'],
      seasons: _seasons,
      episodes: _episodes,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      hindiAvailable: 'No',
      watchSource: '', // Can be edited later
      tmdbId: widget.item['tmdbId'],
    );

    await context.read<WatchProvider>().addItem(newItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newItem.title} added to Watchlist!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if this movie is already in your local SQLite database
    final provider = context.watch<WatchProvider>();
    final isAlreadySaved = provider.watched.any((db) => db.tmdbId == item['tmdbId']) ||
        provider.watching.any((db) => db.tmdbId == item['tmdbId']) ||
        provider.planned.any((db) => db.tmdbId == item['tmdbId']);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (item['backdropPath'] != null || item['posterPath'] != null)
                    CachedNetworkImage(
                      imageUrl: item['backdropPath'] ?? item['posterPath'],
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5)],
                        stops: const [0.5, 1.0],
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
                  Text(item['title'] ?? '', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1)),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8, runSpacing: 4,
                    children: [
                      Text(item['category'] ?? '', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                      if ((item['releaseYear'] ?? '').isNotEmpty) Text('· ${item['releaseYear']}', style: const TextStyle(color: Colors.grey)),
                      if (item['rating'] != null) Text('· ⭐ ${(item['rating'] as num).toStringAsFixed(1)}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── ADD TO WATCHLIST BUTTON ──
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isAlreadySaved ? null : _addToWatchlist,
                      icon: Icon(isAlreadySaved ? Icons.check : Icons.add, color: isAlreadySaved ? Colors.white : Colors.black),
                      label: Text(
                        isAlreadySaved ? 'In Your Watchlist' : 'Add to Watchlist',
                        style: TextStyle(color: isAlreadySaved ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isAlreadySaved ? Colors.green : const Color(0xFFFFD700),
                        disabledBackgroundColor: Colors.green.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── INLINE YOUTUBE PLAYER ──
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFFFFD700))))
                  else if (_ytController != null) ...[
                    const Text('TRAILER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: YoutubePlayer(controller: _ytController!, showVideoProgressIndicator: true, progressColors: const ProgressBarColors(playedColor: Color(0xFFFFD700), handleColor: Color(0xFFFFD700))),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text('OVERVIEW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(item['description']?.isNotEmpty == true ? item['description'] : 'No description available.', style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white70)),
                  const SizedBox(height: 24),

                  if (_castMembers.isNotEmpty) ...[
                    const Text('CAST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _castMembers.length,
                        itemBuilder: (context, index) {
                          final member = _castMembers[index];
                          return Container(
                            width: 75,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 32, backgroundColor: Colors.grey.shade800,
                                  backgroundImage: member.profilePath != null ? CachedNetworkImageProvider('https://image.tmdb.org/t/p/w200${member.profilePath}') : null,
                                  child: member.profilePath == null ? const Icon(Icons.person, size: 30, color: Colors.white54) : null,
                                ),
                                const SizedBox(height: 8),
                                Text(member.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, height: 1.1)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}