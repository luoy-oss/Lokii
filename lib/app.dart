import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';

class LokiiApp extends StatelessWidget {
  const LokiiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lokii',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
