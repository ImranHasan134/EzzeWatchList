// lib/ui/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🆕 Added
import '../../data/database/watch_provider.dart';
import '../../utils/backup_service.dart';
import '../../utils/theme_provider.dart';
import '../../data/network/auth_service.dart';
import '../../data/network/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAuthLoading = false;

  // ── Auth Handlers ──────────────────────────────────────────
  Future<void> _handleSignIn() async {
    setState(() => _isAuthLoading = true);
    try {
      await AuthService.signInWithGoogle();

      // 🆕 Run the cloud sync immediately after logging in
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Syncing data from cloud...'))
        );
      }
      await SyncService.syncCloudToLocal();

      if (mounted) {
        // Reload the UI with the fresh data
        await context.read<WatchProvider>().loadAll();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isAuthLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isAuthLoading = true);
    await AuthService.signOut();
    if (mounted) {
      setState(() => _isAuthLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final backup = BackupService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5);
    final surfaceColor = isDark ? const Color(0xFF141414) : Colors.white;

    // 🆕 Check if user is currently logged in
    final user = Supabase.instance.client.auth.currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ).createShader(bounds),
                    child: const Text(
                      'Customize your experience',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Dark Mode ─────────────────────────────────────
            _buildSettingsContainer(
              isDark: isDark,
              child: SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.dark_mode_rounded, color: Color(0xFFFFD700)),
                ),
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle dark / light theme'),
                value: themeProvider.isDark,
                onChanged: (_) => themeProvider.toggle(),
              ),
            ),
            const SizedBox(height: 12),

            // ── Cloud Sync (UPDATED) ──────────────────────────
            _buildSettingsContainer(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CLOUD ACCOUNT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 6),

                  // If logged out: Show sign-in button
                  if (user == null) ...[
                    Text(
                      'Sign in to sync your watchlist across devices.',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                    ),
                    const SizedBox(height: 12),
                    _isAuthLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                        : OutlinedButton.icon(
                      onPressed: _handleSignIn,
                      icon: Icon(Icons.g_mobiledata_rounded, size: 30, color: isDark ? Colors.white : Colors.black),
                      label: Text('Sign in with Google', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        side: BorderSide(color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]
                  // If logged in: Show profile info
                  else ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(user.userMetadata?['avatar_url'] ?? ''),
                        backgroundColor: Colors.grey.shade300,
                      ),
                      title: Text(
                        user.userMetadata?['full_name'] ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        user.email ?? '',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                      ),
                      trailing: _isAuthLoading
                          ? const CircularProgressIndicator()
                          : IconButton(
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        onPressed: _handleSignOut,
                        tooltip: 'Sign Out',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Data Backup ───────────────────────────────────
            _buildSettingsContainer(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DATA BACKUP',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Export your watchlist as a PDF or restore from backup.',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FilledButton.icon(
                        onPressed: () async => await backup.exportData(context),
                        icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF1A1A1A)),
                        label: const Text('Export Data as PDF', style: TextStyle(color: Color(0xFF1A1A1A))),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await backup.importData(context);
                        if (context.mounted) await context.read<WatchProvider>().loadAll();
                      },
                      icon: Icon(Icons.download, color: isDark ? Colors.white70 : Colors.black54),
                      label: Text('Import Data', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text('EzzeWatchList v1.0', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper method to keep UI clean
  Widget _buildSettingsContainer({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}