import 'package:flutter/material.dart';

@immutable
class BrandingConfig {
  const BrandingConfig({
    this.displayName = 'App 24/7',
    this.primaryColor = const Color(0xFF155EEF),
    this.secondaryColor = const Color(0xFF0E9384),
    this.logoUrl,
    this.compactLogoUrl,
  });

  final String displayName;
  final Color primaryColor;
  final Color secondaryColor;
  final String? logoUrl;
  final String? compactLogoUrl;

  static const fallback = BrandingConfig();

  BrandingConfig copyWith({
    String? displayName,
    Color? primaryColor,
    Color? secondaryColor,
    String? logoUrl,
    String? compactLogoUrl,
  }) => BrandingConfig(
    displayName: displayName ?? this.displayName,
    primaryColor: primaryColor ?? this.primaryColor,
    secondaryColor: secondaryColor ?? this.secondaryColor,
    logoUrl: logoUrl ?? this.logoUrl,
    compactLogoUrl: compactLogoUrl ?? this.compactLogoUrl,
  );
}

class BrandingScope extends InheritedWidget {
  const BrandingScope({
    required this.branding,
    required super.child,
    super.key,
  });

  final BrandingConfig branding;

  static BrandingConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BrandingScope>()?.branding ??
      BrandingConfig.fallback;

  @override
  bool updateShouldNotify(BrandingScope oldWidget) =>
      oldWidget.branding != branding;
}
