import 'package:flutter/widgets.dart';

abstract final class AppBreakpoints {
  static const double mobile = 600;
  static const double desktop = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 40;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double pill = 999;
}

abstract final class AppLayout {
  static const double contentMaxWidth = 1440;
  static const double formMaxWidth = 760;
  static const double sidebarWidth = 260;
  static const double railWidth = 88;
}
