import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'drawer_item.dart';
import '../../views/inventory_view.dart';
import '../../views/sales_view.dart';

/// Componente que representa el menú lateral de la aplicación.
class AppDrawer extends StatelessWidget {
  final Widget currentPage;
  final Function(int) onNavigate;
  final int selectedIndex;

  const AppDrawer({
    super.key,
    required this.currentPage,
    required this.onNavigate,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Determinar qué vista está activa
    bool isInventoryView = currentPage is InventoryView;
    bool isSalesView = currentPage is SalesView;

    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerItem(
                  icon: Icons.inventory,
                  title: 'Inventario',
                  isSelected: isInventoryView,
                  onTap: () {
                    if (!isInventoryView) {
                      onNavigate(0);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                DrawerItem(
                  icon: Icons.attach_money,
                  title: 'Ventas',
                  isSelected: isSalesView,
                  onTap: () {
                    if (!isSalesView) {
                      onNavigate(1);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                DrawerItem(
                  icon: Icons.shopping_cart,
                  title: 'Nueva Venta',
                  isSelected: selectedIndex == 2,
                  onTap: () {
                    // Cierra el drawer y navega a la vista
                    Navigator.pop(context);
                    // Aquí irá la navegación a la vista de nueva venta
                    // Por ahora solo marcamos la opción como seleccionada
                    onNavigate(2);
                  },
                ),
                DrawerItem(
                  icon: Icons.people,
                  title: 'Clientes',
                  isSelected: selectedIndex == 3,
                  onTap: () {
                    // Cierra el drawer y navega a la vista
                    Navigator.pop(context);
                    // Aquí irá la navegación a la vista de clientes
                    onNavigate(3);
                  },
                ),
                DrawerItem(
                  icon: Icons.assessment,
                  title: 'Reportes',
                  isSelected: selectedIndex == 4,
                  onTap: () {
                    // Cierra el drawer y navega a la vista
                    Navigator.pop(context);
                    // Aquí irá la navegación a la vista de reportes
                    onNavigate(4);
                  },
                ),
                const Divider(),
                DrawerItem(
                  icon: Icons.settings,
                  title: 'Configuración',
                  isSelected: selectedIndex == 5,
                  onTap: () {
                    // Cierra el drawer y navega a la vista
                    Navigator.pop(context);
                    // Aquí irá la navegación a la vista de configuración
                    onNavigate(5);
                  },
                ),
              ],
            ),
          ),
          _buildUserInfo(context),
        ],
      ),
    );
  }

  /// Construye el encabezado del drawer con logo y título
  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(color: Theme.of(context).primaryColor),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 80,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(
                    Icons.menu_book,
                    size: 80,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pan de Vida',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el área de información del usuario en la parte inferior del drawer
  Widget _buildUserInfo(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (authService.currentUser != null) ...[
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        authService.currentUser!.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authService.currentUser!.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            authService.currentUser!.role == 'admin'
                                ? 'Administrador'
                                : 'Empleado',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pan de Vida v1.0',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
