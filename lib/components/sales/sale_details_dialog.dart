import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/venta_model.dart';
import '../../controllers/sales_controller.dart';

class SaleDetailsDialog extends StatelessWidget {
  final VentaModel venta;
  final SalesController controller;

  const SaleDetailsDialog({
    super.key,
    required this.venta,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Formatear fecha
    final formattedDate = DateFormat(
      'dd/MM/yyyy - HH:mm',
    ).format(venta.fechaVenta);

    return AlertDialog(
      title: Row(
        children: [
          Text('Venta #${venta.id.substring(0, 6)}...'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: controller.getStatusColor(venta.estado).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              venta.estado,
              style: TextStyle(
                color: controller.getStatusColor(venta.estado),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailSection('Información General', [
                _buildDetailRow('Fecha', formattedDate),
                _buildDetailRow('Vendedor', venta.vendedor),
                if (venta.sucursal != null)
                  _buildDetailRow('Sucursal', venta.sucursal!),
              ]),

              _buildDetailSection('Cliente', [
                _buildDetailRow(
                  'Nombre',
                  venta.nombreCliente ?? 'Cliente general',
                ),
                if (venta.telefonoCliente != null)
                  _buildDetailRow('Teléfono', venta.telefonoCliente!),
                _buildDetailRow(
                  'Es proveedor',
                  venta.esProveedor ? 'Sí' : 'No',
                ),
              ]),

              _buildDetailSection('Productos', [
                ...venta.items.map(
                  (item) => _buildDetailRow(
                    item.nombreLibro,
                    '${item.cantidad} x \$${item.precioUnitario.toStringAsFixed(2)} = \$${item.subtotal.toStringAsFixed(2)}',
                  ),
                ),
              ]),

              _buildDetailSection('Totales', [
                _buildDetailRow(
                  'Subtotal',
                  '\$${venta.subtotal.toStringAsFixed(2)}',
                ),
                _buildDetailRow(
                  'Descuento',
                  '\$${venta.descuento.toStringAsFixed(2)}',
                ),
                _buildDetailRow(
                  'Total',
                  '\$${venta.total.toStringAsFixed(2)}',
                  isBold: true,
                ),
              ]),

              if (venta.esPagoAPlazo)
                _buildDetailSection('Pago a Plazos', [
                  if (venta.montoInicial != null)
                    _buildDetailRow(
                      'Monto inicial',
                      '\$${venta.montoInicial!.toStringAsFixed(2)}',
                    ),
                  _buildDetailRow(
                    'Estado de pago',
                    venta.estaPagada ? 'Pagado' : 'Pendiente',
                  ),
                  _buildDetailRow(
                    'Total pendiente',
                    '\$${venta.totalPendiente.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Historial de pagos:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...venta.pagos.map(
                    (pago) => _buildDetailRow(
                      DateFormat('dd/MM/yyyy').format(pago.fecha),
                      '\$${pago.monto.toStringAsFixed(2)} - ${pago.comentarios ?? ""}',
                    ),
                  ),
                ]),

              if (venta.esEnvio)
                _buildDetailSection('Información de Envío', [
                  if (venta.numeroEnvio != null)
                    _buildDetailRow('Número de envío', venta.numeroEnvio!),
                  if (venta.costoEnvio != null)
                    _buildDetailRow(
                      'Costo de envío',
                      '\$${venta.costoEnvio!.toStringAsFixed(2)}',
                    ),
                  if (venta.direccionEnvio != null)
                    _buildDetailRow('Dirección', venta.direccionEnvio!),
                  if (venta.evidenciaEnvio != null &&
                      venta.evidenciaEnvio!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Evidencia de envío:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.3,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              venta.evidenciaEnvio!,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'No se pudo cargar la imagen',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ]),

              if (venta.notas != null && venta.notas!.isNotEmpty)
                _buildDetailSection('Notas', [Text(venta.notas!)]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CERRAR'),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
