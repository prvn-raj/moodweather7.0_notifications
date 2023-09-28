// app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData themeData = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    primaryColor: Color(0xFF121212),
    fontFamily: 'LuckiestGuy', // Apply the font throughout the app
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF121212),
      secondary: Color(0xFFE9A125),
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF121212),
    textTheme: TextTheme(
      headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
      headline6: TextStyle(fontSize: 24.0, fontFamily: 'LuckiestGuy', color: Color(0xFFE9A125)),
      bodyText2: TextStyle(fontSize: 14.0),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: Color(0xFFE9A125),
      textTheme: ButtonTextTheme.primary,
    ),
  );
}
