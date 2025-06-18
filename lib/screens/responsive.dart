import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Breakpoints
  static const double wearBreakpoint = 300;
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isWearScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < wearBreakpoint;
  }

  static bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= wearBreakpoint && width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    double wearSize = 12,
    double mobileSize = 16,
    double tabletSize = 18,
  }) {
    if (isWearScreen(context)) return wearSize;
    if (isTablet(context)) return tabletSize;
    return mobileSize;
  }

  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    EdgeInsets? wearPadding,
    EdgeInsets? mobilePadding,
    EdgeInsets? tabletPadding,
  }) {
    if (isWearScreen(context)) {
      return wearPadding ?? const EdgeInsets.all(4.0);
    }
    if (isTablet(context)) {
      return tabletPadding ?? const EdgeInsets.all(24.0);
    }
    return mobilePadding ?? const EdgeInsets.all(16.0);
  }

  static double getResponsiveIconSize(
    BuildContext context, {
    double wearSize = 16,
    double mobileSize = 24,
    double tabletSize = 32,
  }) {
    if (isWearScreen(context)) return wearSize;
    if (isTablet(context)) return tabletSize;
    return mobileSize;
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget? wearWidget;
  final Widget? mobileWidget;
  final Widget? tabletWidget;
  final Widget fallbackWidget;

  const ResponsiveWidget({
    super.key,
    this.wearWidget,
    this.mobileWidget,
    this.tabletWidget,
    required this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isWearScreen(context) && wearWidget != null) {
      return wearWidget!;
    } else if (ResponsiveHelper.isTablet(context) && tabletWidget != null) {
      return tabletWidget!;
    } else if (ResponsiveHelper.isMobile(context) && mobileWidget != null) {
      return mobileWidget!;
    }
    return fallbackWidget;
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final double? wearSize;
  final double? mobileSize;
  final double? tabletSize;

  const ResponsiveText(
    this.text, {
    super.key,
    this.baseStyle,
    this.wearSize,
    this.mobileSize,
    this.tabletSize,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      wearSize: wearSize ?? 12,
      mobileSize: mobileSize ?? 16,
      tabletSize: tabletSize ?? 18,
    );

    return Text(
      text,
      style: (baseStyle ?? const TextStyle()).copyWith(
        fontSize: responsiveSize,
      ),
    );
  }
}

// Extensión para hacer más fácil el uso de responsividad
extension ResponsiveContext on BuildContext {
  bool get isWear => ResponsiveHelper.isWearScreen(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isMobile => ResponsiveHelper.isMobile(this);

  double responsiveFontSize({
    double wearSize = 12,
    double mobileSize = 16,
    double tabletSize = 18,
  }) => ResponsiveHelper.getResponsiveFontSize(
    this,
    wearSize: wearSize,
    mobileSize: mobileSize,
    tabletSize: tabletSize,
  );
}
