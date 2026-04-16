// lib/ui/auth/login_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/network/auth_service.dart';
import '../main/main_screen.dart'; // ── 🆕 NEEDED FOR ROUTING ──

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

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await AuthService.signInWithEmail(email, password).timeout(const Duration(seconds: 15));
      } else {
        final name = _nameCtrl.text.trim();
        await AuthService.signUpWithEmail(email, password, name).timeout(const Duration(seconds: 15));
      }

      // ── 🆕 FIXED: EXPLICITLY PUSH TO MAIN SCREEN ON SUCCESS ──
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection timed out. Please check your internet.'), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _submitGoogleAuth() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final response = await AuthService.signInWithGoogle().timeout(const Duration(seconds: 15));

      // ── 🆕 FIXED: IF USER CANCELS THE GOOGLE POPUP, STOP SPINNING ──
      if (response == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // ── 🆕 FIXED: EXPLICITLY PUSH TO MAIN SCREEN ON SUCCESS ──
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection timed out. Please check your internet.'), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In Failed or was cancelled.'), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldGradient = const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)], begin: Alignment.centerLeft, end: Alignment.centerRight);
    final baseGold = const Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: baseGold.withOpacity(0.1)),
                    child: ShaderMask(shaderCallback: (bounds) => goldGradient.createShader(bounds), child: const Icon(Icons.movie_creation_rounded, size: 70, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('EzzeWatchList', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 8),
                Text(_isLogin ? 'Welcome back to your theater' : 'Start your cinematic journey', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 48),

                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: !_isLogin
                      ? Padding(padding: const EdgeInsets.only(bottom: 16), child: _buildTextField(controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline, isDark: isDark, baseGold: baseGold))
                      : const SizedBox.shrink(),
                ),

                _buildTextField(controller: _emailCtrl, label: 'Email Address', icon: Icons.email_outlined, isDark: isDark, isEmail: true, baseGold: baseGold),
                const SizedBox(height: 16),
                _buildTextField(controller: _passwordCtrl, label: 'Password', icon: Icons.lock_outline, isDark: isDark, isPassword: true, baseGold: baseGold),
                const SizedBox(height: 32),

                _isLoading
                    ? Center(child: CircularProgressIndicator(color: baseGold))
                    : Container(
                  decoration: BoxDecoration(gradient: goldGradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: baseGold.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _submitEmailAuth,
                    child: Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _isLogin = !_isLogin);
                  },
                  style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
                  child: Text(_isLogin ? 'New here? Sign Up' : 'Already have an account? Sign In', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold))),
                      Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                    ],
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _submitGoogleAuth,
                  icon: SvgPicture.network('https://upload.wikimedia.org/wikipedia/commons/3/3c/Google_Favicon_2025.svg', height: 24),
                  label: const Text('Continue with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), foregroundColor: isDark ? Colors.white : Colors.black, side: BorderSide(color: isDark ? Colors.white24 : Colors.black26), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, required bool isDark, required Color baseGold, bool isPassword = false, bool isEmail = false}) {
    return TextField(
      controller: controller, obscureText: isPassword, keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text, style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey), prefixIcon: Icon(icon, color: Colors.grey), filled: true, fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: baseGold, width: 1.5))),
    );
  }
}