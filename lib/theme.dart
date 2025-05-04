import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color blue = Color(0xFF00BCD4);
  static const Color cyan = Color(0xFF3F51B5);
  static const Color black = Color(0xFF0A0A0A);
  static const Color darkGrey = Color(0xFF1E1E1E);
  static const Color purple = Color(0xFF9C27B0);
  static const Color pink = Color(0xFFE91E63);
  static const Color teal = Color(0xFF009688);
  static const Color amber = Color(0xFFFFB300);
  
  // Light Theme Colors
  static const Color lightBg = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1E1E1E);
  static const Color lightAccent = Color(0xFF0085FF);
  
  // Text Styles
  static TextStyle headingStyle(bool isDark) => TextStyle(
    fontFamily: 'Segoe UI',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: isDark ? Colors.white : lightText,
  );
  
  static TextStyle subheadingStyle(bool isDark) => TextStyle(
    fontFamily: 'Segoe UI',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: isDark ? Colors.white : lightText,
  );
  
  static TextStyle bodyStyle(bool isDark) => TextStyle(
    fontFamily: 'Segoe UI',
    fontSize: 16,
    color: isDark ? Colors.white : lightText,
    height: 1.6,
  );
  
  // Theme Data
  static ThemeData getTheme({bool isDark = true}) {
    return isDark ? _getDarkTheme() : _getLightTheme();
  }
  
  static ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: blue,
        secondary: pink,
        tertiary: purple,
        background: black,
        surface: darkGrey,
        onBackground: Colors.white,
        onSurface: Colors.white,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: black,
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      tabBarTheme: const TabBarTheme(
        indicatorColor: pink,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: pink, width: 3),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: darkGrey,
        margin: const EdgeInsets.only(bottom: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Segoe UI',
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: blue,
          textStyle: const TextStyle(
            fontFamily: 'Segoe UI',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white.withOpacity(0.08),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blue, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIconColor: Colors.white70,
        suffixIconColor: Colors.white70,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: pink,
        linearTrackColor: Colors.white10,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: purple.withOpacity(0.2),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: purple.withOpacity(0.5)),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white70,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.1),
        thickness: 1,
      ),
    );
  }
  
  static ThemeData _getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: blue,
        secondary: pink,
        tertiary: purple,
        background: lightBg,
        surface: lightSurface,
        onBackground: lightText,
        onSurface: lightText,
        error: Colors.red,
      ),
      scaffoldBackgroundColor: lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightText,
        elevation: 0,
      ),
      tabBarTheme: const TabBarTheme(
        indicatorColor: pink,
        labelColor: lightText,
        unselectedLabelColor: Colors.black54,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: pink, width: 3),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: lightSurface,
        margin: const EdgeInsets.only(bottom: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Segoe UI',
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 1,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: blue,
          textStyle: const TextStyle(
            fontFamily: 'Segoe UI',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.black.withOpacity(0.03),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blue, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.black54),
        hintStyle: const TextStyle(color: Colors.black38),
        prefixIconColor: Colors.black54,
        suffixIconColor: Colors.black54,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: blue,
        linearTrackColor: Colors.black12,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: blue.withOpacity(0.1),
        labelStyle: const TextStyle(
          color: darkGrey,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: blue.withOpacity(0.3)),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Colors.black54,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withOpacity(0.1),
        thickness: 1,
      ),
    );
  }
  
  // Gradients
  static LinearGradient headerGradient({bool isDark = true, bool subtle = false}) {
    if (subtle) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark 
          ? [darkGrey.withOpacity(0.8), darkGrey.withOpacity(0.95)] 
          : [lightSurface.withOpacity(0.9), lightSurface],
        stops: const [0.0, 1.0],
      );
    }
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark 
        ? [blue, purple] 
        : [lightAccent, blue],
      stops: const [0.0, 1.0],
    );
  }
  
  static LinearGradient ctaGradient({bool isDark = true}) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark 
      ? [cyan, blue] 
      : [blue, purple],
    stops: const [0.0, 1.0],
  );
} 