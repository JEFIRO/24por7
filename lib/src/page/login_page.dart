import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/branding_config.dart';
import '../model/api_client.dart';

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
    final brand = BrandingScope.of(context);
    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      child: Text(brand.displayName.characters.first),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        brand.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Bem-vindo',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Acesse o painel administrativo da sua operação.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _cpf,
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Informe o CPF' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _senha,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe a senha' : null,
                  onFieldSubmitted: (_) => _login(),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
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
            if (constraints.maxWidth < AppBreakpoints.desktop) return form;
            return Row(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(64),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 72,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Operação clara,\ndo estoque ao Terminal.',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Gerencie mercados autônomos, acompanhe equipamentos e tome decisões em um único painel.',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: form),
              ],
            );
          },
        ),
      ),
    );
  }
}
