// lib/ui/stats/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/database/watch_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
    isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5);
    final surfaceColor =
    isDark ? const Color(0xFF141414) : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: surfaceColor,
          title: Row(
            children: [
              Container(
                width: 3,
                height: 22,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF1A1A1A),
                      letterSpacing: 0.3,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ).createShader(bounds),
                    child: const Text(
                      'Your watching overview',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // ── Section label ───────────────────────────────────────────
              Text(
                'OVERVIEW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 10),

              // ── Row 1: Total + Watched ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _GoldStatCard(
                      icon: Icons.movie_filter_rounded,
                      value: provider.totalCount.toString(),
                      label: 'Total',
                      isDark: isDark,
                      isGold: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GoldStatCard(
                      icon: Icons.check_circle_rounded,
                      value: provider.watchedCount.toString(),
                      label: 'Watched',
                      isDark: isDark,
                      isGold: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Row 2: Avg Rating + Top Genre ───────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _GoldStatCard(
                      icon: Icons.star_rounded,
                      value: provider.averageRating != null
                          ? provider.averageRating!.toStringAsFixed(1)
                          : 'N/A',
                      label: 'Avg Rating',
                      isDark: isDark,
                      isGold: true,
                      smallValue: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GoldStatCard(
                      icon: Icons.emoji_events_rounded,
                      value: provider.topGenre ?? 'N/A',
                      label: 'Top Genre',
                      isDark: isDark,
                      isGold: false,
                      smallValue: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Progress section ────────────────────────────────────────
              Text(
                'PROGRESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 10),

              _ProgressCard(
                isDark: isDark,
                watched: provider.watchedCount,
                watching: provider.totalCount -
                    provider.watchedCount -
                    (provider.totalCount -
                        provider.watchedCount -
                        _plannedCount(provider)),
                planned: _plannedCount(provider),
                total: provider.totalCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _plannedCount(WatchProvider provider) {
    return provider.planned.length;
  }
}

// ── Gold Stat Card ────────────────────────────────────────────────────────────

class _GoldStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;
  final bool isGold;
  final bool smallValue;

  const _GoldStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
    required this.isGold,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGold
              ? const Color(0xFFFFD700).withOpacity(0.4)
              : isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.06),
          width: isGold ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isGold
                ? const Color(0xFFFFD700).withOpacity(0.1)
                : Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with gold or neutral background
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: isGold
                  ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              )
                  : null,
              color: isGold
                  ? null
                  : isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isGold
                  ? const Color(0xFF1A1A1A)
                  : isDark
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: smallValue ? 20 : 30,
              fontWeight: FontWeight.w800,
              color: isGold
                  ? const Color(0xFFFFD700)
                  : isDark
                  ? Colors.white
                  : const Color(0xFF1A1A1A),
              height: 1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Card ─────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final bool isDark;
  final int watched;
  final int watching;
  final int planned;
  final int total;

  const _ProgressCard({
    required this.isDark,
    required this.watched,
    required this.watching,
    required this.planned,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total == 0 ? 1 : total;
    final watchedRatio = watched / safeTotal;
    final watchingRatio = watching / safeTotal;
    final plannedRatio = planned / safeTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stacked progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (watchedRatio > 0)
                    Expanded(
                      flex: (watchedRatio * 100).round(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                        ),
                      ),
                    ),
                  if (watchingRatio > 0)
                    Expanded(
                      flex: (watchingRatio * 100).round(),
                      child: Container(color: const Color(0xFF4FC3F7)),
                    ),
                  if (plannedRatio > 0)
                    Expanded(
                      flex: (plannedRatio * 100).round(),
                      child: Container(
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.08),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend
          Row(
            children: [
              _LegendDot(
                color: const Color(0xFFFFD700),
                label: 'Watched',
                count: watched,
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _LegendDot(
                color: const Color(0xFF4FC3F7),
                label: 'Watching',
                count: watching,
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _LegendDot(
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.15),
                label: 'Planned',
                count: planned,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final bool isDark;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}