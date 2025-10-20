// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i3;
import 'package:forma_flutter/ui/gemini_setup_screen.dart' as _i1;
import 'package:forma_flutter/ui/welcome_screen.dart' as _i2;

/// generated route for
/// [_i1.GeminiSetupScreen]
class GeminiSetupRoute extends _i3.PageRouteInfo<void> {
  const GeminiSetupRoute({List<_i3.PageRouteInfo>? children})
    : super(GeminiSetupRoute.name, initialChildren: children);

  static const String name = 'GeminiSetupRoute';

  static _i3.PageInfo page = _i3.PageInfo(
    name,
    builder: (data) {
      return const _i1.GeminiSetupScreen();
    },
  );
}

/// generated route for
/// [_i2.WelcomeScreen]
class WelcomeRoute extends _i3.PageRouteInfo<void> {
  const WelcomeRoute({List<_i3.PageRouteInfo>? children})
    : super(WelcomeRoute.name, initialChildren: children);

  static const String name = 'WelcomeRoute';

  static _i3.PageInfo page = _i3.PageInfo(
    name,
    builder: (data) {
      return const _i2.WelcomeScreen();
    },
  );
}
