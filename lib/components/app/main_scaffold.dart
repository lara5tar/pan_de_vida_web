import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../views/inventory_view.dart';
import '../../views/sale/add_sale_view.dart';
import '../../views/sales_view.dart';
import 'sidebar_menu.dart'; // Cambiamos app_drawer.dart por sidebar_menu.dart

/// Componente principal que contiene el scaffold básico para todas las vistas.
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0; // 0 = Inventario

  // Lista de las vistas disponibles para navegar
  final List<Widget> _pages = [
    const InventoryView(),
    const SalesView(),
    const AddSaleView(), // Agregar AddSaleView a la lista
  ];

  @override
  void initState() {
    super.initState();
    // Determinar el índice inicial basado en el widget hijo
    if (widget.child is SalesView) {
      _selectedIndex = 1;
    } else if (widget.child is AddSaleView) {
      _selectedIndex = 2; // Actualizar el índice para AddSaleView
    }
  }

  /// Actualiza el índice seleccionado
  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Navega a una vista específica
  void _navigateToView(int index) {
    if (index < _pages.length) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainScaffold(child: _pages[index]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reducir el ancho del sidebar a la mitad (de 20% a 10%)
    final double sidebarWidth = MediaQuery.of(context).size.width * 0.1;

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text(
      //     'Pan de Vida',
      //     style: TextStyle(fontWeight: FontWeight.bold),
      //   ),
      //   actions: [_buildLogoutButton(context)],
      // ),
      // Ya no usamos drawer, ahora el body es un Row con sidebar y contenido
      body: Row(
        children: [
          // Sidebar menu a la izquierda
          SizedBox(
            width: sidebarWidth,
            child: SidebarMenu(
              currentPage: widget.child,
              onNavigate: _navigateToView,
              selectedIndex: _selectedIndex,
            ),
          ),
          // Línea divisoria vertical
          const VerticalDivider(width: 1, thickness: 1),
          // Contenido principal a la derecha
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  /// Construye el botón de cerrar sesión
  Widget _buildLogoutButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Cerrar Sesión',
      onPressed: () {
        // Mostrar un diálogo de confirmación
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Cerrar Sesión'),
              content: const Text('¿Estás seguro que deseas cerrar sesión?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar el diálogo
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    // Cerrar el diálogo
                    Navigator.of(context).pop();
                    // Cerrar sesión
                    Provider.of<AuthService>(context, listen: false).logout();
                  },
                  child: const Text('Cerrar Sesión'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
