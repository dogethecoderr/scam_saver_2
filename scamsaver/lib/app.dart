import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'features/home/home_screen.dart';
import 'features/analyze/analyze_screen.dart';
import 'features/screenshot/screenshot_screen.dart';
import 'features/audio/audio_screen.dart';
import 'features/live/live_screen.dart';
import 'features/learn/learn_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/analyze',
      builder: (context, state) => const AnalyzeScreen(),
    ),
    GoRoute(
      path: '/screenshot',
      builder: (context, state) => const ScreenshotScreen(),
    ),
    GoRoute(
      path: '/audio',
      builder: (context, state) => const AudioScreen(),
    ),
    GoRoute(
      path: '/live',
      builder: (context, state) => const LiveScreen(),
    ),
    GoRoute(
      path: '/learn',
      builder: (context, state) => const LearnScreen(),
    ),
  ],
);

class ScamSaverApp extends StatelessWidget {
  const ScamSaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp.router(
      title: 'ScamSaver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF8B5CF6),
          surface: Color(0xFF1E1E2E),
          error: Color(0xFFEF4444),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E2E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A3E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F1A),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      routerConfig: _router,
    );
  }
}
