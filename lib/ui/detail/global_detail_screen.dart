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
            flags: const YoutubePlayerFlags(autoPlay: false, forceHD: true, mute: false),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final isAlreadySaved = provider.items.any((db) => db.tmdbId == item['tmdbId']);

    final backdropImg = item['backdropPath'] ?? item['posterPath'];
    final genres = item['genres'] as List<String>? ?? [];

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(), // 🆕 Tactile scrolling
        slivers: [
          // ── CINEMATIC BACKDROP ──
          SliverAppBar(
            expandedHeight: 300, // 🆕 Taller for more drama
            pinned: true,
            stretch: true, // 🆕 Image grows when pulled down
            backgroundColor: bgColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (backdropImg != null)
                    CachedNetworkImage(
                      imageUrl: backdropImg,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87, Colors.black],
                        stops: [0.3, 0.85, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── POSTER & TITLE SECTION ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 🆕 HERO POSTER ──
                      // Ensure this tag matches the categoryType logic from Home/SeeAll
                      Hero(
                        tag: 'hero_poster_${item['tmdbId']}',
                        child: Container(
                          width: 120,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: item['posterPath'] != null
                                ? CachedNetworkImage(imageUrl: item['posterPath'], fit: BoxFit.cover)
                                : Container(color: Colors.grey.shade900, child: const Icon(Icons.movie, color: Colors.white54)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                              ),
                              child: Text(
                                (item['category'] ?? 'Movie').toUpperCase(),
                                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(item['title'] ?? '', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.15)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  (item['rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  item['releaseYear'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── GENRE CHIPS ──
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genres.map((genre) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(genre, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                    )).toList(),
                  ),

                  const SizedBox(height: 32),

                  // ── ACTION BUTTON ──
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: isAlreadySaved
                          ? null
                          : const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                      color: isAlreadySaved ? Colors.green.withOpacity(0.2) : null,
                      border: isAlreadySaved ? Border.all(color: Colors.green, width: 1.5) : null,
                    ),
                    child: FilledButton.icon(
                      onPressed: isAlreadySaved ? null : _addToWatchlist,
                      icon: Icon(isAlreadySaved ? Icons.check_circle_outline : Icons.add_rounded, color: isAlreadySaved ? Colors.green : Colors.black),
                      label: Text(
                        isAlreadySaved ? 'Saved to Watchlist' : 'Add to Watchlist',
                        style: TextStyle(color: isAlreadySaved ? Colors.green : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── DESCRIPTION ──
                  const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    item['description']?.isNotEmpty == true ? item['description'] : 'No storyline provided.',
                    style: TextStyle(fontSize: 15, height: 1.6, color: isDark ? Colors.white70 : Colors.black87, letterSpacing: 0.2),
                  ),

                  const SizedBox(height: 40),

                  // ── TRAILER ──
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFFFFD700))))
                  else if (_ytController != null) ...[
                    const Text('Official Trailer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: YoutubePlayer(
                        controller: _ytController!,
                        showVideoProgressIndicator: true,
                        progressColors: const ProgressBarColors(playedColor: Color(0xFFFFD700), handleColor: Color(0xFFFFA500)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],

                  // ── CAST SECTION ──
                  if (_castMembers.isNotEmpty) ...[
                    const Text('Top Cast', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _castMembers.length,
                        itemBuilder: (context, index) {
                          final member = _castMembers[index];
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 20),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white10, width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 35,
                                    backgroundColor: Colors.grey.shade900,
                                    backgroundImage: member.profilePath != null
                                        ? CachedNetworkImageProvider('https://image.tmdb.org/t/p/w200${member.profilePath}')
                                        : null,
                                    child: member.profilePath == null ? const Icon(Icons.person, size: 30, color: Colors.white24) : null,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                    member.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2)
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],

                  // ── SIMILAR CONTENT ──
                  if (_similarContent.isNotEmpty) ...[
                    const Text('More Like This', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _similarContent.length,
                        itemBuilder: (context, index) {
                          final similarItem = _similarContent[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalDetailScreen(item: similarItem)));
                            },
                            child: Container(
                              width: 110,
                              margin: const EdgeInsets.only(right: 14),
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
                                  const SizedBox(height: 8),
                                  Text(
                                    similarItem['title'] ?? 'N/A',
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

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}