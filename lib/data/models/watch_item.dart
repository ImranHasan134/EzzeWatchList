import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class WatchItem {
  final int? id;
  final String title;
  final String category;
  final String genres;
  final String releaseYear;
  final String description;
  final double rating;
  final String status;
  final String? posterPath;
  final int? seasons;
  final int? episodes;
  final int createdAt;
  final String? hindiAvailable; // "Yes" / "No"
  final String? watchSource;    // MLWBD / MovieBox / HiAnime

  const WatchItem({
    this.id,
    required this.title,
    required this.category,
    required this.genres,
    required this.releaseYear,
    required this.description,
    required this.rating,
    required this.status,
    this.posterPath,
    this.seasons,
    this.episodes,
    required this.createdAt,
    this.hindiAvailable,
    this.watchSource,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category': category,
      'genres': genres,
      'releaseYear': releaseYear,
      'description': description,
      'rating': rating,
      'status': status,
      'posterPath': posterPath,
      'seasons': seasons,
      'episodes': episodes,
      'createdAt': createdAt,
      'hindiAvailable': hindiAvailable ?? 'No',
      'watchSource': watchSource ?? '',
    };
  }

  factory WatchItem.fromMap(Map<String, dynamic> map) {
    return WatchItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      genres: map['genres'] as String,
      releaseYear: map['releaseYear'] as String,
      description: map['description'] as String,
      rating: (map['rating'] as num).toDouble(),
      status: map['status'] as String,
      posterPath: map['posterPath'] as String?,
      seasons: map['seasons'] as int?,
      episodes: map['episodes'] as int?,
      createdAt: map['createdAt'] as int,
      hindiAvailable: map['hindiAvailable'] as String?,
      watchSource: map['watchSource'] as String?,
    );
  }

  WatchItem copyWith({
    int? id,
    String? title,
    String? category,
    String? genres,
    String? releaseYear,
    String? description,
    double? rating,
    String? status,
    String? posterPath,
    int? seasons,
    int? episodes,
    int? createdAt,
    String? hindiAvailable,
    String? watchSource,
  }) {
    return WatchItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      genres: genres ?? this.genres,
      releaseYear: releaseYear ?? this.releaseYear,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      posterPath: posterPath ?? this.posterPath,
      seasons: seasons ?? this.seasons,
      episodes: episodes ?? this.episodes,
      createdAt: createdAt ?? this.createdAt,
      hindiAvailable: hindiAvailable ?? this.hindiAvailable,
      watchSource: watchSource ?? this.watchSource,
    );
  }
}

// ── Status / Category / Genre constants ─────────────────────────────
class WatchStatus {
  static const String watched  = 'Watched';
  static const String watching = 'Watching';
  static const String planned  = 'Planned';
  static const List<String> all = [watched, watching, planned];
}

class Category {
  static const String movie       = 'Movie';
  static const String webSeries   = 'Web Series';
  static const String animeMovie  = 'Anime Movie';
  static const String animeSeries = 'Anime Series';
  static const List<String> all = [movie, webSeries, animeMovie, animeSeries];
}

class Genre {
  // A comprehensive master list of Movie, TV Series, and Anime genres
  static List<String> all = [
    'Action',
    'Action & Adventure',
    'Adventure',
    'Animation',
    'Avant Garde',
    'Award Winning',
    'Boys Love',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Ecchi',
    'Family',
    'Fantasy',
    'Girls Love',
    'Gourmet',
    'History',
    'Horror',
    'Isekai',
    'Kids',
    'Magic',
    'Martial Arts',
    'Mecha',
    'Music',
    'Mystery',
    'News',
    'Psychological',
    'Reality',
    'Romance',
    'Sci-Fi',
    'Sci-Fi & Fantasy',
    'Slice of Life',
    'Soap',
    'Sports',
    'Supernatural',
    'Suspense',
    'Talk',
    'Thriller',
    'TV Movie',
    'War',
    'War & Politics',
    'Western',
  ];
}
