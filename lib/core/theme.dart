import 'package:flutter/material.dart';

import '../incidents/incident.dart';

/// Snagboard design tokens: warm paper, ink, one signal colour. Flat, no
/// gradients, no shadows, 2 px outlines, 4 px corners.
abstract final class Snag {
  static const paper = Color(0xFFF3EFE6);
  static const paperDeep = Color(0xFFE8E2D4);
  static const ink = Color(0xFF16130F);
  static const inkSoft = Color(0xFF4A443C);
  static const flare = Color(0xFFFF4F1A);
  static const onFlare = Color(0xFF16130F);
  static const danger = Color(0xFF9B1C1C);

  static const outline = 2.0;
  static const radius = 4.0;
  static const gap = 16.0;

  static const sans = 'SpaceGrotesk';
  static const mono = 'JetBrainsMono';

  static Color statusColor(IncidentStatus s) => switch (s) {
        IncidentStatus.submitted => const Color(0xFF6B6359),
        IncidentStatus.acknowledged => const Color(0xFF2457D6),
        IncidentStatus.inProgress => const Color(0xFFB86E00),
        IncidentStatus.resolved => const Color(0xFF1F7A4D),
        IncidentStatus.declined => const Color(0xFF9B1C1C),
      };

  /// Mono caps label style used for codes, tabs and stamps.
  static TextStyle label({double size = 12, Color color = ink}) => TextStyle(
        fontFamily: mono,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: color,
      );

  static const border = BorderSide(color: ink, width: outline);
  static final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: border,
  );
}

ThemeData buildSnagTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: Snag.sans,
    scaffoldBackgroundColor: Snag.paper,
    colorScheme: const ColorScheme.light(
      primary: Snag.ink,
      onPrimary: Snag.paper,
      secondary: Snag.flare,
      onSecondary: Snag.onFlare,
      surface: Snag.paper,
      onSurface: Snag.ink,
      error: Snag.danger,
      outline: Snag.ink,
    ),
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Snag.radius),
    borderSide: Snag.border,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Snag.paper,
      foregroundColor: Snag.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.6),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: Snag.flare, width: 2.5),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: Snag.danger, width: 2),
      ),
      labelStyle: Snag.label(size: 12, color: Snag.inkSoft),
      floatingLabelStyle: Snag.label(size: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Snag.ink,
        foregroundColor: Snag.paper,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Snag.radius)),
        textStyle: Snag.label(size: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Snag.ink,
        minimumSize: const Size(48, 48),
        side: Snag.border,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Snag.radius)),
        textStyle: Snag.label(size: 13),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Snag.ink,
        minimumSize: const Size(48, 48),
        textStyle: Snag.label(size: 12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Snag.ink,
      contentTextStyle: const TextStyle(fontFamily: Snag.sans, color: Snag.paper),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Snag.radius)),
    ),
    dividerTheme: const DividerThemeData(color: Snag.ink, thickness: 1),
  );
}
