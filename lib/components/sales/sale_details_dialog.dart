import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/venta_model.dart';
import '../../controllers/sales_controller.dart';

class SaleDetailsDialog extends StatefulWidget {
  final VentaModel venta;
  final SalesController controller;

  const SaleDetailsDialog({
    super.key,
    required this.venta,
    required this.controller,
  });

  @override
  State<SaleDetailsDialog> createState() => _SaleDetailsDialogState();
}

class _SaleDetailsDialogState extends State<SaleDetailsDialog> {
  late VentaModel venta;

  @override
  void initState() {
    super.initState();
    venta = widget.venta;
  }

  @override
  Widget build(BuildContext context) {
    // Formatear fecha
    final formattedDate = DateFormat(
      'dd/MM/yyyy - HH:mm',
    ).format(venta.fechaVenta);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text('Venta #${venta.id.substring(0, 6)}...'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.controller
                        .getStatusColor(venta.estado)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    venta.estado,
                    style: TextStyle(
                      color: widget.controller.getStatusColor(venta.estado),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información General
                _buildCard(
                  title: 'Información General',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Fecha', formattedDate),
                      _buildDetailRow('Vendedor', venta.vendedor),
                      if (venta.sucursal != null)
                        _buildDetailRow('Sucursal', venta.sucursal!),
                      if (venta.notas != null && venta.notas!.isNotEmpty)
                        _buildDetailRow('Notas', venta.notas!),
                    ],
                  ),
                ),

                // Información del Cliente
                _buildCard(
                  title: 'Información del Cliente',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Nombre',
                        venta.nombreCliente ?? 'Cliente general',
                      ),
                      if (venta.telefonoCliente != null)
                        _buildDetailRow('Teléfono', venta.telefonoCliente!),
                      _buildDetailRow(
                        'Es mayorista',
                        venta.esProveedor ? 'Sí' : 'No',
                      ),
                      _buildDetailRow(
                        'Pago a plazos',
                        venta.esPagoAPlazo ? 'Sí' : 'No',
                      ),
                    ],
                  ),
                ),

                // Productos
                _buildProductsCard(),

                // Información de Pago
                if (venta.esPagoAPlazo) _buildPaymentCard(),

                // Información de Envío
                if (venta.esEnvio) _buildShippingCard(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tarjeta de productos con formato de tabla mejorado
  Widget _buildProductsCard() {
    return _buildCard(
      title: 'Productos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezados de la tabla
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: const [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Producto',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Cant.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Precio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Subtotal',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Lista de productos con formato de tabla
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: venta.items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = venta.items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(flex: 5, child: Text(item.nombreLibro)),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.cantidad}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '\$${item.precioUnitario.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(),
          const SizedBox(height: 8),

          // Totales
          Row(
            children: [
              const Expanded(
                flex: 7,
                child: Text(
                  'Total productos:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  '${venta.items.fold(0, (sum, item) => sum + item.cantidad)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                flex: 7,
                child: Text(
                  'Subtotal:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  '\$${venta.subtotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                flex: 7,
                child: Text(
                  'Descuento:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  '\$${venta.descuento.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                flex: 7,
                child: Text(
                  'TOTAL:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  '\$${venta.total.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tarjeta de información de pago a plazos
  Widget _buildPaymentCard() {
    return _buildCard(
      title: 'Información de Pago a Plazos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (venta.montoInicial != null)
            _buildDetailRow(
              'Monto inicial',
              '\$${venta.montoInicial!.toStringAsFixed(2)}',
            ),
          _buildDetailRow(
            'Estado de pago',
            venta.estaPagada ? 'Pagado' : 'Pendiente',
            valueColor: venta.estaPagada ? Colors.green : Colors.orange,
          ),
          _buildDetailRow(
            'Total pendiente',
            '\$${venta.totalPendiente.toStringAsFixed(2)}',
            valueColor: venta.totalPendiente > 0 ? Colors.orange : Colors.green,
          ),

          if (venta.pagos.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Historial de pagos:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: venta.pagos.length,
              itemBuilder: (context, index) {
                final pago = venta.pagos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(pago.fecha),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${pago.monto.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        if (pago.comentarios != null &&
                            pago.comentarios!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            pago.comentarios!,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                        if (pago.comprobante != null &&
                            pago.comprobante!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _showImagePreview(pago.comprobante!),
                            child: Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.network(
                                      pago.comprobante!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return const Center(
                                          child: Text(
                                            'No se pudo cargar la imagen',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        );
                                      },
                                    ),
                                    Container(
                                      color: Colors.black.withOpacity(0.3),
                                      child: const Center(
                                        child: Icon(
                                          Icons.search,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              'Toca para ver comprobante',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          if (venta.comprobanteInicial != null &&
              venta.comprobanteInicial!.isNotEmpty &&
              (venta.pagos.isEmpty ||
                  !venta.pagos.any(
                    (p) => p.comprobante == venta.comprobanteInicial,
                  ))) ...[
            const SizedBox(height: 16),
            const Text(
              'Comprobante de pago inicial:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImagePreview(venta.comprobanteInicial!),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        venta.comprobanteInicial!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'No se pudo cargar la imagen',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      ),
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Toca para ver comprobante',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Tarjeta de información de envío
  Widget _buildShippingCard() {
    return _buildCard(
      title: 'Información de Envío',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (venta.numeroEnvio != null)
            _buildDetailRow('Número de envío', venta.numeroEnvio!),
          if (venta.costoEnvio != null)
            _buildDetailRow(
              'Costo de envío',
              '\$${venta.costoEnvio!.toStringAsFixed(2)}',
            ),
          if (venta.direccionEnvio != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Dirección de envío:',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(venta.direccionEnvio!),
            ),
          ],

          if (venta.evidenciaEnvio != null &&
              venta.evidenciaEnvio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Evidencia de envío:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImagePreview(venta.evidenciaEnvio!),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        venta.evidenciaEnvio!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'No se pudo cargar la imagen',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      ),
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Toca para ver evidencia',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Componentes básicos para construir la interfaz
  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight:
                    valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar vista previa de imagen a tamaño completo
  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.black.withOpacity(0.7),
                automaticallyImplyLeading: false,
                title: const Text('Vista previa'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Flexible(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
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
                                const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
