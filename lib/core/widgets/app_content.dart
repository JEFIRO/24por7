import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

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
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AppSpacing.lg,
    runSpacing: AppSpacing.md,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      if (actions.isNotEmpty)
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: actions,
        ),
    ],
  );
}
