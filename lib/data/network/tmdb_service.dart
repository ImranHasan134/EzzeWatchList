// lib/data/network/tmdb_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CastMember {
  final String name;
  final String character;
  final String? profilePath;
  final int? tmdbId;

  CastMember({required this.name, required this.character, this.profilePath, this.tmdbId});

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      name: json['name'],
      character: json['character'],
      profilePath: json['profile_path'],
      tmdbId: json['id'],
    );
  }
}

class TmdbService {
  static final String _apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

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
            'tmdbId': item['id'], // 🆕 Add this line to save the TMDB ID!
          };
        }).toList();
      }
    } catch (e) {
      print('TMDB Search Error: $e');
    }
    return [];
  }

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

  // 🆕 New methods for trailer and cast
  Future<String?> getTrailerUrl(int tmdbId, bool isMovie) async {
    final type = isMovie ? 'movie' : 'tv';
    final url = Uri.parse('$_baseUrl/$type/$tmdbId/videos?api_key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        final trailer = results.firstWhere((v) => v['type'] == 'Trailer' && v['site'] == 'YouTube', orElse: () => null);
        if (trailer != null) {
          return 'https://www.youtube.com/watch?v=${trailer['key']}';
        }
      }
    } catch (e) { print('TMDB Trailer Error: $e'); }
    return null;
  }

  Future<List<CastMember>> getCast(int tmdbId, bool isMovie) async {
    final type = isMovie ? 'movie' : 'tv';
    final url = Uri.parse('$_baseUrl/$type/$tmdbId/credits?api_key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List cast = data['cast'] ?? [];
        return cast.take(10).map((c) => CastMember.fromJson(c)).toList(); // Get top 10 cast members
      }
    } catch (e) { print('TMDB Cast Error: $e'); }
    return [];
  }
}