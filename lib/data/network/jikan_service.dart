// lib/data/network/jikan_service.dart

import 'dart:convert';
import 'dart:async'; // ── 🆕 REQUIRED FOR TIMEOUTS ──
import 'package:http/http.dart' as http;

class JikanService {
  static const String _baseUrl = 'https://api.jikan.moe/v4';

  Future<List<Map<String, dynamic>>> searchAnime(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse('$_baseUrl/anime?q=${Uri.encodeComponent(query)}&limit=5');

    try {
      // ── 🆕 FIXED: 10 SECOND TIMEOUT ──
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['data'] ?? [];

        return results.map((item) {
          final List<dynamic> rawGenres = item['genres'] ?? [];
          final List<String> genres = rawGenres.map((g) => g['name'].toString()).toList();
          final isMovie = item['type'] == 'Movie';

          return {
            'title': item['title_english'] ?? item['title'] ?? 'Unknown',
            'releaseYear': item['year']?.toString() ?? '',
            'description': item['synopsis'] ?? '',
            'rating': (item['score'] as num?)?.toDouble() ?? 0.0,
            'posterPath': item['images']?['jpg']?['large_image_url'] ?? item['images']?['jpg']?['image_url'],
            'category': isMovie ? 'Anime Movie' : 'Anime Series',
            'episodes': item['episodes'],
            'genres': genres,
          };
        }).toList();
      }
    } catch (e) {
      print('Jikan Search Error: $e');
    }
    return [];
  }
}