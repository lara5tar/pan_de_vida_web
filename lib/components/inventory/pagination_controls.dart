import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final Function(int) onPageChange;
  final Function(int) onRowsPerPageChange;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.rowsPerPage,
    required this.rowsPerPageOptions,
    required this.onPageChange,
    required this.onRowsPerPageChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Filas por página
          Row(
            children: [
              const Text('Filas por página: '),
              DropdownButton<int>(
                value: rowsPerPage,
                items:
                    rowsPerPageOptions
                        .map(
                          (count) => DropdownMenuItem(
                            value: count,
                            child: Text('$count'),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onRowsPerPageChange(value);
                  }
                },
              ),
            ],
          ),

          // Información de página
          Text('${currentPage + 1} de $pageCount'),

          // Controles de navegación
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: currentPage > 0 ? () => onPageChange(0) : null,
                tooltip: 'Primera página',
              ),
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed:
                    currentPage > 0
                        ? () => onPageChange(currentPage - 1)
                        : null,
                tooltip: 'Página anterior',
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed:
                    currentPage < pageCount - 1
                        ? () => onPageChange(currentPage + 1)
                        : null,
                tooltip: 'Página siguiente',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed:
                    currentPage < pageCount - 1
                        ? () => onPageChange(pageCount - 1)
                        : null,
                tooltip: 'Última página',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
