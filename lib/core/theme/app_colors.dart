import 'package:flutter/material.dart';

import 'app_brand.dart';

/// Tokens do design system do Painel 24/7. As cores de marca vêm do logo
/// ([AppBrand]); o esquema é fixo e não muda por Empresa.
abstract final class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const successSoft = Color(0xFFDCFCE7);
  static const success = Color(0xFF166534);
  static const warningSoft = Color(0xFFFEF3C7);
  static const warning = Color(0xFF92400E);
  static const offline = Color(0xFF616161);
}

const lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppBrand.blue,
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(
    0xFFE3F0FC,
  ), // primary-soft: nav selecionada, badge info
  onPrimaryContainer: Color(0xFF00539E),
  secondary: AppBrand.navy,
  onSecondary: Color(0xFFFFFFFF),
  // Laranja da marca: destaque gráfico (ícones, gráficos, detalhes).
  // Claro demais para texto pequeno sobre branco; para isso, use
  // onTertiaryContainer.
  tertiary: AppBrand.orange,
  onTertiary: Color(0xFF2B1200),
  tertiaryContainer: Color(0xFFFFE9D6),
  onTertiaryContainer: Color(0xFF8A3B00),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF93000A),
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF171C24),
  onSurfaceVariant: Color(0xFF414855),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF1F5FC),
  surfaceContainer: Color(0xFFEBF0F8),
  surfaceContainerHigh: Color(0xFFE4EAF3),
  surfaceContainerHighest: Color(0xFFDDE4EE),
  outline: Color(0xFF707885), // linha dos campos, botões contornados
  outlineVariant: Color(0xFFC2C9D6), // divisores
  inverseSurface: Color(0xFF2C313A),
  onInverseSurface: Color(0xFFEEF1F8),
  surfaceTint: Colors.transparent,
);

/// Cores de marca, status e superfícies que o ColorScheme do Material não
/// cobre.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.brand,
    required this.onBrand,
    required this.accent,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.offline,
    required this.chartSecondary,
  });

  /// Fundo de áreas de marca (painel do login) e o texto sobre ele.
  final Color brand;
  final Color onBrand;

  /// Laranja da marca, para destaques gráficos.
  final Color accent;
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

  factory AppThemeColors.fallback(ColorScheme scheme) => AppThemeColors(
    brand: scheme.primary,
    onBrand: scheme.onPrimary,
    accent: AppBrand.orange,
    primarySoft: scheme.primaryContainer,
    onPrimarySoft: scheme.onPrimaryContainer,
    success: AppColors.success,
    successSoft: AppColors.successSoft,
    warning: AppColors.warning,
    warningSoft: AppColors.warningSoft,
    offline: AppColors.offline,
    chartSecondary: AppBrand.orange,
  );

  @override
  AppThemeColors copyWith({
    Color? brand,
    Color? onBrand,
    Color? accent,
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
    accent: accent ?? this.accent,
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
      accent: Color.lerp(accent, other.accent, t)!,
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
