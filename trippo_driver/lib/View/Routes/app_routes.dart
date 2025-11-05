import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homzy_provider/View/Routes/routes.dart';
import 'package:homzy_provider/View/Screens/Auth_Screens/Driver_config/driver_config.dart';
import 'package:homzy_provider/View/Screens/Auth_Screens/Login_Screen/login_screen.dart';
import 'package:homzy_provider/View/Screens/Auth_Screens/Register_Screen/register_screen.dart';
import 'package:homzy_provider/View/Screens/Nav_Screens/navigation_screen.dart';
import 'package:homzy_provider/View/Screens/Other_Screens/Splash_Screen/splash_screen.dart';
import 'package:homzy_provider/View/Screens/Main_Screens/Dashboard/provider_dashboard_screen.dart';
import 'package:homzy_provider/View/Screens/Main_Screens/Job_Detail/job_detail_screen.dart';
import 'package:homzy_provider/View/Screens/Main_Screens/Active_Job/active_job_screen.dart';
import 'package:homzy_provider/View/Screens/Main_Screens/Quote/quote_builder_screen.dart';
import 'package:homzy_provider/View/Screens/Main_Screens/Earnings/provider_earnings_screen.dart';


final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');



final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/${Routes().splash}',
  routes:allRoutes
);


final List<RouteBase> allRoutes =[

  // Other Screen Routes

    GoRoute(
      name: Routes().splash,
      path: '/${Routes().splash}',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),

    // Auth Routes
    GoRoute(
      name: Routes().login,
      path: '/${Routes().login}',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      name: Routes().register,
      path: '/${Routes().register}',
      builder: (BuildContext context, GoRouterState state) {
        return const RegisterScreen();
      },
    ),
    GoRoute(
      name: Routes().driverConfig,
      path: '/${Routes().driverConfig}',
      builder: (BuildContext context, GoRouterState state) {
        return const DriverConfigsScreen();
      },
    ),
    GoRoute(
      name: Routes().navigationScreen,
      path: '/${Routes().navigationScreen}',
      builder: (BuildContext context, GoRouterState state) {
        return const NavigationScreen();
      },
    ),

    // Main Routes
    GoRoute(
      name: Routes().dashboard,
      path: '/${Routes().dashboard}',
      builder: (BuildContext context, GoRouterState state) {
        return const ProviderDashboardScreen();
      },
    ),
    GoRoute(
      name: Routes().jobDetail,
      path: '/${Routes().jobDetail}',
      builder: (BuildContext context, GoRouterState state) {
        final serviceRequestId = state.extra as String;
        return JobDetailScreen(serviceRequestId: serviceRequestId);
      },
    ),
    GoRoute(
      name: Routes().activeJob,
      path: '/${Routes().activeJob}',
      builder: (BuildContext context, GoRouterState state) {
        final serviceRequestId = state.extra as String;
        return ActiveJobScreen(serviceRequestId: serviceRequestId);
      },
    ),
    GoRoute(
      name: Routes().quoteBuilder,
      path: '/${Routes().quoteBuilder}',
      builder: (BuildContext context, GoRouterState state) {
        final serviceRequestId = state.extra as String;
        return QuoteBuilderScreen(serviceRequestId: serviceRequestId);
      },
    ),
    GoRoute(
      name: Routes().providerEarnings,
      path: '/${Routes().providerEarnings}',
      builder: (BuildContext context, GoRouterState state) {
        return const ProviderEarningsScreen();
      },
    ),
  ];

