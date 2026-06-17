import 'package:flutter/material.dart';

/// Central palette + theme for the neon look.
class RgbColors {
  static const Color bg = Color(0xFF07070B);
  static const Color bgPanel = Color(0xFF12121C);
  static const Color red = Color(0xFFFF2D55);
  static const Color green = Color(0xFF2BFF88);
  static const Color blue = Color(0xFF2D9CFF);
  static const Color yellow = Color(0xFFFFE03D); // red + green
  static const Color cyan = Color(0xFF35FFE0); // green + blue
  static const Color magenta = Color(0xFFFF49E1); // red + blue
  static const Color textDim = Color(0xFF8A8AA0);
  static const Color text = Color(0xFFF2F2FA);
}

ThemeData buildTheme() {
  const base = ColorScheme.dark(
    primary: RgbColors.blue,
    secondary: RgbColors.magenta,
    surface: RgbColors.bgPanel,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: RgbColors.bg,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: RgbColors.text,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, color: RgbColors.text),
      bodyMedium: TextStyle(color: RgbColors.text),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: RgbColors.bgPanel,
      contentTextStyle: TextStyle(color: RgbColors.text),
    ),
  );
}

/// Reusable neon glow shadow.
List<BoxShadow> neonGlow(Color color, {double blur = 24, double spread = 1}) {
  return [
    BoxShadow(color: color.withOpacity(0.55), blurRadius: blur, spreadRadius: spread),
    BoxShadow(color: color.withOpacity(0.25), blurRadius: blur * 2, spreadRadius: spread * 2),
  ];
}
