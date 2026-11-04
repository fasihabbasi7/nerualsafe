import 'package:flutter/material.dart';

import '../services/secure_vault_service.dart';

/// Colour tokens for the NeuralSafe design. Two skins: Midnight Ink (dark)
/// and Cobalt Paper (light). Read them anywhere with `context.ns`.
@immutable
class NsColors extends ThemeExtension<NsColors> {
  const NsColors({
    required this.bg,
    required this.panel,
    required this.panel2,
    required this.ink,
    required this.mute,
    required this.acc,
    required this.accInk,
    required this.ok,
    required this.warn,
    required this.crit,
    required this.line,
  });

  final Color bg;
  final Color panel;
  final Color panel2;
  final Color ink;
  final Color mute;
  final Color acc;
  final Color accInk;
  final Color ok;
  final Color warn;
  final Color crit;
  final Color line;

  static const dark = NsColors(
    bg: Color(0xFF0F141B),
    panel: Color(0xFF171E28),
    panel2: Color(0xFF212A37),
    ink: Color(0xFFE8EEF6),
    mute: Color(0xFF8593A6),
    acc: Color(0xFF8FD3FF),
    accInk: Color(0xFF06141F),
    ok: Color(0xFF6FE0B5),
    warn: Color(0xFFB69CFF),
    crit: Color(0xFFFF4D6D),
    line: Color(0xFF2A3544),
  );

  static const light = NsColors(
    bg: Color(0xFFE9EEF2),
    panel: Color(0xFFF7F9FB),
    panel2: Color(0xFFD9E1E8),
    ink: Color(0xFF0D1F2D),
    mute: Color(0xFF5A6E80),
    acc: Color(0xFF1F5FD1),
    accInk: Color(0xFFF4F8FF),
    ok: Color(0xFF1C9A72),
    warn: Color(0xFF6B4FD8),
    crit: Color(0xFFD6264A),
    line: Color(0xFFC5D0DB),
  );

  @override
  NsColors copyWith({
    Color? bg,
    Color? panel,
    Color? panel2,
    Color? ink,
    Color? mute,
    Color? acc,
    Color? accInk,
    Color? ok,
    Color? warn,
    Color? crit,
    Color? line,
  }) {
    return NsColors(
      bg: bg ?? this.bg,
      panel: panel ?? this.panel,
      panel2: panel2 ?? this.panel2,
      ink: ink ?? this.ink,
      mute: mute ?? this.mute,
      acc: acc ?? this.acc,
      accInk: accInk ?? this.accInk,
      ok: ok ?? this.ok,
      warn: warn ?? this.warn,
      crit: crit ?? this.crit,
      line: line ?? this.line,
    );
  }

  @override
  NsColors lerp(ThemeExtension<NsColors>? other, double t) {
    if (other is! NsColors) return this;
    return NsColors(
      bg: Color.lerp(bg, other.bg, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panel2: Color.lerp(panel2, other.panel2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mute: Color.lerp(mute, other.mute, t)!,
      acc: Color.lerp(acc, other.acc, t)!,
      accInk: Color.lerp(accInk, other.accInk, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      crit: Color.lerp(crit, other.crit, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}

extension NsContext on BuildContext {
  NsColors get ns => Theme.of(this).extension<NsColors>()!;
}

/// Text styles. Sora (headings and numbers) and Plus Jakarta Sans (body)
/// are variable fonts bundled in assets/fonts, so weights are set through
/// font variations.
class NsText {
  NsText._();

  static FontWeight _fw(int w) {
    final i = (w ~/ 100).clamp(1, 9).toInt();
    return FontWeight.values[i - 1];
  }

  static TextStyle head(double size,
      {int w = 600, Color? color, double? spacing, double? height}) {
    return TextStyle(
      fontFamily: 'Sora',
      fontSize: size,
      fontWeight: _fw(w),
      fontVariations: [FontVariation('wght', w.toDouble())],
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }

  static TextStyle body(double size,
      {int w = 500, Color? color, double? spacing, double? height}) {
    return TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: size,
      fontWeight: _fw(w),
      fontVariations: [FontVariation('wght', w.toDouble())],
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }

  /// Sora with tabular figures, so digits line up and do not jitter.
  static TextStyle num(double size,
      {int w = 500, Color? color, double? spacing}) {
    return TextStyle(
      fontFamily: 'Sora',
      fontSize: size,
      fontWeight: _fw(w),
      fontVariations: [FontVariation('wght', w.toDouble())],
      fontFeatures: const [FontFeature.tabularFigures()],
      color: color,
      letterSpacing: spacing,
    );
  }

  static TextStyle urdu(double size, {Color? color}) {
    return TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: size,
      fontWeight: FontWeight.w500,
      fontVariations: const [FontVariation('wght', 500)],
      color: color,
    );
  }
}

ThemeData buildNsTheme(NsColors c, Brightness brightness) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c.line),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.bg,
    fontFamily: 'PlusJakartaSans',
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.acc,
      onPrimary: c.accInk,
      secondary: c.acc,
      onSecondary: c.accInk,
      error: c.crit,
      onError: Colors.white,
      surface: c.panel,
      onSurface: c.ink,
    ),
    extensions: [c],
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.panel,
      labelStyle: NsText.body(13, color: c.mute),
      floatingLabelStyle: NsText.body(12, w: 600, color: c.mute),
      hintStyle: NsText.body(14, color: c.mute),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.acc, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.crit),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.crit, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.acc),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.panel2,
      contentTextStyle: NsText.body(13, color: c.ink),
      behavior: SnackBarBehavior.floating,
    ),
    dividerColor: c.line,
  );
}

/// App-level settings stored in the same encrypted vault as everything
/// else. Appearance applies immediately. Test mode is read once at
/// start-up (see main.dart), so changing it needs an app restart.
class AppSettings {
  AppSettings._();

  static const _themeKey = 'app_theme';
  static const _testModeKey = 'test_mode';

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  /// true = alerts run fully but no real SMS is sent (safe default).
  static bool testMode = true;

  /// The value main.dart actually used when the app started. If it differs
  /// from [testMode], the user has changed it and must restart the app.
  static bool appliedTestMode = true;

  static void load() {
    final box = SecureVaultService.instance.box;
    final t = box.get(_themeKey);
    themeMode.value = t == 'light' ? ThemeMode.light : ThemeMode.dark;
    final tm = box.get(_testModeKey);
    testMode = tm is bool ? tm : true;
    appliedTestMode = testMode;
  }

  static Future<void> setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    await SecureVaultService.instance.box
        .put(_themeKey, mode == ThemeMode.light ? 'light' : 'dark');
  }

  static Future<void> setTestMode(bool value) async {
    testMode = value;
    await SecureVaultService.instance.box.put(_testModeKey, value);
  }
}
