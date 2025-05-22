import 'package:flutter/material.dart';

class SearchAndFiltersBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool showLowStock;
  final Function(bool) onLowStockToggle;
  final VoidCallback onAddBook;
  final VoidCallback onShowFilters;
  final VoidCallback onClearSearch;
  final String sortCriteria;
  final bool isAscending;
  final Function(String) onSortCriteriaChange;
  final VoidCallback onToggleSortDirection;
  final int filteredCount;
  final int totalCount;

  const SearchAndFiltersBar({
    super.key,
    required this.searchController,
    required this.showLowStock,
    required this.onLowStockToggle,
    required this.onAddBook,
    required this.onShowFilters,
    required this.onClearSearch,
    required this.sortCriteria,
    required this.isAscending,
    required this.onSortCriteriaChange,
    required this.onToggleSortDirection,
    required this.filteredCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Buscador
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar libros',
                    hintText: 'Nombre o código de barras',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon:
                        searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: onClearSearch,
                            )
                            : null,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Botón para agregar libro
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'AGREGAR LIBRO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: onAddBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Botón para filtros adicionales
              ElevatedButton.icon(
                icon: const Icon(Icons.filter_list),
                label: const Text(
                  'FILTROS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: onShowFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Filtro rápido de stock bajo
              FilterChip(
                label: const Text('Stock bajo'),
                selected: showLowStock,
                onSelected: onLowStockToggle,
                avatar: showLowStock ? const Icon(Icons.check, size: 18) : null,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Información de resultados y opciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mostrando $filteredCount de $totalCount libros',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Text('Ordenar por:'),
                  const SizedBox(width: 8),
                  _buildSortDropdown(),
                  IconButton(
                    icon: Icon(
                      isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                    onPressed: onToggleSortDirection,
                    tooltip:
                        isAscending ? 'Orden ascendente' : 'Orden descendente',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButton<String>(
      value: sortCriteria,
      items: const [
        DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
        DropdownMenuItem(value: 'precio', child: Text('Precio')),
        DropdownMenuItem(value: 'stock', child: Text('Stock')),
        DropdownMenuItem(value: 'codigo', child: Text('Código')),
      ],
      onChanged: (value) {
        if (value != null) {
          onSortCriteriaChange(value);
        }
      },
    );
  }
}
