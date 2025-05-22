import 'package:flutter/material.dart';

class StatsPanel extends StatelessWidget {
  final int totalBooks;
  final int lowStockCount;
  final double inventoryValue;

  const StatsPanel({
    super.key,
    required this.totalBooks,
    required this.lowStockCount,
    required this.inventoryValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'Total de Libros',
            totalBooks.toString(),
            Icons.menu_book,
            Colors.blue,
            context,
          ),
          _buildStatCard(
            'Libros con Stock Bajo',
            lowStockCount.toString(),
            Icons.warning_amber_rounded,
            Colors.orange,
            context,
          ),
          _buildStatCard(
            'Valor del Inventario',
            '\$${inventoryValue.toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.green,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
