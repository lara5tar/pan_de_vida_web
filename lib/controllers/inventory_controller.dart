import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/books_service.dart';
import '../reports/inventory_excel_report.dart';

class InventoryController {
  final BooksService _booksService = BooksService();

  // Estado
  List<Book> books = [];
  List<Book> filteredBooks = [];
  bool isLoading = true;
  String errorMessage = '';

  // Control de ordenamiento
  String sortCriteria = 'nombre';
  bool isAscending = true;

  // Control de paginación
  int rowsPerPage = 10;
  int currentPage = 0;
  final List<int> rowsPerPageOptions = [10, 25, 50, 100];

  // Control de filtros
  bool showLowStock = false;
  double minPrice = 0;
  double maxPrice = double.infinity;

  // Stats
  int totalBooks = 0;
  int lowStockCount = 0;
  double inventoryValue = 0;

  // Control de edición
  Map<String, Book> originalBooks =
      {}; // Para guardar el estado original antes de editar
  Map<String, Book> editedBooks = {}; // Para guardar los cambios temporales
  bool hasChanges = false;

  // Función para obtener todos los libros
  Future<void> loadBooks(Function setState) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await _booksService.getAll();

      if (result['error']) {
        setState(() {
          errorMessage = result['message'] ?? 'Error al cargar el inventario';
          isLoading = false;
        });
      } else {
        setState(() {
          books = result['data'];
          calculateStats();
          filterBooks('');
          isLoading = false;
          originalBooks = {};
          editedBooks = {};
          hasChanges = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Calcular estadísticas
  void calculateStats() {
    totalBooks = books.length;
    lowStockCount = books.where((book) => book.cantidadEnStock < 5).length;
    inventoryValue = books.fold(
      0,
      (total, book) => total + (book.precio * book.cantidadEnStock),
    );
  }

  // Filtrar libros
  void filterBooks(String query) {
    final searchQuery = query.toLowerCase();

    filteredBooks =
        books.where((book) {
          // Aplicar filtro de búsqueda
          final matchesSearch =
              searchQuery.isEmpty ||
              book.nombre.toLowerCase().contains(searchQuery) ||
              book.codigoBarras.toLowerCase().contains(searchQuery);

          // Aplicar filtro de stock bajo si está activado
          final matchesStockFilter = !showLowStock || book.cantidadEnStock < 5;

          // Aplicar filtro de precio
          final matchesPriceFilter =
              book.precio >= minPrice &&
              (maxPrice == double.infinity || book.precio <= maxPrice);

          return matchesSearch && matchesStockFilter && matchesPriceFilter;
        }).toList();

    sortBooks();
  }

  // Ordenar libros
  void sortBooks() {
    switch (sortCriteria) {
      case 'nombre':
        filteredBooks.sort(
          (a, b) =>
              isAscending
                  ? a.nombre.compareTo(b.nombre)
                  : b.nombre.compareTo(a.nombre),
        );
        break;
      case 'precio':
        filteredBooks.sort(
          (a, b) =>
              isAscending
                  ? a.precio.compareTo(b.precio)
                  : b.precio.compareTo(a.precio),
        );
        break;
      case 'stock':
        filteredBooks.sort(
          (a, b) =>
              isAscending
                  ? a.cantidadEnStock.compareTo(b.cantidadEnStock)
                  : b.cantidadEnStock.compareTo(a.cantidadEnStock),
        );
        break;
      case 'codigo':
        filteredBooks.sort(
          (a, b) =>
              isAscending
                  ? a.codigoBarras.compareTo(b.codigoBarras)
                  : b.codigoBarras.compareTo(a.codigoBarras),
        );
        break;
    }
  }

  // Cambiar criterio de ordenamiento
  void changeSortCriteria(String criteria, Function setState) {
    setState(() {
      if (sortCriteria == criteria) {
        isAscending = !isAscending;
      } else {
        sortCriteria = criteria;
        isAscending = true;
      }
      sortBooks();
    });
  }

  // Generar reporte Excel
  Future<void> generateExcelReport(
    BuildContext context,
    Function setState,
  ) async {
    try {
      setState(() {
        isLoading = true;
      });

      final report = InventoryExcelReport();
      await report.generateAndDownload(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar el reporte: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Obtener libros paginados
  List<Book> getPaginatedBooks() {
    final startIndex = currentPage * rowsPerPage;
    final endIndex =
        startIndex + rowsPerPage > filteredBooks.length
            ? filteredBooks.length
            : startIndex + rowsPerPage;

    if (startIndex >= filteredBooks.length) {
      return [];
    }

    return filteredBooks.sublist(startIndex, endIndex);
  }

  int get pageCount => (filteredBooks.length / rowsPerPage).ceil();

  // Métodos para edición en línea
  void startEditingBook(Book book, Function setState) {
    if (!originalBooks.containsKey(book.id)) {
      setState(() {
        originalBooks[book.id] = book;
        editedBooks[book.id] = book;
      });
    }
  }

  void updateEditedBook(
    Book book, {
    String? nombre,
    String? codigoBarras,
    double? precio,
    int? cantidadEnStock,
    required Function setState,
  }) {
    if (!originalBooks.containsKey(book.id)) {
      startEditingBook(book, setState);
    }

    setState(() {
      editedBooks[book.id] = editedBooks[book.id]!.copyWith(
        nombre: nombre,
        codigoBarras: codigoBarras,
        precio: precio,
        cantidadEnStock: cantidadEnStock,
      );

      // Verificar si hay cambios en este libro
      final original = originalBooks[book.id]!;
      final edited = editedBooks[book.id]!;

      bool bookHasChanges =
          original.nombre != edited.nombre ||
          original.codigoBarras != edited.codigoBarras ||
          original.precio != edited.precio ||
          original.cantidadEnStock != edited.cantidadEnStock;

      // Si no hay cambios, eliminar del mapeo
      if (!bookHasChanges) {
        originalBooks.remove(book.id);
        editedBooks.remove(book.id);
      }

      // Verificar si hay cambios globales
      hasChanges = editedBooks.isNotEmpty;
    });
  }

  bool isEditing(String bookId) {
    return originalBooks.containsKey(bookId);
  }

  Book getBookToDisplay(Book originalBook) {
    if (editedBooks.containsKey(originalBook.id)) {
      return editedBooks[originalBook.id]!;
    }
    return originalBook;
  }

  Future<void> saveChanges(BuildContext context, Function setState) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Guardar cada libro editado
      for (var bookId in editedBooks.keys) {
        await _booksService.update(editedBooks[bookId]!);
      }

      // Recargar los libros para refrescar la vista
      await loadBooks(setState);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios guardados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar los cambios: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  void cancelChanges(Function setState) {
    setState(() {
      originalBooks = {};
      editedBooks = {};
      hasChanges = false;
      filterBooks(''); // Recargar la vista con datos originales
    });
  }

  // Eliminar libro
  Future<void> deleteBook(
    Book book,
    BuildContext context,
    Function setState,
  ) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Eliminar el libro
      final result = await _booksService.delete(book.id);

      if (result['error']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Libro "${book.nombre}" eliminado'),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar libros
        await loadBooks(setState);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
