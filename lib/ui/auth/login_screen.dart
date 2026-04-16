// lib/ui/auth/login_screen.dart

import 'package:flutter/material.dart';
import '../../data/network/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submitEmailAuth() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await AuthService.signInWithEmail(email, password);
      } else {
        final name = _nameCtrl.text.trim();
        await AuthService.signUpWithEmail(email, password, name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGoogleAuth() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign-In Failed'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── 🆕 GRADIENT DEFINITION ──
    final goldGradient = const LinearGradient(
      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    final baseGold = const Color(0xFFFFD700); // Used for borders and spinners

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── LOGO ──
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: baseGold.withOpacity(0.1),
                    ),
                    // ── 🆕 GRADIENT ICON ──
                    child: ShaderMask(
                      shaderCallback: (bounds) => goldGradient.createShader(bounds),
                      child: const Icon(Icons.movie_creation_rounded, size: 70, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'EzzeWatchList',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Welcome back to your theater' : 'Start your cinematic journey',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 48),

                // ── INPUT FIELDS ──
                if (!_isLogin) ...[
                  _buildTextField(controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline, isDark: isDark, baseGold: baseGold),
                  const SizedBox(height: 16),
                ],

                _buildTextField(controller: _emailCtrl, label: 'Email Address', icon: Icons.email_outlined, isDark: isDark, isEmail: true, baseGold: baseGold),
                const SizedBox(height: 16),

                _buildTextField(controller: _passwordCtrl, label: 'Password', icon: Icons.lock_outline, isDark: isDark, isPassword: true, baseGold: baseGold),
                const SizedBox(height: 32),

                // ── AUTH BUTTONS ──
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: baseGold))
                    : Container(
                  // ── 🆕 GRADIENT BUTTON WRAPPER ──
                  decoration: BoxDecoration(
                    gradient: goldGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: baseGold.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4)
                      )
                    ],
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent, // Let the gradient show through
                      shadowColor: Colors.transparent,     // Prevent default shadows from clashing
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitEmailAuth,
                    child: Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin ? 'New here? Sign Up' : 'Already have an account? Sign In',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                    ],
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _submitGoogleAuth,
                  icon: SvgPicture.network(
                    'https://upload.wikimedia.org/wikipedia/commons/3/3c/Google_Favicon_2025.svg',
                    height: 24,
                  ),
                  label: const Text('Continue with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for clean text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color baseGold, // Added baseGold requirement for the border
    bool isPassword = false,
    bool isEmail = false
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: baseGold, width: 1.5)),
      ),
    );
  }
}