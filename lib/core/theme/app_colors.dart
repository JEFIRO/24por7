import 'package:flutter/material.dart';

/// Tokens do design system 24/7 Admin (esquema M3 fidelity, semente #155EEF).
abstract final class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const brand = Color(0xFF155EEF);
  static const onBrand = Color(0xFFE7EAFF);
  static const teal = Color(0xFF0E9384);
  static const successSoft = Color(0xFFDCFCE7);
  static const success = Color(0xFF166534);
  static const warningSoft = Color(0xFFFEF3C7);
  static const warning = Color(0xFF92400E);
  static const offline = Color(0xFF616161);
}

const lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF0047C1),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(
    0xFFE7EAFF,
  ), // primary-soft: nav selecionada, badge info
  onPrimaryContainer: Color(0xFF0047C1),
  secondary: Color(0xFF475C9A),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF93000A),
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF191B24),
  onSurfaceVariant: Color(0xFF434655),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF2F3FF),
  surfaceContainer: Color(0xFFEDEDF9),
  surfaceContainerHigh: Color(0xFFE7E7F3),
  surfaceContainerHighest: Color(0xFFE1E1EE),
  outline: Color(0xFF737687), // linha dos campos, botões contornados
  outlineVariant: Color(0xFFC3C6D8), // divisores
  inverseSurface: Color(0xFF2E3039),
  onInverseSurface: Color(0xFFF0F0FC),
  surfaceTint: Colors.transparent,
);

/// Cores de status e superfícies que o ColorScheme do Material não cobre.
/// `primarySoft` deriva do primário para continuar funcionando quando um
/// tenant troca a cor da marca.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.brand,
    required this.onBrand,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.offline,
    required this.chartSecondary,
  });

  final Color brand;
  final Color onBrand;
  final Color primarySoft;
  final Color onPrimarySoft;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color offline;
  final Color chartSecondary;

  /// Fora do [AppTheme] (ex.: testes com MaterialApp puro) cai nos valores
  /// padrão derivados do esquema atual.
  static AppThemeColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppThemeColors>() ??
        AppThemeColors.fallback(theme.colorScheme);
  }

  factory AppThemeColors.fallback(ColorScheme scheme, {Color? secondary}) =>
      AppThemeColors(
        brand: scheme.primaryContainer,
        onBrand: scheme.onPrimaryContainer,
        primarySoft: identical(scheme, lightScheme)
            ? scheme.primaryContainer
            : Color.lerp(AppColors.background, scheme.primary, .09)!,
        onPrimarySoft: identical(scheme, lightScheme)
            ? scheme.onPrimaryContainer
            : scheme.primary,
        success: const Color(0xFF166534),
        successSoft: const Color(0xFFDCFCE7),
        warning: const Color(0xFF92400E),
        warningSoft: const Color(0xFFFEF3C7),
        offline: const Color(0xFF616161),
        chartSecondary: secondary ?? const Color(0xFF0E9384),
      );

  @override
  AppThemeColors copyWith({
    Color? brand,
    Color? onBrand,
    Color? primarySoft,
    Color? onPrimarySoft,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? offline,
    Color? chartSecondary,
  }) => AppThemeColors(
    brand: brand ?? this.brand,
    onBrand: onBrand ?? this.onBrand,
    primarySoft: primarySoft ?? this.primarySoft,
    onPrimarySoft: onPrimarySoft ?? this.onPrimarySoft,
    success: success ?? this.success,
    successSoft: successSoft ?? this.successSoft,
    warning: warning ?? this.warning,
    warningSoft: warningSoft ?? this.warningSoft,
    offline: offline ?? this.offline,
    chartSecondary: chartSecondary ?? this.chartSecondary,
  );

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      onPrimarySoft: Color.lerp(onPrimarySoft, other.onPrimarySoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      chartSecondary: Color.lerp(chartSecondary, other.chartSecondary, t)!,
    );
  }
}
