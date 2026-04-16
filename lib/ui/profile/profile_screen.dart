// lib/ui/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../data/network/auth_service.dart';
import '../../data/network/sync_service.dart';
import '../../utils/backup_service.dart';
import '../../utils/theme_provider.dart';
import '../../data/database/db_helper.dart';
import '../../widgets/custom_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // ── 🆕 PREMIUM GRADIENT ──
  final goldGradient = const LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── EXISTING LOGIC PRESERVED ────────────────────────────────
  Future<void> _editName() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.userMetadata?['full_name'] ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update Identity', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(gradient: goldGradient, borderRadius: BorderRadius.circular(12)),
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                        onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
                        child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await _supabase.auth.updateUser(UserAttributes(data: {'full_name': newName}));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshDatabase() async {
    setState(() => _isLoading = true);
    try {
      await SyncService.syncCloudToLocal();
      if (mounted) await context.read<WatchProvider>().loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Library fully synced!'), behavior: SnackBarBehavior.floating)
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final items = context.watch<WatchProvider>().items;
    final user = _supabase.auth.currentUser;

    final totalMovies = items.where((i) => i.category == Category.movie).length;
    final totalSeries = items.where((i) => i.category == Category.webSeries).length;
    final totalAnime = items.where((i) => i.category.contains('Anime')).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        centerTitle: false,
        title: const CustomHeader(title: 'Profile', subtitle: 'Manage your library'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // ── 🆕 PREMIUM PROFILE CARD ────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(gradient: goldGradient, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: isDark ? const Color(0xFF0E0E0E) : Colors.grey.shade200,
                        backgroundImage: user?.userMetadata?['avatar_url'] != null
                            ? NetworkImage(user!.userMetadata!['avatar_url'])
                            : null,
                        child: user?.userMetadata?['avatar_url'] == null
                            ? const Icon(Icons.person_rounded, size: 45, color: Color(0xFFFFD700))
                            : null,
                      ),
                    ),
                    GestureDetector(
                      onTap: _editName,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFFFD700),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.userMetadata?['full_name'] ?? 'Ezze User',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 🆕 STATS GRID ──────────────────────────────────
          Row(
            children: [
              _buildStatCard('Movies', totalMovies.toString(), Icons.movie_filter_rounded, isDark),
              const SizedBox(width: 12),
              _buildStatCard('Series', totalSeries.toString(), Icons.tv_rounded, isDark),
              const SizedBox(width: 12),
              _buildStatCard('Anime', totalAnime.toString(), Icons.animation_rounded, isDark),
            ],
          ),
          const SizedBox(height: 32),

          const Text('PREFERENCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 12),

          _buildListTile(
            title: 'Visual Theme',
            subtitle: isDark ? 'Dark Mode Active' : 'Light Mode Active',
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            trailing: Switch(
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggle(),
              activeColor: const Color(0xFFFFD700),
            ),
            isDark: isDark,
          ),

          const SizedBox(height: 24),
          const Text('DATA & SYNC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 12),

          _buildListTile(
            title: 'Refresh Library',
            subtitle: 'Sync local database with cloud',
            icon: Icons.sync_rounded,
            onTap: _refreshDatabase,
            isDark: isDark,
          ),
          _buildListTile(
            title: 'Export Collection',
            subtitle: 'Download your watchlist as PDF',
            icon: Icons.picture_as_pdf_rounded,
            onTap: () => BackupService().exportData(context),
            isDark: isDark,
          ),

          const SizedBox(height: 40),

          // ── 🆕 PREMIUM LOGOUT ──────────────────────────────
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                setState(() => _isLoading = true);
                await DbHelper().clearAllItems();
                if (context.mounted) {
                  await context.read<WatchProvider>().loadAll();
                }
                await AuthService.signOut();
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.redAccent.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => goldGradient.createShader(bounds),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFFFD700), size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}