import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/book_model.dart';

class InventoryTable extends StatefulWidget {
  final List<Book> books;
  final String sortCriteria;
  final bool isAscending;
  final Function(String) onSort;
  final Function(Book) onStartEditingBook;
  final Function(
    Book, {
    String? nombre,
    String? codigoBarras,
    double? precio,
    int? cantidadEnStock,
  })
  onUpdateBook;
  final Function(Book) onDeleteBook;
  final Function(String) isEditing;
  final Function(Book) getBookToDisplay;

  const InventoryTable({
    super.key,
    required this.books,
    required this.sortCriteria,
    required this.isAscending,
    required this.onSort,
    required this.onStartEditingBook,
    required this.onUpdateBook,
    required this.onDeleteBook,
    required this.isEditing,
    required this.getBookToDisplay,
  });

  @override
  State<InventoryTable> createState() => _InventoryTableState();
}

class _InventoryTableState extends State<InventoryTable> {
  // Map para guardar los controllers por ID de libro y campo
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    // Limpiar todos los controllers al destruir el widget
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Obtener o crear un controller para un libro específico y un campo específico
  TextEditingController _getController(
    String bookId,
    String field,
    String initialValue,
  ) {
    final key = '${bookId}_$field';
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialValue);
    }
    return _controllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTableHeader(context),
        widget.books.isEmpty
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No se encontraron libros'),
              ),
            )
            : _buildBooksTable(context),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final textStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );

    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => widget.onSort('nombre'),
              child: Row(
                children: [
                  Text('NOMBRE', style: textStyle),
                  if (widget.sortCriteria == 'nombre')
                    Icon(
                      widget.isAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => widget.onSort('codigo'),
              child: Row(
                children: [
                  Text('CÓDIGO', style: textStyle),
                  if (widget.sortCriteria == 'codigo')
                    Icon(
                      widget.isAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => widget.onSort('precio'),
              child: Row(
                children: [
                  Text('PRECIO', style: textStyle),
                  if (widget.sortCriteria == 'precio')
                    Icon(
                      widget.isAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => widget.onSort('stock'),
              child: Row(
                children: [
                  Text('STOCK', style: textStyle),
                  if (widget.sortCriteria == 'stock')
                    Icon(
                      widget.isAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildBooksTable(BuildContext context) {
    return Column(
      children:
          widget.books.map((originalBook) {
            // Obtenemos la versión que debemos mostrar (original o editada)
            final book = widget.getBookToDisplay(originalBook);
            final isLowStock = book.cantidadEnStock < 5;
            final isBookEditing = widget.isEditing(book.id);

            return Container(
              decoration: BoxDecoration(
                color:
                    widget.books.indexOf(originalBook).isEven
                        ? Colors.transparent
                        : Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color:
                        isBookEditing
                            ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3)
                            : Colors.black12,
                    width: isBookEditing ? 1.5 : 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Nombre (editable)
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildEditableField(
                          bookId: book.id,
                          field: 'nombre',
                          initialValue: book.nombre,
                          onTap: () => widget.onStartEditingBook(originalBook),
                          onChanged:
                              (value) => widget.onUpdateBook(
                                originalBook,
                                nombre: value,
                              ),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          isEditing: isBookEditing,
                        ),
                      ),
                    ),

                    // Código de barras (editable)
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildEditableField(
                          bookId: book.id,
                          field: 'codigoBarras',
                          initialValue:
                              book.codigoBarras.isNotEmpty
                                  ? book.codigoBarras
                                  : '',
                          onTap: () => widget.onStartEditingBook(originalBook),
                          onChanged:
                              (value) => widget.onUpdateBook(
                                originalBook,
                                codigoBarras: value,
                              ),
                          style: TextStyle(
                            color:
                                book.codigoBarras.isEmpty ? Colors.grey : null,
                          ),
                          isEditing: isBookEditing,
                        ),
                      ),
                    ),

                    // Precio (editable)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildEditableField(
                          bookId: book.id,
                          field: 'precio',
                          initialValue:
                              isBookEditing
                                  ? book.precio.toString()
                                  : '\$${book.precio.toStringAsFixed(2)}',
                          onTap: () => widget.onStartEditingBook(originalBook),
                          onChanged: (value) {
                            final doubleValue = double.parse(value);
                            widget.onUpdateBook(
                              originalBook,
                              precio: doubleValue,
                            );
                          },
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          isEditing: isBookEditing,
                          isNumber: true,
                        ),
                      ),
                    ),

                    // Stock (editable)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            isLowStock
                                ? Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: Colors.red[700],
                                )
                                : const SizedBox(width: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildEditableField(
                                bookId: book.id,
                                field: 'stock',
                                initialValue: book.cantidadEnStock.toString(),
                                onTap:
                                    () =>
                                        widget.onStartEditingBook(originalBook),
                                onChanged: (value) {
                                  final intValue = int.parse(value);
                                  widget.onUpdateBook(
                                    originalBook,
                                    cantidadEnStock: intValue,
                                  );
                                },
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isLowStock ? Colors.red[700] : null,
                                ),
                                isEditing: isBookEditing,
                                isNumber: true,
                                isInteger: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Acción eliminar
                    SizedBox(
                      width: 60,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => widget.onDeleteBook(book),
                        tooltip: 'Eliminar',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  // Widget para campo editable
  Widget _buildEditableField({
    required String bookId,
    required String field,
    required String initialValue,
    required Function() onTap,
    required Function(String) onChanged,
    TextStyle? style,
    bool isEditing = false,
    bool isNumber = false,
    bool isInteger = false,
  }) {
    if (isEditing) {
      return Builder(
        builder: (context) {
          // Obtener o crear controller para este campo específico
          final controller = _getController(bookId, field, initialValue);

          return TextField(
            controller: controller,
            onChanged: onChanged,
            style: style,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            keyboardType:
                isNumber
                    ? isInteger
                        ? TextInputType.number
                        : const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
            inputFormatters:
                isNumber
                    ? isInteger
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}$'),
                          ),
                        ]
                    : null,
          );
        },
      );
    } else {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(initialValue, style: style),
        ),
      );
    }
  }
}
