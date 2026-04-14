// lib/ui/auth/login_screen.dart

import 'package:flutter/material.dart';
import '../../data/network/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // Only used for Sign Up

  bool _isLogin = true; // Toggle between Login and Sign Up
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
      // Note: We don't need Navigator.push here because main.dart will auto-route us!
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
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
            SnackBar(content: Text('Google Sign-In Failed'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.movie_filter_rounded, size: 80, color: const Color(0xFFFFD700)),
                const SizedBox(height: 16),
                Text(
                  'EzzeWatchList',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 40),

                if (!_isLogin) ...[
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                    : FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _submitEmailAuth,
                  child: Text(_isLogin ? 'Sign In' : 'Sign Up', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),

                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? 'Need an account? Sign Up' : 'Already have an account? Sign In'),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR')),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _submitGoogleAuth,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}