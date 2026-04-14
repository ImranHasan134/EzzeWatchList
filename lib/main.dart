// lib/main.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/database/watch_provider.dart';
import 'utils/app_theme.dart';
import 'utils/theme_provider.dart';
import 'ui/main_scaffold.dart';
import 'ui/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🆕 Load the secret keys
  await dotenv.load(fileName: ".env");

  // 🆕 Initialize Supabase securely
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Load saved theme preference before app starts
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
      // 🆕 THE AUTH GATE
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // If the stream is still loading, show a blank screen
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final session = snapshot.data?.session;

          if (session != null) {
            // User is logged in! Send them to the main app
            return const MainScaffold();
          } else {
            // User is NOT logged in! Send them to the Login Screen
            return const LoginScreen();
          }
        },
      ),
    );
  }
}