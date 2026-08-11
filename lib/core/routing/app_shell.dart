import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_almacen_plus/core/theme/app_theme.dart';

/// Shell scaffold with bottom navigation (DESING.MD: 84px bottom nav, large
/// touch targets). Hosts the Dashboard, Products, Movements and Profile
/// branches.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 15,
              offset: Offset(0, -4),
              color: Color(0x0D000000),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.borderRadiusMd),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Productos',
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_vert_outlined),
                selectedIcon: Icon(Icons.swap_vert),
                label: 'Movimientos',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
