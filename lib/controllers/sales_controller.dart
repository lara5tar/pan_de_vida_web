import 'package:flutter/material.dart';
import '../models/venta_model.dart';
import '../services/ventas_service.dart';
import '../reports/sales_excel_report.dart';

class SalesController {
  final VentasService _ventasService = VentasService();

  // Estado
  List<VentaModel> ventas = [];
  List<VentaModel> filteredVentas = [];
  List<VentaModel> ventasPendientes = [];
  bool isLoading = true;
  String errorMessage = '';

  // Para filtrado por fecha
  DateTime? selectedDate;

  // Para pestañas
  int currentTabIndex = 0;

  // Cargar todas las ventas
  Future<void> loadVentas(Function setState) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await _ventasService.getAll();

      if (result['error']) {
        setState(() {
          errorMessage = result['message'] ?? 'Error al cargar las ventas';
          isLoading = false;
        });
      } else {
        setState(() {
          ventas = result['data'];
          // Aplicar filtro por fecha si estamos en la primera pestaña
          if (currentTabIndex == 0 && selectedDate != null) {
            filterVentas(setState);
          } else {
            filteredVentas = ventas;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Cargar ventas con pagos pendientes
  Future<void> loadVentasPendientes(Function setState) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await _ventasService.getAll();

      if (result['error']) {
        setState(() {
          errorMessage = result['message'] ?? 'Error al cargar las ventas';
          isLoading = false;
        });
      } else {
        setState(() {
          ventasPendientes =
              result['data']
                  .where((venta) => venta.esPagoAPlazo && !venta.estaPagada)
                  .toList();
          filteredVentas = ventasPendientes;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Cargar ventas con envío
  Future<void> loadVentasConEnvio(Function setState) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await _ventasService.getVentasConEnvio();

      if (result['error']) {
        setState(() {
          errorMessage =
              result['message'] ?? 'Error al cargar las ventas con envío';
          isLoading = false;
        });
      } else {
        setState(() {
          filteredVentas = result['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Filtrar ventas por fecha seleccionada
  void filterVentas(Function setState) {
    setState(() {
      isLoading = true;
    });

    // Si no hay fecha seleccionada, no filtramos
    if (selectedDate == null) {
      setState(() {
        filteredVentas = ventas;
        isLoading = false;
      });
      return;
    }

    final startOfDay = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      0,
      0,
      0,
    );
    final endOfDay = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      23,
      59,
      59,
    );

    // Filtrar por fecha
    filteredVentas =
        ventas.where((venta) {
          final ventaDate = venta.fechaVenta;
          return ventaDate.isAfter(startOfDay) && ventaDate.isBefore(endOfDay);
        }).toList();

    setState(() {
      isLoading = false;
    });
  }

  // Cambiar la fecha seleccionada
  void setSelectedDate(DateTime? date, Function setState) {
    setState(() {
      selectedDate = date;
    });
    filterVentas(setState);
  }

  // Generar reporte Excel para ventas del día seleccionado
  Future<void> generateExcelReport(
    BuildContext context,
    Function setState,
  ) async {
    try {
      setState(() {
        isLoading = true;
      });

      final report = SalesExcelReport(
        fechaInicio: selectedDate,
        fechaFin:
            selectedDate != null
                ? DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  23,
                  59,
                  59,
                )
                : null,
      );
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

  // Generar reporte Excel para pagos pendientes
  Future<void> generatePendingPaymentsExcelReport(
    BuildContext context,
    Function setState,
  ) async {
    try {
      setState(() {
        isLoading = true;
      });

      final List<VentaModel> ventasPendientesParaReporte =
          ventasPendientes.where((venta) => !venta.estaPagada).toList();

      final report = SalesExcelReport(
        fechaInicio: selectedDate,
        fechaFin:
            selectedDate != null
                ? DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  23,
                  59,
                  59,
                )
                : null,
        ventas: ventasPendientesParaReporte,
      );
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

  // Cambiar de pestaña
  void onTabChanged(int index, Function setState) {
    setState(() {
      currentTabIndex = index;
      // Limpiar filtros al cambiar de pestaña
      if (index == 0) {
        selectedDate = DateTime.now();
      } else {
        selectedDate = null;
      }
    });

    // Cargar datos según la pestaña
    if (index == 0) {
      loadVentas(setState);
    } else if (index == 1) {
      loadVentasPendientes(setState);
    } else if (index == 2) {
      loadVentasConEnvio(setState);
    }
  }

  // Obtener color según el estado de la venta
  Color getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  // Registrar un nuevo pago para una venta con pago a plazos
  Future<void> registerPayment(
    VentaModel venta,
    double monto,
    String comentarios,
    Function setState,
    BuildContext context,
  ) async {
    try {
      setState(() {
        isLoading = true;
      });

      // Crear un nuevo objeto Pago con los datos proporcionados
      final nuevoPago = Pago(
        id:
            DateTime.now().millisecondsSinceEpoch
                .toString(), // Usar timestamp como ID
        monto: monto,
        fecha: DateTime.now(),
        pagado: true,
        comentarios: comentarios,
      );

      // Llamar al servicio con el objeto Pago
      final result = await _ventasService.registrarPago(venta.id, nuevoPago);

      if (result['error']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar datos
        loadVentasPendientes(setState);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Actualizar evidencia de envío
  Future<void> updateShippingEvidence(
    String ventaId,
    String imageUrl,
    Function setState,
    BuildContext context,
  ) async {
    try {
      setState(() {
        isLoading = true;
      });

      final result = await _ventasService.actualizarEvidenciaEnvio(
        ventaId,
        imageUrl,
      );

      if (result['error']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidencia de envío actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar datos
        loadVentasConEnvio(setState);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
