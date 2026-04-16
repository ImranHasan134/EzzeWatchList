// lib/main.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/database/watch_provider.dart';
import 'utils/app_theme.dart';
import 'utils/theme_provider.dart';

// ── 🆕 IMPORT THE NEW SPLASH SCREEN ──
import 'ui/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => WatchProvider()),
      ],
      child: const EzzeApp(),
    ),
  );
}

class EzzeApp extends StatelessWidget {
  const EzzeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'EzzeWatchList',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      // ── 🆕 THE SPLASH SCREEN IS NOW THE FIRST ROUTE ──
      home: const SplashScreen(),
    );
  }
}