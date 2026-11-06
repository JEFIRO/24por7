import 'package:flutter/material.dart';

export 'app_colors.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'branding_config.dart';

abstract final class AppTheme {
  static const background = AppColors.background;

  /// Esquema padrão do design system; tenant com cor própria gera o esquema
  /// a partir da semente, mantendo o fundo branco.
  static ColorScheme schemeFor(BrandingConfig branding) =>
      branding.primaryColor == AppColors.brand
      ? lightScheme
      : ColorScheme.fromSeed(
          seedColor: branding.primaryColor,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(surface: Colors.white, surfaceTint: Colors.transparent);

  static ThemeData light(BrandingConfig branding) {
    final scheme = schemeFor(branding);
    final colors = AppThemeColors.fallback(
      scheme,
      secondary: branding.secondaryColor,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkSparkle.splashFactory,
    );
    final text = base.textTheme;
    final fieldLine = BorderSide(color: scheme.outline);
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return base.copyWith(
      extensions: [colors],
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      // Cards são raros (diálogos, prévias, itens selecionados como unidade):
      // fundo da página, contorno fino e nenhuma sombra.
      cardTheme: CardThemeData(
        elevation: 0,
        color: background,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: UnderlineInputBorder(borderSide: fieldLine),
        enabledBorder: UnderlineInputBorder(borderSide: fieldLine),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.error)
                ? scheme.error
                : states.contains(WidgetState.focused)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
        helperMaxLines: 2,
        errorMaxLines: 2,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: UnderlineInputBorder(borderSide: fieldLine),
          enabledBorder: UnderlineInputBorder(borderSide: fieldLine),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          side: fieldLine,
          shape: controlShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: controlShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size(48, 48),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colors.primarySoft,
          selectedForegroundColor: colors.onPrimarySoft,
          side: fieldLine,
          minimumSize: const Size(0, 40),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: colors.primarySoft,
        checkmarkColor: colors.onPrimarySoft,
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide.none
              : fieldLine,
        ),
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        secondaryLabelStyle: text.labelLarge?.copyWith(
          color: colors.onPrimarySoft,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        elevation: 0,
        pressElevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        selectedColor: colors.onPrimarySoft,
        selectedTileColor: colors.primarySoft,
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: AppSpacing.md,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: const WidgetStatePropertyAll(Colors.transparent),
        dataRowColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? scheme.surfaceContainerLow
              : states.contains(WidgetState.selected)
              ? scheme.surfaceContainer
              : null,
        ),
        headingTextStyle: text.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
          letterSpacing: .5,
        ),
        dataTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
        dividerThickness: 1,
        horizontalMargin: 0,
        columnSpacing: AppSpacing.xl,
        headingRowHeight: 44,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 68,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primarySoft,
        elevation: 0,
        height: 80,
        // O esquema fixo não define secondaryContainer, que o M3 usaria aqui.
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.onPrimarySoft
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: background,
        labelType: NavigationRailLabelType.selected,
        indicatorColor: colors.primarySoft,
        selectedIconTheme: IconThemeData(color: colors.onPrimarySoft),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: scheme.onSurface.withValues(alpha: .25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
        waitDuration: const Duration(milliseconds: 400),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: .18),
        selectionHandleColor: scheme.primary,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(scheme.outlineVariant),
        radius: const Radius.circular(AppRadius.pill),
        thickness: const WidgetStatePropertyAll(6),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.lg),
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        collapsedShape: Border(
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
    );
  }
}
