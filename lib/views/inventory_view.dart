import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../controllers/inventory_controller.dart';
import 'add_book_view.dart';
import '../components/inventory/stats_panel.dart';
import '../components/inventory/search_filters_bar.dart';
import '../components/inventory/inventory_table.dart';
import '../components/inventory/pagination_controls.dart';
import '../components/inventory/action_buttons_bar.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  _InventoryViewState createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final TextEditingController _searchController = TextEditingController();
  final InventoryController _controller = InventoryController();

  @override
  void initState() {
    super.initState();
    _controller.loadBooks(setState);

    _searchController.addListener(() {
      _controller.filterBooks(_searchController.text);
      _controller.currentPage = 0; // Volver a la primera página al buscar
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    double minPrice = _controller.minPrice;
    double maxPrice =
        _controller.maxPrice == double.infinity ? 1000 : _controller.maxPrice;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Filtros avanzados'),
                content: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filtro por precio
                      const Text('Rango de precio:'),
                      RangeSlider(
                        values: RangeValues(minPrice, maxPrice),
                        min: 0,
                        max: 1000,
                        divisions: 100,
                        labels: RangeLabels(
                          '\$${minPrice.toStringAsFixed(2)}',
                          maxPrice >= 1000
                              ? '\$1000+'
                              : '\$${maxPrice.toStringAsFixed(2)}',
                        ),
                        onChanged: (values) {
                          setDialogState(() {
                            minPrice = values.start;
                            maxPrice = values.end;
                          });
                        },
                      ),

                      // Stock bajo
                      Row(
                        children: [
                          Checkbox(
                            value: _controller.showLowStock,
                            onChanged: (value) {
                              setDialogState(() {
                                _controller.showLowStock = value ?? false;
                              });
                            },
                          ),
                          const Text('Mostrar solo libros con stock bajo (<5)'),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('CANCELAR'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _controller.minPrice = minPrice;
                        _controller.maxPrice =
                            maxPrice >= 1000 ? double.infinity : maxPrice;
                        _controller.currentPage =
                            0; // Volver a la primera página
                        _controller.filterBooks(_searchController.text);
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('APLICAR'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showAddEditBookDialog({Book? book}) {
    // Navegar a la vista de agregar/editar libro
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddBookView(bookToEdit: book)),
    ).then((result) {
      // Si se agregó/editó correctamente, recargar los datos
      if (result == true) {
        _controller.loadBooks(setState);
      }
    });
  }

  void _confirmDeleteBook(Book book) {
    final BuildContext currentContext = context;

    showDialog(
      context: currentContext,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Estás seguro que deseas eliminar el libro "${book.nombre}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCELAR'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _controller.deleteBook(book, currentContext, setState);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('ELIMINAR'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventario de Libros',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Botones para guardar o cancelar cambios
          if (_controller.hasChanges)
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('GUARDAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 4,
                  ),
                  onPressed: () => _controller.saveChanges(context, setState),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('CANCELAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 4,
                  ),
                  onPressed: () => _controller.cancelChanges(setState),
                ),
                const SizedBox(width: 16),
              ],
            ),
        ],
      ),
      body:
          _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : _buildInventoryContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _controller.errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _controller.loadBooks(setState),
            child: const Text('Intentar nuevamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1000;

    // Envolvemos todo el contenido en un SingleChildScrollView
    // para que toda la página se desplace como una unidad
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLargeScreen)
            StatsPanel(
              totalBooks: _controller.totalBooks,
              lowStockCount: _controller.lowStockCount,
              inventoryValue: _controller.inventoryValue,
            ),

          ActionButtonsBar(
            onGenerateExcelReport:
                () => _controller.generateExcelReport(context, setState),
            onRefreshInventory: () => _controller.loadBooks(setState),
          ),

          SearchAndFiltersBar(
            searchController: _searchController,
            showLowStock: _controller.showLowStock,
            onLowStockToggle: (selected) {
              setState(() {
                _controller.showLowStock = selected;
                _controller.filterBooks(_searchController.text);
                _controller.currentPage = 0;
              });
            },
            onAddBook: () => _showAddEditBookDialog(),
            onShowFilters: _showFilterDialog,
            onClearSearch: () {
              _searchController.clear();
            },
            sortCriteria: _controller.sortCriteria,
            isAscending: _controller.isAscending,
            onSortCriteriaChange: (criteria) {
              _controller.changeSortCriteria(criteria, setState);
            },
            onToggleSortDirection: () {
              setState(() {
                _controller.isAscending = !_controller.isAscending;
                _controller.sortBooks();
              });
            },
            filteredCount: _controller.filteredBooks.length,
            totalCount: _controller.totalBooks,
          ),

          InventoryTable(
            books: _controller.getPaginatedBooks(),
            sortCriteria: _controller.sortCriteria,
            isAscending: _controller.isAscending,
            onSort:
                (criteria) =>
                    _controller.changeSortCriteria(criteria, setState),
            onStartEditingBook:
                (book) => _controller.startEditingBook(book, setState),
            onUpdateBook: (
              book, {
              nombre,
              codigoBarras,
              precio,
              cantidadEnStock,
            }) {
              _controller.updateEditedBook(
                book,
                nombre: nombre,
                codigoBarras: codigoBarras,
                precio: precio,
                cantidadEnStock: cantidadEnStock,
                setState: setState,
              );
            },
            onDeleteBook: _confirmDeleteBook,
            isEditing: (bookId) => _controller.isEditing(bookId),
            getBookToDisplay: (book) => _controller.getBookToDisplay(book),
          ),

          PaginationControls(
            currentPage: _controller.currentPage,
            pageCount: _controller.pageCount,
            rowsPerPage: _controller.rowsPerPage,
            rowsPerPageOptions: _controller.rowsPerPageOptions,
            onPageChange: (page) {
              setState(() {
                _controller.currentPage = page;
              });
            },
            onRowsPerPageChange: (value) {
              setState(() {
                _controller.rowsPerPage = value;
                _controller.currentPage = 0; // Volver a la primera página
              });
            },
          ),

          // Espacio al final para mejor visualización
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
