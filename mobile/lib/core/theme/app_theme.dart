import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0E17), // Deep Dark Blue/Black
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00FF9D), // Neon Green
      secondary: Color(0xFF00D1FF), // Neon Blue
      surface: Color(0xFF161B26), // Lighter Dark for Cards
      error: Color(0xFFFF4444),
      onPrimary: Colors.black,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme), // Sporty Font
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0E17),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF161B26),
      selectedItemColor: Color(0xFF00FF9D),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
    ),
  );
}
