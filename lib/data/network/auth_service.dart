// lib/data/network/auth_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;
  static final String _webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  static Future<AuthResponse> signUpWithEmail(String email, String password, String name) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

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

  // ── 🆕 FIXED: PREVENTS DEADLOCKS ON SIGN OUT ──
  static Future<void> signOut() async {
    try {
      // Force Google to sign out, but abandon it if it takes longer than 2 seconds
      await GoogleSignIn().signOut().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Silently ignore Google plugin errors so we can still sign out of Supabase
    }

    // Always successfully sign out of Supabase
    await _supabase.auth.signOut();
  }
}