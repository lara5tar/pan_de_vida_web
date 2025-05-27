import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/venta_model.dart';
import '../../controllers/sales_controller.dart';

class PendingPaymentsTab extends StatelessWidget {
  final SalesController controller;
  final Function setState;
  final Function(VentaModel) onViewDetails;
  final Function(VentaModel) onRegisterPayment;
  final TextEditingController searchController;

  const PendingPaymentsTab({
    super.key,
    required this.controller,
    required this.setState,
    required this.onViewDetails,
    required this.onRegisterPayment,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSearchField(context),
          _buildActionButtons(context),

          // Mostramos el mensaje de "No hay pagos pendientes" pero mantenemos los botones visibles
          if (controller.ventasPendientes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No hay pagos pendientes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            Column(
              children: [
                _buildPendingPaymentsTableHeader(context),
                _buildPendingPaymentsTable(context),
              ],
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onSubmitted: (_) => controller.loadVentasPendientes(setState),
              decoration: InputDecoration(
                labelText: 'Buscar pagos pendientes',
                hintText: 'Cliente, ID o vendedor',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          controller.loadVentasPendientes(setState);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed:
                          () => controller.loadVentasPendientes(setState),
                      tooltip: 'Buscar',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      () => controller.generatePendingPaymentsExcelReport(
                        context,
                        setState,
                      ),
                  icon: const Icon(Icons.download, size: 28),
                  label: const Text(
                    'DESCARGAR REPORTE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.loadVentasPendientes(setState),
                  icon: const Icon(Icons.refresh, size: 28),
                  label: const Text(
                    'ACTUALIZAR PAGOS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingPaymentsTableHeader(BuildContext context) {
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
          Expanded(child: Text('ID DE VENTA', style: textStyle)),
          Expanded(flex: 2, child: Text('CLIENTE', style: textStyle)),
          Expanded(child: Text('FECHA', style: textStyle)),
          Expanded(child: Text('SUBTOTAL', style: textStyle)),
          Expanded(child: Text('TOTAL', style: textStyle)),
          Expanded(child: Text('PAGADO', style: textStyle)),
          Expanded(child: Text('PENDIENTE', style: textStyle)),
          SizedBox(width: 100), // Espacio para acciones
        ],
      ),
    );
  }

  Widget _buildPendingPaymentsTable(BuildContext context) {
    return Column(
      children:
          controller.ventasPendientes.map((venta) {
            // Calcular monto pagado (total - pendiente)
            final montoPagado = venta.total - venta.totalPendiente;

            return Container(
              decoration: BoxDecoration(
                color:
                    controller.ventasPendientes.indexOf(venta).isEven
                        ? Colors.transparent
                        : Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.black12, width: 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${venta.id.substring(0, 6)}...',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          venta.nombreCliente ?? 'Cliente general',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(venta.fechaVenta),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('\$${venta.subtotal.toStringAsFixed(2)}'),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '\$${venta.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('\$${montoPagado.toStringAsFixed(2)}'),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '\$${venta.totalPendiente.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ),
                    // Acciones
                    SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón para registrar un pago
                          IconButton(
                            icon: const Icon(
                              Icons.payments,
                              color: Colors.green,
                            ),
                            onPressed: () => onRegisterPayment(venta),
                            tooltip: 'Registrar pago',
                          ),
                          // Botón para ver detalles
                          IconButton(
                            icon: const Icon(
                              Icons.visibility,
                              color: Colors.blue,
                            ),
                            onPressed: () => onViewDetails(venta),
                            tooltip: 'Ver detalles',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
