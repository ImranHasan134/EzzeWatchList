// lib/data/network/tmdb_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class TmdbService {
  // ⚠️ REPLACE THIS WITH YOUR ACTUAL API KEY FROM TMDB
  static const String _apiKey = 'fcf557a1948957fbae1d97278970b79b';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  Future<List<Map<String, dynamic>>> searchContent(String query) async {
    if (query.trim().isEmpty) return [];

    // 'multi' search looks for both movies and TV shows at the same time
    final url = Uri.parse('$_baseUrl/search/multi?api_key=$_apiKey&query=${Uri.encodeComponent(query)}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        // Filter out actors/people, we only want movies and TV shows
        return results.where((item) => item['media_type'] == 'movie' || item['media_type'] == 'tv').map((item) {
          final isMovie = item['media_type'] == 'movie';
          final posterPath = item['poster_path'];

          return {
            'title': isMovie ? item['title'] : item['name'],
            'releaseYear': (isMovie ? item['release_date'] : item['first_air_date'])?.toString().split('-').first ?? '',
            'description': item['overview'] ?? '',
            // TMDB ratings are out of 10, perfect for our app
            'rating': (item['vote_average'] as num?)?.toDouble() ?? 0.0,
            // Construct the full image URL
            'posterPath': posterPath != null ? '$_imageBaseUrl$posterPath' : null,
            'category': isMovie ? 'Movie' : 'Web Series',
          };
        }).toList();
      }
    } catch (e) {
      print('TMDB Search Error: $e');
    }
    return [];
  }
}