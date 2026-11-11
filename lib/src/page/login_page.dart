import 'package:flutter/material.dart';

import '../../core/theme/app_brand.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_entrance.dart';
import '../../core/widgets/brand_logo.dart';
import '../model/api_client.dart';
import '../model/empresa_branding.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.intendedRoute = '/dashboard'});
  final String intendedRoute;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _cpf = TextEditingController();
  final _senha = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _cpf.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.instance.loginAdmin(
        _cpf.text.replaceAll(RegExp(r'\D'), ''),
        _senha.text,
      );
      await loadBranding();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(widget.intendedRoute);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget form({required bool showLogo}) => Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Em telas largas a marca já está no painel ao lado.
                if (showLogo) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppEntrance(
                      child: BrandLogo(size: 120, animated: true, cycles: 2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(
                  'Entrar no painel',
                  style: AppBrand.display(
                    Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Use o CPF e a senha do gestor da Empresa.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _cpf,
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Informe o CPF' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _senha,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe a senha' : null,
                  onFieldSubmitted: (_) => _login(),
                ),
                AppReveal(
                  child: _error == null
                      ? null
                      : Padding(
                          key: ValueKey(_error),
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: _loading ? null : _login,
                  icon: AppBusyIcon(busy: _loading, icon: Icons.login),
                  label: Text(_loading ? 'Entrando…' : 'Entrar'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.pushNamed(context, '/onboarding'),
                  child: const Text('Configurar nova empresa'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < AppBreakpoints.desktop) {
              return form(showLogo: true);
            }
            return Row(
              children: [
                const Expanded(child: _BrandPanel()),
                Expanded(child: form(showLogo: false)),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Metade de marca do login em telas largas: logo, nome e o que o painel faz.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.section + AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppEntrance(
              child: BrandLogo(
                size: 220,
                animated: true,
                cycles: 2,
                showWordmark: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppEntrance(
              index: 2,
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppBrand.orangeSweep),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppEntrance(
              index: 3,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Text(
                  'Mercados autônomos dos seus Condomínios: Terminais, catálogo, estoque e pagamentos. Abertos 24 horas, 7 dias por semana.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
