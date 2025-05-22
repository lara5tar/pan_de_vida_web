import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../views/inventory_view.dart';
import '../../views/sales_view.dart';
import 'app_drawer.dart';

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
  final List<Widget> _pages = [const InventoryView(), const SalesView()];

  @override
  void initState() {
    super.initState();
    // Determinar el índice inicial basado en el widget hijo
    if (widget.child is SalesView) {
      _selectedIndex = 1;
    }
  }

  /// Actualiza el índice seleccionado y cierra el drawer
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pan de Vida',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [_buildLogoutButton(context)],
      ),
      drawer: AppDrawer(
        currentPage: widget.child,
        onNavigate: _navigateToView,
        selectedIndex: _selectedIndex,
      ),
      body: widget.child,
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
