// lib/ui/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main/main_screen.dart';
import '../auth/login_screen.dart';

enum GifSize { small, medium, large, custom }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isExiting = false;
  bool _showBranding = false;

  @override
  void initState() {
    super.initState();

    // Trigger branding animation shortly after launch
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showBranding = true);
    });

    _startExitTimer();
  }

  Future<void> _startExitTimer() async {
    // 1. Wait for the GIF to play out
    await Future.delayed(const Duration(milliseconds: 2800));

    if (!mounted) return;

    // 2. Start fading out the GIF and Text
    setState(() {
      _isExiting = true;
      _showBranding = false;
    });

    // ── 🆕 FIXED TIMING ──
    // Wait exactly 800ms. This matches the duration of the text's
    // AnimatedOpacity and AnimatedSlide so it fully vanishes before the next screen!
    await Future.delayed(const Duration(milliseconds: 800));

    _navigateToNext();
  }

  void _navigateToNext() {
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    final Widget nextScreen = session != null ? const MainScreen() : const LoginScreen();

    // Premium Cross-Fade to App
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
      ),
    );
  }

  double _getGifSize(GifSize size) {
    final screenWidth = MediaQuery.of(context).size.width;
    switch (size) {
      case GifSize.small:
        return screenWidth * 0.4;
      case GifSize.large:
        return screenWidth * 0.8;
      case GifSize.medium:
        return screenWidth * 0.6;
      case GifSize.custom:
      default:
        return 350.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double currentSize = _getGifSize(GifSize.custom);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── CENTER ANIMATED GIF ──
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _isExiting ? 0.0 : 1.0,
              child: Image.asset(
                'assets/icon/splash.gif',
                width: currentSize,
                height: currentSize,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ── BOTTOM ANIMATED BRANDING ──
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                // This duration is 800ms, which is why we must wait 800ms before navigating
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _showBranding ? 1.0 : 0.0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    offset: _showBranding ? Offset.zero : const Offset(0, 0.5),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'A',
                          style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Ezze Softwares',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'PRODUCT',
                          style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}