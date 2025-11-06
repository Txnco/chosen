import 'package:flutter/material.dart';

class AppTheme {
  // ---------- BASE COLORS ----------
  static const Color pureBlack = Color(0xFF000000);
  static const Color softBlack = Color(0xFF121212);
  static const Color darkGray = Color(0xFF1C1C1C);
  static const Color darkGrayLight = Color(0xFF2A2A2A);
  static const Color darkGrayLighter = Color(0xFF3A3A3A);
  static const Color mediumGray = Color(0xFF7A7A7A);
  static const Color lightGray = Color(0xFFEDEDED);
  static const Color softGray = Color(0xFFF7F7F7);
  static const Color white = Color(0xFFFFFFFF);

  // ---------- CUSTOM COMPONENT COLORS ----------
  // 💬 Chat bubbles
  static const Color messageBubbleLightUser = Color(0xFFEDEDED);
  static const Color messageBubbleLightOther = Color(0xFFF3F3F3);
  static const Color messageBubbleDarkUser = Color(0xFF3A3A3A);
  static const Color messageBubbleDarkOther = Color(0xFF2A2A2A);

  // 🧠 Cards / Containers
  static const Color cardLight = Colors.white;
  static const Color cardDark = darkGray;
  static const Color cardDarkElevated = darkGrayLight;

  // ✏️ Inputs
  static const Color inputLight = Color(0xFFF5F5F5);
  static const Color inputDark = Color(0xFF2A2A2A);

  // ✅ Accents / success / warnings
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB300);

  // ---------- LIGHT THEME ----------
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Avenir',
    scaffoldBackgroundColor: white,
    primaryColor: pureBlack,
    dividerColor: Colors.grey.shade300,

    appBarTheme: const AppBarTheme(
      backgroundColor: white,
      foregroundColor: pureBlack,
      elevation: 0,
      centerTitle: true,
    ),

    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 2,
      margin: EdgeInsets.zero,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),

    colorScheme: const ColorScheme.light(
      primary: pureBlack,
      onPrimary: white,
      secondary: Colors.grey,
      onSecondary: pureBlack,
      surface: white,
      onSurface: pureBlack,
      error: error,
      onError: white,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: pureBlack, width: 1.5),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: pureBlack,
        foregroundColor: white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade400),
        foregroundColor: pureBlack,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  // ---------- DARK THEME ----------
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Avenir',
    scaffoldBackgroundColor: softBlack,
    primaryColor: white,
    dividerColor: Colors.grey.shade800,

    appBarTheme: const AppBarTheme(
      backgroundColor: darkGray,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
    ),

    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 2,
      margin: EdgeInsets.zero,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: darkGrayLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),

    colorScheme: const ColorScheme.dark(
      primary: white,
      onPrimary: pureBlack,
      secondary: mediumGray,
      onSecondary: pureBlack,
      surface: darkGray,
      onSurface: white,
      error: error,
      onError: white,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: white, width: 1.5),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkGrayLighter,
        foregroundColor: white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade700),
        foregroundColor: white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  // ---------- CUSTOM APP COLORS (UNIVERSAL ACCESS) ----------
  static const Map<String, Color> lightCustom = {
    'bubbleUser': messageBubbleLightUser,
    'bubbleOther': messageBubbleLightOther,
    'input': inputLight,
    'card': cardLight,
    'badge': Color(0xFFEEEEEE),
  };

  static const Map<String, Color> darkCustom = {
    'bubbleUser': messageBubbleDarkUser,
    'bubbleOther': messageBubbleDarkOther,
    'input': inputDark,
    'card': cardDark,
    'badge': Color(0xFF2E2E2E),
  };

  // ---------- GRADIENTS ----------
  static List<Color> motivationGradientLight = [
    Color.fromARGB(255, 49, 49, 49),
    Color.fromARGB(255, 95, 95, 95),
  ];

  static List<Color> motivationGradientDark = [
    Color(0xFF1F1F1F),
    Color(0xFF121212),
  ];

  // ---------- CONTEXT HELPERS ----------
  static Color getBubbleColor(BuildContext context, {required bool isMe}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isMe
        ? (isDark ? AppTheme.messageBubbleDarkUser : AppTheme.messageBubbleLightUser)
        : (isDark ? AppTheme.messageBubbleDarkOther : AppTheme.messageBubbleLightOther);
  }

  static Color getInputColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.inputDark : AppTheme.inputLight;
  }

  static Color getCardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.cardDark : AppTheme.cardLight;
  }

  static Color getBadgeColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.darkCustom['badge']! : AppTheme.lightCustom['badge']!;
  }

}
