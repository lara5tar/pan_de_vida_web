import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/venta_model.dart';
import '../../controllers/sales_controller.dart';

class ShippingSalesTab extends StatelessWidget {
  final SalesController controller;
  final Function setState;
  final Function(VentaModel) onViewDetails;
  final Function(VentaModel) onUploadEvidence;
  final Function(String) onViewEvidence;
  final TextEditingController searchController;

  const ShippingSalesTab({
    super.key,
    required this.controller,
    required this.setState,
    required this.onViewDetails,
    required this.onUploadEvidence,
    required this.onViewEvidence,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSearchField(context),
          _buildActionButtons(context),

          // Mostramos el mensaje de "No hay ventas con envío" pero mantenemos los botones visibles
          if (controller.filteredVentas.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No hay ventas con envío',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            Column(
              children: [
                _buildShippingTableHeader(context),
                _buildShippingTable(context),
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
              onSubmitted: (_) => controller.loadVentasConEnvio(setState),
              decoration: InputDecoration(
                labelText: 'Buscar ventas con envío',
                hintText: 'Cliente, ID o dirección',
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
                          controller.loadVentasConEnvio(setState);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => controller.loadVentasConEnvio(setState),
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
                      () => controller.generateExcelReport(context, setState),
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
                  onPressed: () => controller.loadVentasConEnvio(setState),
                  icon: const Icon(Icons.refresh, size: 28),
                  label: const Text(
                    'ACTUALIZAR ENVÍOS',
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

  Widget _buildShippingTableHeader(BuildContext context) {
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
          Expanded(child: Text('DESCUENTO', style: textStyle)),
          Expanded(child: Text('TOTAL', style: textStyle)),
          Expanded(child: Text('VENDEDOR', style: textStyle)),
          Expanded(child: Text('ESTADO', style: textStyle)),
          const SizedBox(width: 140), // Espacio para acciones
        ],
      ),
    );
  }

  Widget _buildShippingTable(BuildContext context) {
    return Column(
      children:
          controller.filteredVentas.map((venta) {
            return Container(
              decoration: BoxDecoration(
                color:
                    controller.filteredVentas.indexOf(venta).isEven
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
                          '\$${venta.descuento.toStringAsFixed(2)}',
                          style: TextStyle(
                            color:
                                venta.descuento > 0 ? Colors.red : Colors.grey,
                            fontWeight:
                                venta.descuento > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '\$${venta.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(venta.vendedor),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: controller
                                .getStatusColor(venta.estado)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            venta.estado,
                            style: TextStyle(
                              color: controller.getStatusColor(venta.estado),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Acciones - Botones para ver detalles, subir evidencia y ver imagen
                    SizedBox(
                      width: 140,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón para ver detalles
                          IconButton(
                            icon: const Icon(
                              Icons.visibility,
                              color: Colors.blue,
                            ),
                            onPressed: () => onViewDetails(venta),
                            tooltip: 'Ver detalles',
                          ),
                          // Botón para subir evidencia
                          IconButton(
                            icon: const Icon(
                              Icons.cloud_upload,
                              color: Colors.green,
                            ),
                            onPressed: () => onUploadEvidence(venta),
                            tooltip: 'Subir evidencia',
                          ),
                          // Botón para ver imagen de evidencia (solo visible si hay una URL)
                          if (venta.evidenciaEnvio != null &&
                              venta.evidenciaEnvio!.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.image,
                                color: Colors.purple,
                              ),
                              onPressed:
                                  () => onViewEvidence(venta.evidenciaEnvio!),
                              tooltip: 'Ver evidencia',
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
