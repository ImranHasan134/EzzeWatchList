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

  Future<void> _editName() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.userMetadata?['full_name'] ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await _supabase.auth.updateUser(UserAttributes(data: {'full_name': newName}));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update name')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database fully synced!')));
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

    // Calculate quick stats
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
        // 🆕 Look how clean this is now!
        title: const CustomHeader(title: 'Profile', subtitle: 'Manage your account'),
      ),


      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile Card ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: user?.userMetadata?['avatar_url'] != null
                      ? NetworkImage(user!.userMetadata!['avatar_url'])
                      : null,
                  backgroundColor: const Color(0xFFFFD700).withOpacity(0.2),
                  child: user?.userMetadata?['avatar_url'] == null
                      ? const Icon(Icons.person, size: 35, color: Color(0xFFFFD700))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.userMetadata?['full_name'] ?? 'User',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _editName,
                  icon: const Icon(Icons.edit_rounded, color: Color(0xFFFFD700)),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Watch Stats ──────────────────────────────────────
          Row(
            children: [
              _buildStatCard('Movies', totalMovies.toString(), Icons.movie, isDark),
              const SizedBox(width: 12),
              _buildStatCard('Series', totalSeries.toString(), Icons.tv, isDark),
              const SizedBox(width: 12),
              _buildStatCard('Anime', totalAnime.toString(), Icons.animation, isDark),
            ],
          ),
          const SizedBox(height: 24),

          // ── Settings & Data ──────────────────────────────────
          const Text('APP SETTINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),

          _buildListTile(
            title: 'Dark Mode',
            icon: Icons.dark_mode,
            trailing: Switch(value: themeProvider.isDark, onChanged: (_) => themeProvider.toggle(), activeColor: const Color(0xFFFFD700)),
            isDark: isDark,
          ),
          _buildListTile(
            title: 'Refresh Database',
            subtitle: 'Force sync with cloud storage',
            icon: Icons.sync,
            onTap: _refreshDatabase,
            isDark: isDark,
          ),
          _buildListTile(
            title: 'Export as PDF',
            icon: Icons.picture_as_pdf,
            onTap: () => BackupService().exportData(context),
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // ── Logout Button ────────────────────────────────────
          // ── Logout Button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                setState(() => _isLoading = true);

                // 🆕 1. Wipe the local database clean so the next user starts fresh
                await DbHelper().clearAllItems();

                // 🆕 2. Clear the UI state in the background
                if (context.mounted) {
                  await context.read<WatchProvider>().loadAll();
                }

                // 3. Log out of Supabase and Google
                await AuthService.signOut();
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFFD700)),
            const SizedBox(height: 8),
            Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({required String title, String? subtitle, required IconData icon, Widget? trailing, VoidCallback? onTap, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFFD700)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}