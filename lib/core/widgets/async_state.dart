import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({this.label = 'Carregando informações…', super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(label),
        ],
      ),
    ),
  );
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
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _StatePanel(
    icon: Icons.cloud_off_outlined,
    title: 'Não foi possível carregar os dados',
    message: message,
    action: FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
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
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    ),
  );
}
