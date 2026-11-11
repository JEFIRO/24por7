import 'package:app_24por7/core/navigation/app_routes.dart';
import 'package:app_24por7/core/theme/app_motion.dart';
import 'package:app_24por7/core/theme/app_theme.dart';
import 'package:app_24por7/core/theme/branding_config.dart';
import 'package:app_24por7/core/widgets/brand_logo.dart';
import 'package:app_24por7/src/model/api_client.dart';
import 'package:app_24por7/src/model/empresa_branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Continua o splash nativo, com o logo parado, enquanto a inicialização
  // ocupa a thread de interface: girar aqui sairia travado.
  runApp(const _Splash(spin: false));
  await dotenv.load(fileName: '.env', isOptional: true);
  tz.initializeTimeZones();
  await initializeDateFormatting('pt_BR');
  await ApiClient.instance.restoreSession();
  // Não bloqueia a abertura: o tema atualiza quando o branding chegar.
  loadBranding();
  ApiClient.instance.onUnauthorized = () {
    resetBranding();
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  };
  // Com tudo pronto, as setas dão uma volta inteira, sem engasgos, e param
  // na pose do logo antes de o painel entrar.
  runApp(const _Splash(spin: true));
  await Future<void>.delayed(AppMotion.splashMin);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<BrandingConfig>(
    valueListenable: brandingNotifier,
    builder: (context, branding, _) => BrandingScope(
      branding: branding,
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: branding.displayName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    ),
  );
}

class _Splash extends StatelessWidget {
  const _Splash({required this.spin});
  final bool spin;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      color: AppTheme.background,
      child: Center(
        child: BrandLogo(
          size: 160,
          animated: spin,
          cycles: 1,
          turnDuration: AppMotion.splashMin,
        ),
      ),
    ),
  );
}
