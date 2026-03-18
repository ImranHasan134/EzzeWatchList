// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/database/watch_provider.dart';
import 'utils/app_theme.dart';
import 'utils/theme_provider.dart';
import 'ui/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: const MainScaffold(),
    );
  }
}
