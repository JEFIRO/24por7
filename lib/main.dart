import 'package:app_24por7/core/navigation/app_routes.dart';
import 'package:app_24por7/core/theme/app_theme.dart';
import 'package:app_24por7/core/theme/branding_config.dart';
import 'package:app_24por7/src/model/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await initializeDateFormatting('pt_BR');
  ApiClient.instance.onUnauthorized = () {
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const branding = BrandingConfig.fallback;
    return BrandingScope(
      branding: branding,
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: branding.displayName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(branding),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
