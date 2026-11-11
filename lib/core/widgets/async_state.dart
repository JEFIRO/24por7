import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_entrance.dart';
import 'brand_logo.dart';
import 'app_skeleton.dart';

export 'app_skeleton.dart' show AppSkeletonLayout;

/// Espera de conteúdo: um skeleton no formato do que vai chegar, no lugar
/// de um spinner. [label] não aparece; é lido por leitores de tela.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    this.label = 'Carregando informações…',
    this.layout = AppSkeletonLayout.list,
    this.inline = false,
    super.key,
  });

  final String label;
  final AppSkeletonLayout layout;

  /// Dentro de um conteúdo que já tem margem (ex.: abaixo do cabeçalho da
  /// página). Sem isso, ocupa a tela com a margem padrão de página.
  final bool inline;

  @override
  Widget build(BuildContext context) =>
      AppSkeleton(label: label, layout: layout, padded: !inline);
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      _StatePanel(icon: icon, title: title, message: message, action: action);
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.message,
    required this.onRetry,
    this.title = 'Não foi possível carregar os dados',
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _StatePanel(
    icon: Icons.cloud_off_outlined,
    title: title,
    message: message,
    action: OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Tentar novamente'),
    ),
  );
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppEntrance(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandLogo.ring(
                  size: 84,
                  child: Icon(icon, size: 32, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
