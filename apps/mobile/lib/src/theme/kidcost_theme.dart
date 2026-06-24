import 'package:flutter/material.dart';

class KidCostTheme {
  const KidCostTheme._();

  static const primary = Color(0xFF0F766E);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFD6F3EF);
  static const onPrimaryContainer = Color(0xFF062E2B);
  static const secondary = Color(0xFFC76F3D);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFFE3D3);
  static const onSecondaryContainer = Color(0xFF4B1F0D);
  static const tertiary = Color(0xFF375E97);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFDCE8FF);
  static const onTertiaryContainer = Color(0xFF10284F);
  static const success = Color(0xFF2F855A);
  static const warning = Color(0xFFB7791F);
  static const danger = Color(0xFFB42318);
  static const surface = Color(0xFFFAFAF7);
  static const surfaceVariant = Color(0xFFE7ECE7);
  static const text = Color(0xFF172326);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: danger,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: Color(0xFF3F4B4D),
      outline: Color(0xFF6F7D80),
      outlineVariant: Color(0xFFC7D0D2),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2C3538),
      onInverseSurface: Color(0xFFEFF2F0),
      inversePrimary: Color(0xFF7FD8CE),
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    );
  }
}
