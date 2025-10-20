import 'package:auto_route/auto_route.dart';

import 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {

  @override
  List<AutoRoute> get routes => [
    /// routes go here
    AutoRoute(page: WelcomeRoute.page, initial: true),
  ];
}