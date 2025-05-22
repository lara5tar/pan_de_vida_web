import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../models/venta_model.dart';
import '../services/ventas_service.dart';
import 'excel_report_base.dart';

class SalesExcelReport extends ExcelReportBase {
  final VentasService _ventasService = VentasService();
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final List<VentaModel>? ventas;

  SalesExcelReport({this.fechaInicio, this.fechaFin, this.ventas});

  // Sobrescribir el nombre del archivo
  @override
  String get fileName => 'reporte_ventas_${_getFormattedDate()}.xlsx';

  // Generar el contenido específico para el reporte de ventas
  @override
  Future<Excel> generateContent() async {
    // Crear un nuevo documento Excel
    final excel = Excel.createExcel();

    // Obtener ventas del período especificado o usar la lista proporcionada
    List<VentaModel> ventasReporte = [];

    if (ventas != null) {
      // Si se proporciona una lista de ventas, usarla directamente
      ventasReporte = ventas!;
    } else {
      // Si no hay lista predefinida, obtenerlas del servicio
      final Map<String, dynamic> result;

      if (fechaInicio != null && fechaFin != null) {
        // Buscar ventas en el rango de fechas
        final dynamicResult = await _ventasService.findByDateRange(
          fechaInicio!,
          fechaFin!,
        );
        result = Map<String, dynamic>.from(dynamicResult);
      } else {
        // Si no hay fechas, obtener todas las ventas
        final dynamicResult = await _ventasService.getAll();
        result = Map<String, dynamic>.from(dynamicResult);
      }

      if (result['error'] == true) {
        throw Exception(
          result['message'] ?? 'Error al obtener datos de ventas',
        );
      } else {
        // Fix the type casting issue
        ventasReporte = (result['data'] as List<dynamic>).cast<VentaModel>();
      }
    }

    // Eliminar la hoja por defecto y crear nuevas hojas para el reporte
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Crear hoja de resumen
    final sheetResumen = getOrCreateSheet(excel, 'Resumen');
    _createSummarySheet(sheetResumen, ventasReporte);

    // Crear hoja de detalles
    final sheetDetalles = getOrCreateSheet(excel, 'Detalles');
    _createDetailsSheet(sheetDetalles, ventasReporte);

    // Si hay ventas a plazos, crear una hoja para ellas
    final ventasAPlazo =
        ventasReporte.where((venta) => venta.esPagoAPlazo).toList();
    if (ventasAPlazo.isNotEmpty) {
      final sheetPlazos = getOrCreateSheet(excel, 'Ventas a Plazos');
      _createInstallmentSheet(sheetPlazos, ventasAPlazo);
    }

    return excel;
  }

  // Crear la hoja de resumen
  void _createSummarySheet(Sheet sheet, List<VentaModel> ventas) {
    // Configurar estilo para título
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
    );

    final subtitleStyle = CellStyle(
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
    );

    final dateFormat = DateFormat('dd/MM/yyyy');

    // Título del reporte
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'));
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('Reporte de Ventas');
    titleCell.cellStyle = titleStyle;

    // Período del reporte
    sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('F2'));
    final periodCell = sheet.cell(CellIndex.indexByString('A2'));
    String periodText = 'Todas las ventas';
    if (fechaInicio != null && fechaFin != null) {
      periodText =
          'Período: ${dateFormat.format(fechaInicio!)} al ${dateFormat.format(fechaFin!)}';
    }
    periodCell.value = TextCellValue(periodText);
    periodCell.cellStyle = subtitleStyle;

    // Fecha de generación
    sheet.merge(CellIndex.indexByString('A3'), CellIndex.indexByString('F3'));
    final dateCell = sheet.cell(CellIndex.indexByString('A3'));
    dateCell.value = TextCellValue('Generado el ${_getFormattedDateTime()}');
    dateCell.cellStyle = subtitleStyle;

    // Espacio antes de los datos
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('');

    // Calcular estadísticas generales
    int totalVentas = ventas.length;
    double ingresoTotal = 0;
    int totalProductosVendidos = 0;
    int ventasContado = 0;
    int ventasAPlazo = 0;
    double montoVentasContado = 0;
    double montoVentasAPlazo = 0;
    double montoPendientePago = 0;

    for (var venta in ventas) {
      ingresoTotal += venta.total;
      totalProductosVendidos += venta.cantidadProductos;

      if (venta.esPagoAPlazo) {
        ventasAPlazo++;
        montoVentasAPlazo += venta.total;
        montoPendientePago += venta.totalPendiente;
      } else {
        ventasContado++;
        montoVentasContado += venta.total;
      }
    }

    // Formatear números
    final numberFormat = NumberFormat('#,##0.00', 'es_MX');

    // Crear tabla de resumen
    final summaryData = [
      ['Total de ventas:', totalVentas.toString()],
      ['Ingreso total:', '\$${numberFormat.format(ingresoTotal)}'],
      ['Total productos vendidos:', totalProductosVendidos.toString()],
      [
        'Ventas de contado:',
        '$ventasContado (${_formatPercent(ventasContado, totalVentas)})',
      ],
      [
        'Monto ventas contado:',
        '\$${numberFormat.format(montoVentasContado)} (${_formatPercent(montoVentasContado, ingresoTotal)})',
      ],
      [
        'Ventas a plazos:',
        '$ventasAPlazo (${_formatPercent(ventasAPlazo, totalVentas)})',
      ],
      [
        'Monto ventas a plazos:',
        '\$${numberFormat.format(montoVentasAPlazo)} (${_formatPercent(montoVentasAPlazo, ingresoTotal)})',
      ],
      [
        'Monto pendiente de pago:',
        '\$${numberFormat.format(montoPendientePago)}',
      ],
    ];

    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    final summaryStyle = CellStyle(bold: true);

    // Agregar encabezados de resumen
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 5),
    );
    final summaryHeaderCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5),
    );
    summaryHeaderCell.value = TextCellValue('RESUMEN DE VENTAS');
    summaryHeaderCell.cellStyle = headerStyle;

    // Agregar filas de resumen
    for (var i = 0; i < summaryData.length; i++) {
      final row = summaryData[i];
      final rowIndex = i + 6;

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
      );
      final labelCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );
      labelCell.value = TextCellValue(row[0]);

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
      );
      final valueCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
      );
      valueCell.value = TextCellValue(row[1]);
      valueCell.cellStyle = summaryStyle;
    }

    // Ajustar anchos
    autoFitColumns(sheet, summaryData.length + 10, 6);
  }

  // Crear la hoja de detalles
  void _createDetailsSheet(Sheet sheet, List<VentaModel> ventas) {
    // Configurar estilo para título
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Título del reporte
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('J1'));
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('Detalle de Ventas');
    titleCell.cellStyle = titleStyle;

    // Espacio antes de los datos
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('');

    // Definir encabezados (quitando la columna ID)
    final headers = [
      'Fecha',
      'Cliente',
      'Teléfono',
      'Tipo',
      'Vendedor',
      'Productos',
      'Subtotal',
      'Descuento',
      'Total',
      'Estado',
    ];

    // Agregar encabezados
    _addColumnHeaders(sheet, headers, 2);

    // Estilo para las filas de datos
    final evenRowStyle = CellStyle();

    final dateFormat = DateFormat('dd/MM/yyyy');

    // Agregar cada venta como una fila
    for (var i = 0; i < ventas.length; i++) {
      final venta = ventas[i];
      final rowIndex = i + 3; // Empezar después de los encabezados y título
      final isEvenRow = i % 2 == 0;
      final cellStyle = isEvenRow ? evenRowStyle : null;

      // Calcular tipo de venta
      String tipoVenta = venta.esPagoAPlazo ? 'A plazos' : 'Contado';

      // Llenar la fila (sin incluir el ID)
      _setCellValue(
        sheet,
        0,
        rowIndex,
        dateFormat.format(venta.fechaVenta),
        cellStyle,
      );
      _setCellValue(
        sheet,
        1,
        rowIndex,
        venta.nombreCliente ?? 'N/A',
        cellStyle,
      );
      _setCellValue(
        sheet,
        2,
        rowIndex,
        venta.telefonoCliente ?? 'N/A',
        cellStyle,
      );
      _setCellValue(sheet, 3, rowIndex, tipoVenta, cellStyle);
      _setCellValue(sheet, 4, rowIndex, venta.vendedor, cellStyle);

      // Cantidad de productos como entero
      _setCellValue(sheet, 5, rowIndex, venta.cantidadProductos, cellStyle);

      // Valores monetarios como números con formato
      _setCellValue(
        sheet,
        6,
        rowIndex,
        venta.subtotal,
        cellStyle,
        isCurrency: true,
      );
      _setCellValue(
        sheet,
        7,
        rowIndex,
        venta.descuento,
        cellStyle,
        isCurrency: true,
      );
      _setCellValue(
        sheet,
        8,
        rowIndex,
        venta.total,
        cellStyle,
        isCurrency: true,
      );

      _setCellValue(sheet, 9, rowIndex, venta.estado, cellStyle);
    }

    // Ajustar anchos de columnas
    autoFitColumns(sheet, ventas.length + 3, headers.length);
  }

  // Crear la hoja de ventas a plazos
  void _createInstallmentSheet(Sheet sheet, List<VentaModel> ventas) {
    // Configurar estilo para título
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Título del reporte
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('I1'));
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('Detalle de Ventas a Plazos');
    titleCell.cellStyle = titleStyle;

    // Espacio antes de los datos
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('');

    // Definir encabezados (quitando la columna ID)
    final headers = [
      'Fecha',
      'Cliente',
      'Teléfono',
      'Monto Total',
      'Monto Inicial',
      'Total Pagado',
      'Pendiente',
      '% Pagado',
      'Estado',
    ];

    // Agregar encabezados con el nuevo método
    _addColumnHeaders(sheet, headers, 2);

    // Estilo para las filas de datos
    final evenRowStyle = CellStyle();

    // Estilo para destacar pendientes
    final pendingStyle = CellStyle(bold: true);

    // Estilo para pagados
    final paidStyle = CellStyle(bold: true);

    final dateFormat = DateFormat('dd/MM/yyyy');

    // Agregar cada venta a plazos como una fila
    for (var i = 0; i < ventas.length; i++) {
      final venta = ventas[i];
      final rowIndex = i + 3; // Empezar después de los encabezados y título
      final isEvenRow = i % 2 == 0;
      final baseCellStyle = isEvenRow ? evenRowStyle : null;

      // Calcular montos
      double totalPagado = venta.total - venta.totalPendiente;
      double porcentajePagado = totalPagado / venta.total;

      // Determinar estilo para el estado
      final statusStyle = venta.estaPagada ? paidStyle : pendingStyle;

      // Llenar la fila (sin incluir el ID)
      _setCellValue(
        sheet,
        0,
        rowIndex,
        dateFormat.format(venta.fechaVenta),
        baseCellStyle,
      );
      _setCellValue(
        sheet,
        1,
        rowIndex,
        venta.nombreCliente ?? 'N/A',
        baseCellStyle,
      );
      _setCellValue(
        sheet,
        2,
        rowIndex,
        venta.telefonoCliente ?? 'N/A',
        baseCellStyle,
      );

      // Valores monetarios como números con formato
      _setCellValue(
        sheet,
        3,
        rowIndex,
        venta.total,
        baseCellStyle,
        isCurrency: true,
      );
      _setCellValue(
        sheet,
        4,
        rowIndex,
        venta.montoInicial ?? 0,
        baseCellStyle,
        isCurrency: true,
      );
      _setCellValue(
        sheet,
        5,
        rowIndex,
        totalPagado,
        baseCellStyle,
        isCurrency: true,
      );
      _setCellValue(
        sheet,
        6,
        rowIndex,
        venta.totalPendiente,
        baseCellStyle,
        isCurrency: true,
      );

      // Porcentaje como valor numérico con formato
      _setCellValue(
        sheet,
        7,
        rowIndex,
        porcentajePagado,
        baseCellStyle,
        isPercent: true,
      );

      _setCellValue(
        sheet,
        8,
        rowIndex,
        venta.estaPagada ? 'Completado' : 'Pendiente',
        statusStyle,
      );
    }

    // Ajustar anchos de columnas
    autoFitColumns(sheet, ventas.length + 3, headers.length);
  }

  // Método auxiliar para establecer valor de celda con estilo
  // Actualizado para manejar diferentes tipos de datos correctamente
  void _setCellValue(
    Sheet sheet,
    int col,
    int row,
    dynamic value,
    CellStyle? style, {
    bool isCurrency = false,
    bool isPercent = false,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );

    // Manejar diferentes tipos de datos
    if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      if (isCurrency || isPercent) {
        // Para valores monetarios o porcentajes
        cell.value = DoubleCellValue(value);
        // Note: We can't use format parameter as it's not supported in this version
      } else {
        cell.value = DoubleCellValue(value);
      }
    } else if (value is DateTime) {
      // For DateTime values, extract year/month/day
      cell.value = DateCellValue(
        year: value.year,
        month: value.month,
        day: value.day,
      );
    } else {
      // Para strings y cualquier otro tipo
      cell.value = TextCellValue(value?.toString() ?? '');
    }

    // Aplicar estilo si se proporciona
    if (style != null) {
      cell.cellStyle = style;
    }
  }

  // Método auxiliar para formatear la fecha actual (para el nombre del archivo)
  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.day}_${now.month}_${now.year}';
  }

  // Método auxiliar para formatear fecha y hora (para dentro del reporte)
  String _getFormattedDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(now);
  }

  // Método para formatear porcentajes
  String _formatPercent(num value, num total) {
    if (total == 0) return '0%';
    final percent = (value / total) * 100;
    return '${percent.toStringAsFixed(1)}%';
  }

  // Método para agregar encabezados de columna con estilo
  void _addColumnHeaders(Sheet sheet, List<String> headers, int startRow) {
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
  }
}
