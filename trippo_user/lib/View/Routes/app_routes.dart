import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homzy_user/View/Routes/routes.dart';
import 'package:homzy_user/View/Screens/Auth_Screens/Login_Screen/login_screen.dart';
import 'package:homzy_user/View/Screens/Auth_Screens/Register_Screen/register_screen.dart';
import 'package:homzy_user/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:homzy_user/View/Screens/Main_Screens/Chat_Screen/chat_screen.dart';
import 'package:homzy_user/View/Screens/Main_Screens/Service_Dashboard/service_dashboard_screen.dart';
import 'package:homzy_user/View/Screens/Main_Screens/Tracking_Map/tracking_map_screen.dart';
import 'package:homzy_user/View/Screens/Main_Screens/Quote_Approval/quote_approval_screen.dart';
import 'package:homzy_user/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:homzy_user/View/Screens/Admin_Screens/Admin_Dashboard/admin_dashboard_screen.dart';
import 'package:homzy_user/View/Screens/Admin_Screens/Provider_Applications/provider_applications_screen.dart';
import 'package:homzy_user/View/Screens/Admin_Screens/Provider_Applications/application_detail_screen.dart';
import 'package:homzy_user/View/Screens/Admin_Screens/Admin_Settings/admin_settings_screen.dart';

import 'package:homzy_user/View/Screens/Other_Screens/Splash_Screen/splash_screen.dart';

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
    // Main Routes - Chat is now the primary home screen
    GoRoute(
      name: Routes().chat,
      path: '/${Routes().chat}',
      builder: (BuildContext context, GoRouterState state) {
        return const ChatScreen();
      },
    ),

    // Legacy home route (map-based) - kept for backwards compatibility
    GoRoute(
      name: Routes().home,
      path: '/${Routes().home}',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),

    // Service Management Routes
    GoRoute(
      name: Routes().serviceDashboard,
      path: '/${Routes().serviceDashboard}',
      builder: (BuildContext context, GoRouterState state) {
        return const ServiceDashboardScreen();
      },
    ),

    GoRoute(
      name: Routes().trackingMap,
      path: '/${Routes().trackingMap}',
      builder: (BuildContext context, GoRouterState state) {
        final requestId = state.extra as String;
        return TrackingMapScreen(serviceRequestId: requestId);
      },
    ),

    GoRoute(
      name: Routes().quoteApproval,
      path: '/${Routes().quoteApproval}',
      builder: (BuildContext context, GoRouterState state) {
        final requestId = state.extra as String;
        return QuoteApprovalScreen(serviceRequestId: requestId);
      },
    ),

  // Main Sub Routes
 GoRoute(

      name: Routes().whereTo,
      path: '/${Routes().whereTo}',

      builder: (BuildContext context, GoRouterState state) {

        return  WhereToScreen( controller:state.extra as GoogleMapController ,);
      },
    ),

    // Admin Routes
    GoRoute(
      name: Routes().adminDashboard,
      path: '/${Routes().adminDashboard}',
      builder: (BuildContext context, GoRouterState state) {
        return const AdminDashboardScreen();
      },
    ),

    GoRoute(
      name: Routes().adminApplications,
      path: '/${Routes().adminApplications}',
      builder: (BuildContext context, GoRouterState state) {
        return const ProviderApplicationsScreen();
      },
    ),

    GoRoute(
      name: Routes().adminApplicationDetail,
      path: '/${Routes().adminApplicationDetail}',
      builder: (BuildContext context, GoRouterState state) {
        final applicationId = state.extra as String;
        return ApplicationDetailScreen(applicationId: applicationId);
      },
    ),

    GoRoute(
      name: Routes().adminSettings,
      path: '/${Routes().adminSettings}',
      builder: (BuildContext context, GoRouterState state) {
        return const AdminSettingsScreen();
      },
    ),


  ];

