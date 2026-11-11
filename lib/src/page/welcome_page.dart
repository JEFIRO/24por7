import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/navigation/welcome_state.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_entrance.dart';
import '../../core/widgets/brand_backdrop.dart';
import '../../core/widgets/brand_logo.dart';

/// Boas-vindas da primeira abertura: a marca, uma frase e a entrada.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const _white = Color(0xFFFFFFFF);

  // A gravação segue em segundo plano: a navegação não espera o disco.
  void _enter(BuildContext context) {
    WelcomeState.markSeen();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _newCompany(BuildContext context) {
    WelcomeState.markSeen();
    Navigator.pushNamed(context, AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: BrandBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    const AppEntrance(
                      child: Center(
                        child: BrandLogo(
                          size: 150,
                          animated: true,
                          cycles: 2,
                          showWordmark: true,
                          onDark: true,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AppEntrance(
                      index: 2,
                      child: Text(
                        'Seus mercados',
                        textAlign: TextAlign.center,
                        style: text.displaySmall?.copyWith(
                          color: _white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1.05,
                        ),
                      ),
                    ),
                    AppEntrance(
                      index: 3,
                      child: Text(
                        'sempre abertos',
                        textAlign: TextAlign.center,
                        style: text.displaySmall?.copyWith(
                          color: _white,
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -1,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    AppEntrance(
                      index: 5,
                      child: FilledButton(
                        key: const Key('welcome-enter'),
                        onPressed: () => _enter(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: _white,
                          foregroundColor: BrandBackdrop.deep,
                          minimumSize: const Size.fromHeight(56),
                          shape: const StadiumBorder(),
                          textStyle: text.titleMedium,
                        ),
                        child: const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppEntrance(
                      index: 6,
                      child: TextButton(
                        onPressed: () => _newCompany(context),
                        style: TextButton.styleFrom(foregroundColor: _white),
                        child: const Text.rich(
                          TextSpan(
                            text: 'Empresa nova? ',
                            style: TextStyle(fontWeight: FontWeight.w400),
                            children: [
                              TextSpan(
                                text: 'Configurar',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
