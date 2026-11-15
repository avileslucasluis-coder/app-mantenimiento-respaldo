import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;
  static const paths = [
    '/productos',
    '/equipos',
    '/mantenimientos',
    '/movimientos',
  ];
  static const labels = ['Inventario', 'Equipos', 'Órdenes', 'Actividad'];
  static const icons = [
    Icons.inventory_2_outlined,
    Icons.precision_manufacturing_outlined,
    Icons.build_outlined,
    Icons.swap_vert,
  ];
  @override
  Widget build(BuildContext context) {
    final found = paths.indexWhere((p) => location.startsWith(p));
    final index = found < 0 ? 0 : found;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        return Scaffold(
          body: Row(
            children: [
              if (wide) ...[
                NavigationRail(
                  extended: constraints.maxWidth >= 1100,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
                    child: Icon(
                      Icons.handyman,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  selectedIndex: index,
                  onDestinationSelected: (i) => context.go(paths[i]),
                  destinations: List.generate(
                    paths.length,
                    (i) => NavigationRailDestination(
                      icon: Icon(icons[i]),
                      label: Text(labels[i]),
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.xl),
                        child: IconButton(
                          tooltip: 'Mi perfil',
                          onPressed: () => context.go('/perfil'),
                          icon: const Icon(Icons.account_circle_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: child),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (i) => context.go(paths[i]),
                  destinations: List.generate(
                    paths.length,
                    (i) => NavigationDestination(
                      icon: Icon(icons[i]),
                      label: labels[i],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
