// lib/data/network/auth_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;
  static final String _webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  // ── Email & Password Auth ──────────────────────────────────
  static Future<AuthResponse> signUpWithEmail(String email, String password, String name) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name}, // Save their name to their profile
    );
  }

  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Google Auth ────────────────────────────────────────────
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(serverClientId: _webClientId);
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) throw 'Missing Google Auth Tokens';

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // ── Sign Out ───────────────────────────────────────────────
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _supabase.auth.signOut();
  }
}