// filepath: /home/lara5tar/Escritorio/pan_de_vida_web/lib/components/app/sidebar_menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'drawer_item.dart';
import '../../views/inventory_view.dart';
import '../../views/sales_view.dart';

/// Componente que representa el menú lateral fijo de la aplicación.
class SidebarMenu extends StatelessWidget {
  final Widget currentPage;
  final Function(int) onNavigate;
  final int selectedIndex;

  const SidebarMenu({
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

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      child: Column(
        children: [
          _buildSidebarHeader(context),
          const Divider(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerItem(
                  icon: Icons.inventory,
                  title: 'Inventario',
                  isSelected: isInventoryView,
                  onTap: () => onNavigate(0),
                ),
                DrawerItem(
                  icon: Icons.attach_money,
                  title: 'Ventas',
                  isSelected: isSalesView,
                  onTap: () => onNavigate(1),
                ),
                DrawerItem(
                  icon: Icons.shopping_cart,
                  title: 'Nueva Venta',
                  isSelected: selectedIndex == 2,
                  onTap: () => onNavigate(2),
                ),
                DrawerItem(
                  icon: Icons.people,
                  title: 'Clientes',
                  isSelected: selectedIndex == 3,
                  onTap: () => onNavigate(3),
                ),
                DrawerItem(
                  icon: Icons.assessment,
                  title: 'Reportes',
                  isSelected: selectedIndex == 4,
                  onTap: () => onNavigate(4),
                ),
                const Divider(),
                DrawerItem(
                  icon: Icons.settings,
                  title: 'Configuración',
                  isSelected: selectedIndex == 5,
                  onTap: () => onNavigate(5),
                ),
              ],
            ),
          ),
          _buildUserInfo(context),
        ],
      ),
    );
  }

  /// Construye el encabezado del sidebar con logo y título
  Widget _buildSidebarHeader(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navegar a la vista de bienvenida al hacer clic en el logo
        Navigator.pushReplacementNamed(context, '/');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        // decoration: BoxDecoration(color: Theme.of(context).primaryColor),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Image.asset(
                  'assets/pandevida_logo.png',
                  height: 150,
                  // Ya no usamos el icono de libro como fallback, en su lugar mostramos
                  // un contenedor con el nombre cuando la imagen no carga
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'PdV',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el área de información del usuario en la parte inferior del sidebar
  Widget _buildUserInfo(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                            overflow: TextOverflow.ellipsis,
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
                    size: 16,
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
