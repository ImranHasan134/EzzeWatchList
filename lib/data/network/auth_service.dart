// lib/data/network/auth_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // 🆕 Pull the Google Web Client ID securely
  static final String _webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      // 1. Trigger the native Google Sign-In popup
      final googleSignIn = GoogleSignIn(serverClientId: _webClientId);
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null; // User closed the popup

      // 2. Get the auth tokens from Google
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Missing Google Auth Tokens';
      }

      // 3. Hand those tokens to Supabase to log the user into your database
      return await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await Supabase.instance.client.auth.signOut();
  }
}