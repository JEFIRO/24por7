import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'status_badge.dart';

class AppContent extends StatelessWidget {
  const AppContent({
    required this.child,
    this.maxWidth = AppLayout.contentMaxWidth,
    this.padding,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding:
            padding ??
            EdgeInsets.all(
              AppBreakpoints.isMobile(context) ? AppSpacing.lg : AppSpacing.xl,
            ),
        child: child,
      ),
    ),
  );
}

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onRefresh,
    this.refreshing = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Ação "Atualizar": botão com texto à direita a partir de 600px; abaixo
  /// disso vira ícone ao lado do título (a página também puxa para atualizar).
  final VoidCallback? onRefresh;

  /// Desabilita "Atualizar" enquanto a página carrega.
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = AppBreakpoints.isMobile(context);
    final hasRefresh = onRefresh != null;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              if (hasRefresh)
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: refreshing ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: actions,
            ),
          ],
        ],
      );
    }

    final trailing = [
      if (hasRefresh)
        TextButton.icon(
          onPressed: refreshing ? null : onRefresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Atualizar'),
        ),
      ...actions,
    ];
    // Ações à direita, com até 60% da largura; o título fica com o resto.
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: heading),
          if (trailing.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.lg),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * .6),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: trailing,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Título de seção (`title-large`) com ação opcional à direita. As seções de
/// uma página ficam separadas por `AppSpacing.xxl`, não por cards.
class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.title, {this.subtitle, this.trailing, super.key});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Quadrado de ícone das linhas de lista (40px, `surface-high`).
class AppIconWell extends StatelessWidget {
  const AppIconWell(this.icon, {this.color, super.key});
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: 22, color: color ?? scheme.primary),
    );
  }
}

/// Linha plana de lista: ícone opcional, título, meta e um trailing, com
/// divisória embaixo. Substitui o "um card por item".
class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.title,
    this.meta,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.showDivider = true,
    this.muted = false,
    this.metaMaxLines = 2,
    this.trailingOnTitle = false,
    super.key,
  });

  final String title;
  final String? meta;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final bool showDivider;
  final bool muted;
  final int metaMaxLines;

  /// Põe [trailing] na linha do título, à direita, em vez de centralizado.
  final bool trailingOnTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titleText = Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: (dense ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)
          ?.copyWith(color: muted ? scheme.onSurfaceVariant : null),
    );
    return InkWell(
      onTap: onTap,
      hoverColor: scheme.surfaceContainerLow,
      child: Container(
        constraints: BoxConstraints(minHeight: dense ? 48 : 64),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: showDivider
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              )
            : null,
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailingOnTitle && trailing != null)
                    Row(
                      children: [
                        Expanded(child: titleText),
                        const SizedBox(width: AppSpacing.md),
                        trailing!,
                      ],
                    )
                  else
                    titleText,
                  if (meta != null && meta!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        meta!,
                        maxLines: metaMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null && !trailingOnTitle) ...[
              const SizedBox(width: AppSpacing.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class AppKpi {
  const AppKpi({
    required this.label,
    required this.value,
    this.icon,
    this.help,
    this.tone,
    this.onTap,
    this.key,
  });
  final Key? key;
  final VoidCallback? onTap;
  final String label;
  final String value;
  final IconData? icon;
  final String? help;

  /// Quando definido, colore o valor (ex.: alertas críticos).
  final AppStatusTone? tone;
}

/// Indicadores lado a lado numa faixa plana, separados por divisórias de 1px.
/// Nada de card por métrica.
class AppKpiStrip extends StatelessWidget {
  const AppKpiStrip({required this.items, super.key});
  final List<AppKpi> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = BorderSide(color: scheme.outlineVariant);
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < AppBreakpoints.mobile;
        final columns = mobile
            ? 2
            : (constraints.maxWidth / 180).floor().clamp(2, items.length);
        final rows = <List<AppKpi>>[
          for (var i = 0; i < items.length; i += columns)
            items.sublist(i, (i + columns).clamp(0, items.length)),
        ];
        return Container(
          decoration: BoxDecoration(border: Border(top: line)),
          child: Column(
            children: [
              for (final row in rows)
                Container(
                  decoration: BoxDecoration(border: Border(bottom: line)),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < columns; i++)
                          Expanded(
                            child: Container(
                              decoration: i == 0
                                  ? null
                                  : BoxDecoration(border: Border(left: line)),
                              padding: EdgeInsets.fromLTRB(
                                i == 0 ? 0 : AppSpacing.lg,
                                mobile ? AppSpacing.md : AppSpacing.lg,
                                AppSpacing.lg,
                                mobile ? AppSpacing.md : AppSpacing.lg,
                              ),
                              child: i < row.length
                                  ? _KpiCell(
                                      key: row[i].key,
                                      item: row[i],
                                      compact: mobile,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({required this.item, required this.compact, super.key});
  final AppKpi item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final valueColor = item.tone == null
        ? theme.colorScheme.onSurface
        : appToneColors(context, item.tone!).$2;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (item.icon != null) ...[
              Icon(item.icon, size: 20, color: muted),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(color: muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Valor sem número (ex.: "Não disponível") é estado, não métrica.
        if (RegExp(r'\d').hasMatch(item.value))
          Text(
            item.value,
            style:
                (compact
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.headlineMedium)
                    ?.copyWith(
                      color: valueColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ),
        if (item.help != null)
          Text(
            item.help!,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
      ],
    );
    if (item.onTap == null) return content;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: content,
      ),
    );
  }
}

/// Busca preenchida em `surface-low`, sem borda: a única exceção ao campo
/// com sublinhado. Fica acima de listas e tabelas.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    this.controller,
    this.hintText = 'Buscar',
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final none = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: trailing,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: none,
        enabledBorder: none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}

/// Aviso com régua colorida no topo (nunca borda lateral).
class AppBanner extends StatelessWidget {
  const AppBanner({
    required this.message,
    this.tone = AppStatusTone.warning,
    this.icon,
    this.action,
    super.key,
  });

  final String message;
  final AppStatusTone tone;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (tone) {
      AppStatusTone.info => theme.colorScheme.primary,
      AppStatusTone.critical => theme.colorScheme.error,
      AppStatusTone.success => AppThemeColors.of(context).success,
      AppStatusTone.neutral => theme.colorScheme.onSurfaceVariant,
      AppStatusTone.warning => AppThemeColors.of(context).warning,
    };
    final defaultIcon = switch (tone) {
      AppStatusTone.info => Icons.info_outline,
      AppStatusTone.success => Icons.check_circle_outline,
      AppStatusTone.critical => Icons.error_outline,
      _ => Icons.warning_amber_outlined,
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: color, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(message, style: theme.textTheme.bodyMedium),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Lista chave-valor em grade (rótulo pequeno `muted`, valor em 16/500).
class AppKeyValueGrid extends StatelessWidget {
  const AppKeyValueGrid({
    required this.entries,
    this.minItemWidth = 180,
    super.key,
  });
  final List<(String, String)> entries;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minItemWidth).floor().clamp(
          1,
          6,
        );
        final width =
            (constraints.maxWidth - AppSpacing.xl * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.lg,
          children: [
            for (final (label, value) in entries)
              SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Tabela plana com rolagem horizontal quando não cabe.
class AppTable extends StatelessWidget {
  const AppTable({required this.columns, required this.rows, super.key});
  final List<DataColumn> columns;
  final List<DataRow> rows;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: constraints.maxWidth),
        child: DataTable(
          showCheckboxColumn: false,
          columns: columns,
          rows: rows,
        ),
      ),
    ),
  );
}

/// Texto numérico de tabela: algarismos tabulares.
const tabularFigures = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
