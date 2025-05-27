import 'package:flutter/material.dart';

/// Componente que representa un ítem del menú lateral.
class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true, // Hace que el ListTile sea más compacto
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12.0,
      ), // Padding reducido
      leading: Icon(
        icon,
        size: 20, // Tamaño de icono más pequeño
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14, // Tamaño de texto más pequeño
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyLarge?.color,
        ),
        overflow: TextOverflow.ellipsis, // Evita que el texto se desborde
      ),
      tileColor:
          isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
      onTap: onTap,
    );
  }
}
