import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/venta_model.dart';
import '../../controllers/sales_controller.dart';

class SalesByDayTab extends StatelessWidget {
  final SalesController controller;
  final Function setState;
  final Function(VentaModel) onViewDetails;

  const SalesByDayTab({
    super.key,
    required this.controller,
    required this.setState,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDateSelector(context),
          _buildActionButtons(context),
          controller.filteredVentas.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child:
                      controller.selectedDate == null
                          ? const Text(
                            'Seleccione una fecha para ver las ventas',
                            style: TextStyle(fontSize: 16),
                          )
                          : const Text(
                            'No hay ventas para la fecha seleccionada',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              )
              : Column(
                children: [
                  _buildSalesTableHeader(context),
                  _buildSalesTable(context),
                ],
              ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha',
                  hintText: 'Seleccionar fecha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon:
                      controller.selectedDate != null
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.setSelectedDate(null, setState);
                            },
                          )
                          : null,
                ),
                child:
                    controller.selectedDate != null
                        ? Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(controller.selectedDate!),
                        )
                        : const Text('Seleccionar fecha'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != controller.selectedDate) {
      controller.setSelectedDate(picked, setState);
    }
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
                  onPressed: () => controller.loadVentas(setState),
                  icon: const Icon(Icons.refresh, size: 28),
                  label: const Text(
                    'ACTUALIZAR VENTAS',
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

  Widget _buildSalesTableHeader(BuildContext context) {
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
          Expanded(child: Text('ID', style: textStyle)),
          Expanded(flex: 2, child: Text('CLIENTE', style: textStyle)),
          Expanded(child: Text('FECHA', style: textStyle)),
          Expanded(child: Text('SUBTOTAL', style: textStyle)),
          Expanded(child: Text('DESCUENTO', style: textStyle)),
          Expanded(child: Text('TOTAL', style: textStyle)),
          Expanded(child: Text('VENDEDOR', style: textStyle)),
          Expanded(child: Text('ESTADO', style: textStyle)),
          SizedBox(width: 60), // Espacio para acciones
        ],
      ),
    );
  }

  Widget _buildSalesTable(BuildContext context) {
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
                            vertical: 4,
                            horizontal: 8,
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
                    // Acciones
                    SizedBox(
                      width: 60,
                      child: IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => onViewDetails(venta),
                        tooltip: 'Ver detalles',
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
