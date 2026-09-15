import 'package:flutter/material.dart';

class AppTheme {
  // Core colours
  static const Color background    = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color accentOrange  = Color(0xFFE9A125);

  // Confidence badge colours
  static const Color confidenceHigh   = Color(0xFF4CAF50);
  static const Color confidenceMedium = Color(0xFFFFC107);
  static const Color confidenceLow    = Color(0xFF9E9E9E);

  static const BorderRadius defaultCardRadius = BorderRadius.all(Radius.circular(16));

  // Centralised mood colours (replaces duplicated switches across 3 files)
  static Color moodColor(String mood) {
    switch (mood) {
      case 'Happy':   return Colors.green[200]!;
      case 'Relaxed': return Colors.blue[200]!;
      case 'Sad':     return Colors.grey[400]!;
      case 'Excited': return Colors.orange[200]!;
      case 'Angry':   return Colors.red[200]!;
      case 'Sick':    return Colors.purple[200]!;
      default:        return Colors.grey;
    }
  }

  static IconData moodIcon(String mood) {
    switch (mood) {
      case 'Happy':   return Icons.sentiment_very_satisfied;
      case 'Relaxed': return Icons.sentiment_satisfied_alt_sharp;
      case 'Sad':     return Icons.sentiment_very_dissatisfied;
      case 'Excited': return Icons.sentiment_very_satisfied_rounded;
      case 'Angry':   return Icons.sentiment_neutral_sharp;
      case 'Sick':    return Icons.sentiment_very_dissatisfied_rounded;
      default:        return Icons.sentiment_satisfied;
    }
  }

  // Text styles
  static const TextStyle appBarTitle = TextStyle(
    color: accentOrange, fontFamily: 'LuckiestGuy', fontSize: 24,
  );

  static const TextStyle luckiestGuy = TextStyle(fontFamily: 'LuckiestGuy');

  static const TextStyle bodyPoppins = TextStyle(
    fontFamily: 'Poppins', fontSize: 13, color: Colors.white70,
  );

  static final ThemeData themeData = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    primaryColor: background,
    fontFamily: 'LuckiestGuy',
    colorScheme: const ColorScheme.dark(
      primary: background,
      secondary: accentOrange,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: background,
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 24.0, fontFamily: 'LuckiestGuy', color: accentOrange),
      bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Poppins'),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: accentOrange,
      textTheme: ButtonTextTheme.primary,
    ),
  );
}
