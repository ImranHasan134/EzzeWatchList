// lib/widgets/poster_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/models/watch_item.dart';

class PosterCard extends StatelessWidget {
  final WatchItem item;
  final VoidCallback onTap;
  final String heroTag; // ── 🆕 CRITICAL: Enforces flawless transitions ──

  const PosterCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.black12;

    // ── 🆕 PREMIUM RIPPLE EFFECT ──
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Poster image
              Expanded(
                // ── 🆕 HERO WIDGET WRAPPER ──
                child: Hero(
                  tag: heroTag,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildPoster(),
                      // Rating badge
                      if (item.rating > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  item.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: isDark ? Colors.white70 : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    if (item.posterPath != null && item.posterPath!.isNotEmpty) {
      if (item.posterPath!.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: item.posterPath!,
          fit: BoxFit.cover,
          // ── 🆕 PREMIUM IMAGE FADE ──
          fadeInDuration: const Duration(milliseconds: 300),
          placeholder: (context, url) => Container(color: Colors.black12),
          errorWidget: (context, url, error) => _placeholder(),
        );
      } else {
        return Image.file(
          File(item.posterPath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade800.withOpacity(0.15),
      child: const Icon(Icons.movie_filter_rounded, size: 40, color: Colors.grey),
    );
  }
}