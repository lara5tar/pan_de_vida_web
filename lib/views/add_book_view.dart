import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book_model.dart';
import '../services/books_service.dart';

class AddBookView extends StatefulWidget {
  final Book?
  bookToEdit; // Si se proporciona, será edición en lugar de creación

  const AddBookView({super.key, this.bookToEdit});

  @override
  _AddBookViewState createState() => _AddBookViewState();
}

class _AddBookViewState extends State<AddBookView> {
  final _formKey = GlobalKey<FormState>();
  final _booksService = BooksService();
  bool _isLoading = false;

  // Controladores para los campos del formulario
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  final _codigoBarrasController = TextEditingController();

  // Indica si estamos en modo edición
  bool get isEditMode => widget.bookToEdit != null;

  @override
  void initState() {
    super.initState();

    // Si estamos editando, rellenamos el formulario con los datos existentes
    if (isEditMode) {
      _nombreController.text = widget.bookToEdit!.nombre;
      _precioController.text = widget.bookToEdit!.precio.toString();
      _stockController.text = widget.bookToEdit!.cantidadEnStock.toString();
      _codigoBarrasController.text = widget.bookToEdit!.codigoBarras;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _codigoBarrasController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Crear objeto Book con los datos del formulario
        final book = Book(
          id:
              isEditMode
                  ? widget.bookToEdit!.id
                  : '', // ID vacío para nuevo libro
          nombre: _nombreController.text.trim(),
          precio: double.parse(_precioController.text),
          cantidadEnStock: int.parse(_stockController.text),
          codigoBarras: _codigoBarrasController.text.trim(),
        );

        Map<String, dynamic> result;

        // Guardar el libro (crear nuevo o actualizar existente)
        if (isEditMode) {
          result = await _booksService.update(book);
        } else {
          result = await _booksService.add(book);
        }

        setState(() {
          _isLoading = false;
        });

        if (result['error']) {
          // Mostrar mensaje de error
          if (mounted) {
            _showErrorDialog(result['message']);
          }
        } else {
          // Operación exitosa
          if (mounted) {
            _showSuccessDialog(isEditMode);
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          _showErrorDialog('Error: ${e.toString()}');
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog(bool wasEditing) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(wasEditing ? 'Libro actualizado' : 'Libro agregado'),
            content: Text(
              wasEditing
                  ? 'El libro ha sido actualizado correctamente.'
                  : 'El libro ha sido agregado correctamente al inventario.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar el diálogo
                  Navigator.pop(
                    context,
                    true,
                  ); // Volver a la vista anterior con resultado positivo
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Editar Libro' : 'Agregar Nuevo Libro'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Título del formulario
                                Text(
                                  isEditMode
                                      ? 'Editar información del libro'
                                      : 'Información del nuevo libro',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 30),

                                // Campo de nombre del libro
                                TextFormField(
                                  controller: _nombreController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre del libro *',
                                    hintText:
                                        'Ingrese el título completo del libro',
                                    prefixIcon: Icon(Icons.book),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Por favor ingrese el nombre del libro';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Campo de precio
                                TextFormField(
                                  controller: _precioController,
                                  decoration: const InputDecoration(
                                    labelText: 'Precio *',
                                    hintText: 'Ingrese el precio del libro',
                                    prefixIcon: Icon(Icons.attach_money),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}'),
                                    ),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese el precio';
                                    }
                                    try {
                                      final price = double.parse(value);
                                      if (price < 0) {
                                        return 'El precio no puede ser negativo';
                                      }
                                    } catch (e) {
                                      return 'Por favor ingrese un valor numérico válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Campo de cantidad en stock
                                TextFormField(
                                  controller: _stockController,
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad en stock *',
                                    hintText: 'Ingrese la cantidad disponible',
                                    prefixIcon: Icon(Icons.inventory),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese la cantidad en stock';
                                    }
                                    try {
                                      final stock = int.parse(value);
                                      if (stock < 0) {
                                        return 'La cantidad en stock no puede ser negativa';
                                      }
                                    } catch (e) {
                                      return 'Por favor ingrese un valor entero válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Campo de código de barras (opcional)
                                TextFormField(
                                  controller: _codigoBarrasController,
                                  decoration: const InputDecoration(
                                    labelText: 'Código de barras (opcional)',
                                    hintText:
                                        'Ingrese el código de barras si está disponible',
                                    prefixIcon: Icon(Icons.qr_code),
                                    border: OutlineInputBorder(),
                                  ),
                                  // No se necesita validador porque es opcional
                                ),
                                const SizedBox(height: 30),

                                // Botones de acción
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(Icons.cancel),
                                        label: const Text('Cancelar'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _saveBook,
                                        icon: Icon(
                                          isEditMode ? Icons.save : Icons.add,
                                        ),
                                        label: Text(
                                          isEditMode
                                              ? 'Guardar cambios'
                                              : 'Agregar libro',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
