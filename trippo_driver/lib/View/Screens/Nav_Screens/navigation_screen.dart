import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homzy_provider/View/Screens/Main_Screens/Dashboard/provider_dashboard_screen.dart';
import 'package:homzy_provider/View/Screens/Main_Screens/Earnings/provider_earnings_screen.dart';
import 'package:homzy_provider/View/Screens/Main_Screens/Profile_Screen/profile_screen.dart';
import 'package:homzy_provider/View/Screens/Nav_Screens/navigation_providers.dart';



class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  List<Widget> screens = [
    const ProviderDashboardScreen(),
    const ProviderEarningsScreen(),
    const ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          body: screens[ref.watch(navigationStateProvider)],
          bottomNavigationBar: NavigationBar(
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.work_outline),
                label: "Jobs",
                selectedIcon: Icon(Icons.work),
              ),
              NavigationDestination(
                icon: Icon(Icons.attach_money_outlined),
                label: "Earnings",
                selectedIcon: Icon(Icons.attach_money),
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: "Profile",
                selectedIcon: Icon(Icons.person),
              )
            ],
            onDestinationSelected: (int selection) {
              ref
                  .watch(navigationStateProvider.notifier)
                  .update((state) => selection);
            },
            backgroundColor: const Color(0xFF1E1E1E),
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            selectedIndex: ref.watch(navigationStateProvider),
          ),
        );
      },
    );
  }
}
