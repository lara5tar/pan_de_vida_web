import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/venta_model.dart';
import '../../models/book_model.dart';
import '../../controllers/sales_controller.dart';
import '../../services/books_service.dart';
import '../../services/auth_service.dart';
import '../../services/upload_image.dart';
import '../../services/ventas_service.dart';

class AddSaleView extends StatefulWidget {
  const AddSaleView({super.key});

  @override
  State<AddSaleView> createState() => _AddSaleViewState();
}

class _AddSaleViewState extends State<AddSaleView> {
  // Controllers for form fields
  final formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _initialAmountController = TextEditingController();
  final _shippingNumberController = TextEditingController();
  final _shippingCostController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _notesController = TextEditingController();

  // Services
  final BooksService _booksService = BooksService();
  final SalesController _salesController = SalesController();
  final AuthService _authService = AuthService();
  final VentasService _ventasService = VentasService();

  // Form values
  List<Book> _availableBooks = [];
  List<ItemVenta> _cartItems = [];
  bool _isLoading = true;
  bool _isPlanPayment = false;
  bool _isWholesaler = false;
  bool _isShipping = false;
  double _discount = 0;
  String? _selectedBranch;
  String _saleStatus = 'Completada';

  // Sale status options
  final List<String> _statusOptions = ['Completada', 'Pendiente', 'Cancelada'];

  // For initial payment proof
  String? _initialPaymentProofUrl;
  bool _isInitialPaymentImageLoading = false;

  // For shipping proof
  String? _shippingProofUrl;
  bool _isShippingImageLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _initialAmountController.dispose();
    _shippingNumberController.dispose();
    _shippingCostController.dispose();
    _shippingAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Load available books from database
  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _booksService.getAll();
      if (result['error'] == false) {
        setState(() {
          _availableBooks = result['data'];
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Error al cargar los libros: ${result['message']}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add item to cart
  void _addToCart(Book book, int quantity) {
    // Make sure quantity is valid
    if (quantity <= 0 || quantity > book.cantidadEnStock) {
      _showErrorSnackBar('Cantidad inválida');
      return;
    }

    // Check if the item already exists in the cart
    final existingItemIndex = _cartItems.indexWhere(
      (item) => item.idLibro == book.id,
    );

    setState(() {
      if (existingItemIndex >= 0) {
        // Update existing item
        final existingItem = _cartItems[existingItemIndex];
        final newQuantity = existingItem.cantidad + quantity;

        if (newQuantity <= book.cantidadEnStock) {
          _cartItems[existingItemIndex] = ItemVenta(
            idLibro: book.id,
            nombreLibro: book.nombre,
            precioUnitario: book.precio,
            cantidad: newQuantity,
            subtotal: book.precio * newQuantity,
          );
        } else {
          _showErrorSnackBar('No hay suficiente stock disponible');
        }
      } else {
        // Add new item
        _cartItems.add(
          ItemVenta(
            idLibro: book.id,
            nombreLibro: book.nombre,
            precioUnitario: book.precio,
            cantidad: quantity,
            subtotal: book.precio * quantity,
          ),
        );
      }
    });
  }

  // Remove item from cart
  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  // Update item quantity in cart
  void _updateCartItemQuantity(int index, int newQuantity) {
    final item = _cartItems[index];
    final book = _availableBooks.firstWhere((b) => b.id == item.idLibro);

    if (newQuantity <= 0) {
      _removeFromCart(index);
      return;
    }

    if (newQuantity > book.cantidadEnStock) {
      _showErrorSnackBar('No hay suficiente stock disponible');
      return;
    }

    setState(() {
      _cartItems[index] = ItemVenta(
        idLibro: item.idLibro,
        nombreLibro: item.nombreLibro,
        precioUnitario: item.precioUnitario,
        cantidad: newQuantity,
        subtotal: item.precioUnitario * newQuantity,
      );
    });
  }

  // Calculate subtotal of all items
  double get _subtotal {
    return _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  // Calculate discount amount
  double get _discountAmount {
    return _subtotal * (_discount / 100);
  }

  // Calculate total after discount
  double get _total {
    return _subtotal - _discountAmount;
  }

  // Upload image and get URL
  Future<String?> _uploadImage() async {
    try {
      final result = await ImageUploadService.pickAndUploadImage();
      if (result['success']) {
        return result['url'];
      } else {
        _showErrorSnackBar('Error: ${result['message']}');
      }
      return null;
    } catch (e) {
      _showErrorSnackBar('Error al subir imagen: ${e.toString()}');
      return null;
    }
  }

  // Submit the form to create a new sale
  Future<void> _submitForm() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (_cartItems.isEmpty) {
      _showErrorSnackBar('Debe agregar al menos un producto');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final currentUser = await _authService.getCurrentUser();

      // Create payments list if it's a plan payment
      List<Pago> pagos = [];
      if (_isPlanPayment && _initialAmountController.text.isNotEmpty) {
        final initialAmount = double.parse(_initialAmountController.text);
        pagos.add(
          Pago(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            monto: initialAmount,
            fecha: DateTime.now(),
            comprobante: _initialPaymentProofUrl,
            pagado: true,
            comentarios: 'Pago inicial',
          ),
        );
      }

      // Create VentaModel
      final ventaModel = VentaModel(
        id: '', // ID will be assigned by Firebase
        items: _cartItems,
        fechaVenta: DateTime.now(),
        subtotal: _subtotal,
        descuento: _discountAmount,
        total: _total,
        vendedor: currentUser,
        nombreCliente:
            (_isPlanPayment || _isWholesaler)
                ? _clientNameController.text
                : null,
        telefonoCliente:
            (_isPlanPayment || _isWholesaler)
                ? _clientPhoneController.text
                : null,
        esProveedor: _isWholesaler,
        esPagoAPlazo: _isPlanPayment,
        pagos: pagos,
        montoInicial:
            _isPlanPayment && _initialAmountController.text.isNotEmpty
                ? double.parse(_initialAmountController.text)
                : null,
        comprobanteInicial: _initialPaymentProofUrl,
        esEnvio: _isShipping,
        numeroEnvio: _isShipping ? _shippingNumberController.text : null,
        costoEnvio:
            _isShipping && _shippingCostController.text.isNotEmpty
                ? double.parse(_shippingCostController.text)
                : null,
        direccionEnvio: _isShipping ? _shippingAddressController.text : null,
        evidenciaEnvio: _shippingProofUrl,
        sucursal: _selectedBranch,
        estado: _saleStatus,
        notas: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Verificar stock suficiente si la venta está completada
      if (_saleStatus == 'Completada') {
        // Verificar que haya suficiente stock para todos los productos
        for (var item in _cartItems) {
          final book = _availableBooks.firstWhere(
            (b) => b.id == item.idLibro,
            orElse: () {
              _showErrorSnackBar(
                'Libro no encontrado en inventario: ${item.nombreLibro}',
              );
              throw Exception('Libro no encontrado en inventario');
            },
          );

          if (book.cantidadEnStock < item.cantidad) {
            _showErrorSnackBar(
              'No hay suficiente stock para "${book.nombre}". Disponible: ${book.cantidadEnStock}, Solicitado: ${item.cantidad}',
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
      }

      // Save the sale to Firebase
      final result = await _ventasService.add(ventaModel);

      if (result['error'] == true) {
        _showErrorSnackBar('Error al guardar la venta: ${result['message']}');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Update inventory after successful sale (only if status is "Completada")
      if (_saleStatus == 'Completada') {
        await _updateInventory();
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta registrada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the form
      _clearForm();
    } catch (e) {
      _showErrorSnackBar('Error al registrar la venta: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update inventory quantities after a sale
  Future<void> _updateInventory() async {
    try {
      // Por cada artículo en el carrito, actualizar el stock del libro
      for (var item in _cartItems) {
        // Encontrar el libro en los libros disponibles
        final bookIndex = _availableBooks.indexWhere(
          (b) => b.id == item.idLibro,
        );
        if (bookIndex >= 0) {
          final book = _availableBooks[bookIndex];

          // Crear libro actualizado con stock reducido
          final updatedBook = book.copyWith(
            cantidadEnStock: book.cantidadEnStock - item.cantidad,
          );

          // Actualizar libro en la base de datos
          final result = await _booksService.update(updatedBook);
          if (result['error'] == true) {
            throw Exception(
              'Error al actualizar el inventario: ${result['message']}',
            );
          }
        }
      }

      // Recargar libros para reflejar el inventario actualizado
      await _loadBooks();
    } catch (e) {
      _showErrorSnackBar('Error al actualizar el inventario: ${e.toString()}');
      rethrow; // Re-lanzar la excepción para que _submitForm la capture
    }
  }

  // Clear the form
  void _clearForm() {
    setState(() {
      _cartItems = [];
      _isPlanPayment = false;
      _isWholesaler = false;
      _isShipping = false;
      _discount = 0;
      _selectedBranch = null;
      _saleStatus = 'Completada';
      _initialPaymentProofUrl = null;
      _shippingProofUrl = null;
      _clientNameController.clear();
      _clientPhoneController.clear();
      _initialAmountController.clear();
      _shippingNumberController.clear();
      _shippingCostController.clear();
      _shippingAddressController.clear();
      _notesController.clear();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Show image preview dialog
  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image display
              Container(
                constraints: BoxConstraints(maxHeight: 400, maxWidth: 400),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          'Error al cargar la imagen',
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Close button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Venta')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Products and cart section combined
                          _buildProductsAndCartSection(),

                          // Pricing section
                          _buildPricingSection(),

                          // Client information section
                          _buildClientSection(),

                          // Payment information section (always visible)
                          _buildPaymentSection(),

                          // Shipping information section
                          _buildShippingSection(),

                          // Administrative information section
                          _buildAdminSection(),

                          const SizedBox(height: 20),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Registrar Venta'),
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  // Products and cart section
  Widget _buildProductsAndCartSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Carrito de Compra',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Buscador de libros (por nombre o código de barras)
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar libro por nombre o código de barras',
                hintText: 'Ingrese nombre o código de barras',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Buscar cuando se ingresen al menos 2 caracteres
                _searchBooks(value);
              },
            ),

            // Resultados de la búsqueda
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children:
                      _searchResults
                          .take(5) // Limitar a mostrar solo 5 resultados máximo
                          .map(
                            (book) => ListTile(
                              title: Text(book.nombre),
                              subtitle: Text(
                                'Precio: \$${book.precio.toStringAsFixed(2)} - Stock: ${book.cantidadEnStock}${book.codigoBarras.isNotEmpty ? ' - Código: ${book.codigoBarras}' : ''}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                ),
                                onPressed:
                                    book.cantidadEnStock > 0
                                        ? () {
                                          _addToCart(book, 1);
                                          // No limpiar la búsqueda para permitir agregar más del mismo tipo
                                        }
                                        : null,
                                iconSize: 32,
                              ),
                              enabled: book.cantidadEnStock > 0,
                              tileColor:
                                  book.cantidadEnStock <= 0
                                      ? Colors.grey.shade200
                                      : null,
                            ),
                          )
                          .toList(),
                ),
              ),
              // Si hay más resultados de los que se muestran, indicarlo
              if (_searchResults.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                  child: Text(
                    'Mostrando 5 de ${_searchResults.length} resultados. Refina tu búsqueda para encontrar más libros.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 20),

            // Cart items
            if (_cartItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text('No hay artículos en el carrito')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  return ListTile(
                    title: Text(item.nombreLibro),
                    subtitle: Text(
                      'Precio: \$${item.precioUnitario.toStringAsFixed(2)} x ${item.cantidad}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Precio total del producto con texto más grande
                        Text(
                          '\$${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botón de disminuir cantidad
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          tooltip: 'Disminuir cantidad',
                          onPressed: () {
                            _updateCartItemQuantity(index, item.cantidad - 1);
                          },
                          iconSize: 32,
                        ),
                        // Campo de texto para editar cantidad directamente
                        SizedBox(
                          width: 50,
                          child: TextField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            controller: TextEditingController(
                              text: item.cantidad.toString(),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            onSubmitted: (value) {
                              final newQuantity =
                                  int.tryParse(value) ?? item.cantidad;
                              _updateCartItemQuantity(index, newQuantity);
                            },
                          ),
                        ),
                        // Botón de aumentar cantidad
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.green,
                          ),
                          tooltip: 'Aumentar cantidad',
                          onPressed: () {
                            _updateCartItemQuantity(index, item.cantidad + 1);
                          },
                          iconSize: 32,
                        ),
                        // Botón para eliminar
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Eliminar del carrito',
                          onPressed: () => _removeFromCart(index),
                          iconSize: 32,
                        ),
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  );
                },
              ),

            // Cart summary
            if (_cartItems.isNotEmpty) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total productos:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_cartItems.fold(0, (sum, item) => sum + item.cantidad)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${_subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Pricing section
  Widget _buildPricingSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Precio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Discount slider
            Row(
              children: [
                const Text('Descuento: '),
                Expanded(
                  child: Slider(
                    value: _discount,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    label: '${_discount.round()}%',
                    onChanged: (value) {
                      setState(() {
                        _discount = value;
                      });
                    },
                  ),
                ),
                Text('${_discount.round()}%'),
              ],
            ),

            // Subtotal, discount and total
            ListTile(
              title: const Text('Subtotal'),
              trailing: Text('\$${_subtotal.toStringAsFixed(2)}'),
            ),
            ListTile(
              title: Text('Descuento (${_discount.round()}%)'),
              trailing: Text('\$${_discountAmount.toStringAsFixed(2)}'),
            ),
            ListTile(
              title: const Text('Total'),
              trailing: Text(
                '\$${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Client information section
  Widget _buildClientSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Payment method selector
            SwitchListTile(
              title: const Text('Pago a Plazos'),
              value: _isPlanPayment,
              onChanged: (value) {
                setState(() {
                  _isPlanPayment = value;
                });
              },
            ),

            // Wholesaler selector
            SwitchListTile(
              title: const Text('Es Mayorista'),
              value: _isWholesaler,
              onChanged: (value) {
                setState(() {
                  _isWholesaler = value;
                });
              },
            ),

            // Client information (if payment plan or wholesaler)
            if (_isPlanPayment || _isWholesaler) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _clientNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Cliente *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((_isPlanPayment || _isWholesaler) &&
                      (value == null || value.isEmpty)) {
                    return 'Por favor ingrese el nombre del cliente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clientPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono del Cliente *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if ((_isPlanPayment || _isWholesaler) &&
                      (value == null || value.isEmpty)) {
                    return 'Por favor ingrese el teléfono del cliente';
                  }
                  return null;
                },
              ),

              // Monto inicial (si es pago a plazos)
              if (_isPlanPayment) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _initialAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto Inicial',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Por favor ingrese un monto válido';
                      }
                      if (double.parse(value) > _total) {
                        return 'El monto inicial no puede ser mayor al total';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Payment information section
  Widget _buildPaymentSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Pago y Comprobantes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Payment proof (always available)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text('Cargar Comprobante de Pago'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    onPressed:
                        _isInitialPaymentImageLoading
                            ? null
                            : () async {
                              setState(() {
                                _isInitialPaymentImageLoading = true;
                              });
                              final url = await _uploadImage();
                              if (url != null) {
                                setState(() {
                                  _initialPaymentProofUrl = url;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Comprobante cargado correctamente',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                              setState(() {
                                _isInitialPaymentImageLoading = false;
                              });
                            },
                  ),
                ),
                if (_isInitialPaymentImageLoading)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  )
                else if (_initialPaymentProofUrl != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.blue),
                    tooltip: 'Ver comprobante',
                    onPressed: () {
                      _showImagePreview(_initialPaymentProofUrl!);
                    },
                  ),
                ],
              ],
            ),

            // Preview of the uploaded image
            if (_initialPaymentProofUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        _initialPaymentProofUrl!,
                        fit: BoxFit.cover,
                        height: 150,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(height: 8),
                              Text(
                                'Error al cargar la imagen',
                                style: TextStyle(color: Colors.red[700]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        },
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Material(
                          color: Colors.white.withOpacity(0.8),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar comprobante',
                            onPressed: () {
                              setState(() {
                                _initialPaymentProofUrl = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Shipping information section
  Widget _buildShippingSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Envío',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Shipping selector
            SwitchListTile(
              title: const Text('Incluye Envío'),
              value: _isShipping,
              onChanged: (value) {
                setState(() {
                  _isShipping = value;
                });
              },
            ),

            if (_isShipping) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _shippingNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Envío *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_isShipping && (value == null || value.isEmpty)) {
                    return 'Por favor ingrese el número de envío';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shippingCostController,
                decoration: const InputDecoration(
                  labelText: 'Costo de Envío *',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (_isShipping && (value == null || value.isEmpty)) {
                    return 'Por favor ingrese el costo de envío';
                  }
                  if (_isShipping && double.tryParse(value!) == null) {
                    return 'Por favor ingrese un costo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shippingAddressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección de Envío *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (_isShipping && (value == null || value.isEmpty)) {
                    return 'Por favor ingrese la dirección de envío';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Shipping proof
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      label: const Text('Cargar Evidencia de Envío'),
                      onPressed:
                          _isShippingImageLoading
                              ? null
                              : () async {
                                setState(() {
                                  _isShippingImageLoading = true;
                                });
                                final url = await _uploadImage();
                                if (url != null) {
                                  setState(() {
                                    _shippingProofUrl = url;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Evidencia cargada correctamente',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                                setState(() {
                                  _isShippingImageLoading = false;
                                });
                              },
                    ),
                  ),
                  if (_isShippingImageLoading)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      ),
                    )
                  else if (_shippingProofUrl != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.image, color: Colors.blue),
                      tooltip: 'Ver evidencia',
                      onPressed: () {
                        _showImagePreview(_shippingProofUrl!);
                      },
                    ),
                  ],
                ],
              ),

              // Preview of the shipping evidence
              if (_shippingProofUrl != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          _shippingProofUrl!,
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(height: 8),
                                Text(
                                  'Error al cargar la imagen',
                                  style: TextStyle(color: Colors.red[700]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          },
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Material(
                            color: Colors.white.withOpacity(0.8),
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar evidencia',
                              onPressed: () {
                                setState(() {
                                  _shippingProofUrl = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Administrative information section
  Widget _buildAdminSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Administrativa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Sale status
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Estado de la Venta',
                border: OutlineInputBorder(),
              ),
              value: _saleStatus,
              items:
                  _statusOptions.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _saleStatus = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  // Lista de resultados de búsqueda
  List<Book> _searchResults = [];

  // Método para buscar libros por nombre o código de barras
  void _searchBooks(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();

    setState(() {
      _searchResults =
          _availableBooks.where((book) {
            return book.nombre.toLowerCase().contains(lowercaseQuery) ||
                book.codigoBarras.toLowerCase().contains(lowercaseQuery);
          }).toList();
    });
  }
}
