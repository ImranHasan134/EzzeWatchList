// lib/ui/detail/global_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../data/network/tmdb_service.dart';

class GlobalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const GlobalDetailScreen({super.key, required this.item});

  @override
  State<GlobalDetailScreen> createState() => _GlobalDetailScreenState();
}

class _GlobalDetailScreenState extends State<GlobalDetailScreen> {
  final TmdbService _tmdbService = TmdbService();

  bool _isLoading = true;
  YoutubePlayerController? _ytController;
  List<CastMember> _castMembers = [];
  List<Map<String, dynamic>> _similarContent = [];
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

    final results = await Future.wait([
      _tmdbService.getTrailerUrl(tmdbId, isMovie),
      _tmdbService.getCast(tmdbId, isMovie),
      if (!isMovie) _tmdbService.getTvSeasonEpisode(tmdbId) else Future.value(null),
      _tmdbService.getSimilar(tmdbId, isMovie),
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
        _similarContent = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  Future<void> _addToWatchlist() async {
    final newItem = WatchItem(
      title: widget.item['title'] ?? 'Unknown',
      category: widget.item['category'] ?? 'Movie',
      genres: (widget.item['genres'] as List<String>).join(', '),
      releaseYear: widget.item['releaseYear'] ?? '',
      description: widget.item['description'] ?? '',
      rating: (widget.item['rating'] as num?)?.toDouble() ?? 0.0,
      status: WatchStatus.planned,
      posterPath: widget.item['posterPath'],
      seasons: _seasons,
      episodes: _episodes,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      hindiAvailable: 'No',
      watchSource: '',
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
    final bgColor = isDark ? const Color(0xFF0B0B0E) : const Color(0xFFF5F5F5);

    final provider = context.watch<WatchProvider>();
    final isAlreadySaved = provider.watched.any((db) => db.tmdbId == item['tmdbId']) ||
        provider.watching.any((db) => db.tmdbId == item['tmdbId']) ||
        provider.planned.any((db) => db.tmdbId == item['tmdbId']);

    final backdropImg = item['backdropPath'] ?? item['posterPath'];
    final genres = item['genres'] as List<String>? ?? [];

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── BACKDROP APP BAR ──
          SliverAppBar(
            expandedHeight: 220, // 🆕 Slightly shorter for better balance
            pinned: true,
            backgroundColor: bgColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (backdropImg != null)
                    CachedNetworkImage(
                      imageUrl: item['backdropPath'] ?? item['posterPath'], // 🆕 This will now automatically pull the 1280px version!
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, bgColor],
                        stops: const [0.4, 1.0], // 🆕 Smoother fade
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── CONTENT ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8), // 🆕 Clean spacing, NO more negative offset

                  // ── CLEAN POSTER & TITLE SECTION ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The Poster
                      Container(
                        width: 115, // 🆕 Standardized poster width
                        height: 170, // 🆕 Standardized poster height
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item['posterPath'] != null
                              ? CachedNetworkImage(imageUrl: item['posterPath'], fit: BoxFit.cover)
                              : Container(color: Colors.grey.shade900, child: const Icon(Icons.movie, color: Colors.white54)),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Title & Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            // Type Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B4DFF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (item['category'] ?? 'Movie').toUpperCase(),
                                style: const TextStyle(color: Color(0xFFA694FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Title
                            Text(item['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)),
                            const SizedBox(height: 8),

                            // Rating & Year Row
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  (item['rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  item['releaseYear'] ?? '',
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Genre Pills
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: genres.take(3).map((genre) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(genre, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87)),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── BIG YELLOW ACTION BUTTON ──
                  Container(
                    width: double.infinity, // Optional: makes it stretch full width
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      // 1. If saved, use solid green. If not, color is null.
                      color: isAlreadySaved ? Colors.green : null,
                      // 2. If saved, gradient is null. If not, use the golden gradient.
                      gradient: isAlreadySaved
                          ? null
                          : const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                    ),
                    child: FilledButton.icon(
                      // Your onPressed and icon/label go here
                      onPressed: isAlreadySaved ? null : _addToWatchlist,
                      icon: Icon(isAlreadySaved ? Icons.check : Icons.add, color: Colors.black),
                      label: Text(
                        isAlreadySaved ? 'In Your Watchlist' : 'Add to Watchlist',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        // 3. Make the button itself transparent so the Container shows through!
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent, // Removes weird double-shadows
                        disabledBackgroundColor: Colors.transparent, // Keeps it clean when disabled
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── OVERVIEW ──
                  // Find the Overview section inside the build method
                  const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    item['description']?.isNotEmpty == true ? item['description'] : 'No description available.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── TRAILER ──
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFFFFD700))))
                  else if (_ytController != null) ...[
                    const Text('Trailer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: YoutubePlayer(controller: _ytController!, showVideoProgressIndicator: true, progressColors: const ProgressBarColors(playedColor: Color(0xFFFFD700), handleColor: Color(0xFFFFD700))),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── CAST ──
                  if (_castMembers.isNotEmpty) ...[
                    const Text('Cast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _castMembers.length,
                        itemBuilder: (context, index) {
                          final member = _castMembers[index];
                          return Container(
                            width: 70,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey.shade800,
                                  backgroundImage: member.profilePath != null ? CachedNetworkImageProvider('https://image.tmdb.org/t/p/w200${member.profilePath}') : null,
                                  child: member.profilePath == null ? const Icon(Icons.person, size: 28, color: Colors.white54) : null,
                                ),
                                const SizedBox(height: 8),
                                Text(member.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.1)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── SIMILAR CONTENT ──
                  if (_similarContent.isNotEmpty) ...[
                    const Text('More Like This', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _similarContent.length,
                        itemBuilder: (context, index) {
                          final similarItem = _similarContent[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalDetailScreen(item: similarItem)));
                            },
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: similarItem['posterPath'] != null
                                          ? CachedNetworkImage(imageUrl: similarItem['posterPath'], fit: BoxFit.cover, width: double.infinity)
                                          : Container(color: Colors.grey.shade900, child: const Icon(Icons.movie, color: Colors.white24)),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    similarItem['title'] ?? 'Unknown',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}