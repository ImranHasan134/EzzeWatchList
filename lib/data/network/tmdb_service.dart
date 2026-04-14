// lib/data/network/tmdb_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class TmdbService {
  static const String _apiKey = 'fcf557a1948957fbae1d97278970b79b';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  // 🆕 TMDB ID to Genre String Map
  static const Map<int, String> _genreMap = {
    28: 'Action', 12: 'Adventure', 16: 'Animation', 35: 'Comedy', 80: 'Crime',
    99: 'Documentary', 18: 'Drama', 10751: 'Family', 14: 'Fantasy', 36: 'History',
    27: 'Horror', 10402: 'Music', 9648: 'Mystery', 10749: 'Romance', 878: 'Sci-Fi',
    10770: 'TV Movie', 53: 'Thriller', 10752: 'War', 37: 'Western',
    10759: 'Action & Adventure', 10762: 'Kids', 10763: 'News', 10764: 'Reality',
    10765: 'Sci-Fi & Fantasy', 10766: 'Soap', 10767: 'Talk', 10768: 'War & Politics'
  };

  Future<List<Map<String, dynamic>>> searchContent(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse('$_baseUrl/search/multi?api_key=$_apiKey&query=${Uri.encodeComponent(query)}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        return results.where((item) => item['media_type'] == 'movie' || item['media_type'] == 'tv').map((item) {
          final isMovie = item['media_type'] == 'movie';
          final posterPath = item['poster_path'];

          // 🆕 Translate the IDs into words
          final List<dynamic> genreIds = item['genre_ids'] ?? [];
          final List<String> genres = genreIds
              .map((id) => _genreMap[id])
              .whereType<String>()
              .toList();

          return {
            'title': isMovie ? item['title'] : item['name'],
            'releaseYear': (isMovie ? item['release_date'] : item['first_air_date'])?.toString().split('-').first ?? '',
            'description': item['overview'] ?? '',
            'rating': (item['vote_average'] as num?)?.toDouble() ?? 0.0,
            'posterPath': posterPath != null ? '$_imageBaseUrl$posterPath' : null,
            'category': isMovie ? 'Movie' : 'Web Series',
            'genres': genres,
            'id': item['id'],
          };
        }).toList();
      }
    } catch (e) {
      print('TMDB Search Error: $e');
    }
    return [];
  }
  // 🆕 New method to fetch exact season and episode counts
  Future<Map<String, int>> getTvSeasonEpisode(int tvId) async {
    final url = Uri.parse('$_baseUrl/tv/$tvId?api_key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'seasons': data['number_of_seasons'] as int? ?? 0,
          'episodes': data['number_of_episodes'] as int? ?? 0,
        };
      }
    } catch (e) {
      print('TMDB TV Details Error: $e');
    }
    return {};
  }
}