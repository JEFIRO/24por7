import 'package:flutter/material.dart';

import 'app_brand.dart';

/// O que cada Empresa personaliza: nome e logo. Cores são da marca.
@immutable
class BrandingConfig {
  const BrandingConfig({
    this.displayName = AppBrand.name,
    this.logoUrl,
    this.compactLogoUrl,
  });

  final String displayName;
  final String? logoUrl;
  final String? compactLogoUrl;

  static const fallback = BrandingConfig();

  BrandingConfig copyWith({
    String? displayName,
    String? logoUrl,
    String? compactLogoUrl,
  }) => BrandingConfig(
    displayName: displayName ?? this.displayName,
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
