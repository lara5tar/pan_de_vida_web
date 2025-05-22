import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../models/book_model.dart';
import '../services/books_service.dart';
import 'excel_report_base.dart';

class InventoryExcelReport extends ExcelReportBase {
  final BooksService _booksService = BooksService();
  final String? sortBy;
  final bool descending;

  InventoryExcelReport({this.sortBy, this.descending = false});

  // Sobrescribir el nombre del archivo
  @override
  String get fileName => 'inventario_libros_${_getFormattedDate()}.xlsx';

  // Generar el contenido específico para el reporte de inventario
  @override
  Future<Excel> generateContent() async {
    // Crear un nuevo documento Excel
    final excel = Excel.createExcel();

    // Obtener todos los libros
    final result = await _booksService.getAll();
    if (result['error']) {
      throw Exception(
        result['message'] ?? 'Error al obtener datos del inventario',
      );
    }

    final List<Book> books = result['data'];

    // Ordenar los libros si se especifica un campo
    if (sortBy != null) {
      _sortBooks(books, sortBy!, descending);
    }

    // Primero creamos nuestra hoja de Inventario
    final Sheet sheet = excel['Inventario'];

    // Obtenemos la lista de hojas actuales
    final defaultSheets = excel.sheets.keys.toList();

    // Eliminamos todas las hojas excepto la de Inventario
    for (var sheetName in defaultSheets) {
      if (sheetName != 'Inventario') {
        excel.delete(sheetName);
      }
    }

    // Agregar información del reporte
    _addReportInfo(sheet);

    // Definir y agregar encabezados (quitando la columna ID)
    final headers = [
      'Nombre',
      'Código de Barras',
      'Precio',
      'Stock',
      'Valor Total',
    ];
    _addColumnHeaders(sheet, headers);

    // Agregar filas de datos
    _addBookRows(sheet, books);

    // Agregar resumen
    _addSummary(sheet, books);

    // Ajustar anchos de columnas
    autoFitColumns(
      sheet,
      books.length + 7,
      headers.length,
    ); // +7 para incluir encabezados y resumen

    return excel;
  }

  // Agregar información del reporte
  void _addReportInfo(Sheet sheet) {
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

    // Título del reporte (fusionar celdas A1:F1)
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'));
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('Reporte de Inventario de Libros');
    titleCell.cellStyle = titleStyle;

    // Fecha y hora del reporte (fusionar celdas A2:F2)
    sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('F2'));
    final dateCell = sheet.cell(CellIndex.indexByString('A2'));
    dateCell.value = TextCellValue('Generado el ${_getFormattedDateTime()}');
    dateCell.cellStyle = subtitleStyle;

    // Espacio antes de los encabezados
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('');
  }

  // Agregar encabezados de columnas
  void _addColumnHeaders(Sheet sheet, List<String> headers) {
    // Configurar estilo para los encabezados
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      // Eliminamos backgroundColorHex que causa el error de tipo
      verticalAlign: VerticalAlign.Center,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 12,
    );

    // La fila 4 es donde comenzarán los encabezados (después del título y espacio)
    final headerRowIndex = 3;

    // Agregar cada encabezado
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIndex),
      );
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }
  }

  // Método auxiliar para convertir color hexadecimal a ExcelColor
  String getColorFromHex(String hex) {
    // El paquete Excel acepta colores en formato hexadecimal como String directamente
    return hex.replaceAll('#', '');
  }

  // Método auxiliar para obtener familia de fuente
  String getFontFamily(FontFamily fontFamily) {
    switch (fontFamily) {
      case FontFamily.Calibri:
        return 'Calibri';
      case FontFamily.Arial:
        return 'Arial';
      default:
        return 'Calibri';
    }
  }

  // Agregar filas de datos de los libros
  void _addBookRows(Sheet sheet, List<Book> books) {
    // Estilo para las filas de datos - Fix ExcelColor issue
    final evenRowStyle = CellStyle();
    // Note: We'll set background colors in a way compatible with the Excel package

    // Agregar cada libro como una fila
    for (var i = 0; i < books.length; i++) {
      final book = books[i];
      final rowIndex = i + 4; // Empezar después de los encabezados y el título
      final isEvenRow = i % 2 == 0;
      final cellStyle = isEvenRow ? evenRowStyle : null;

      // Calcular el valor total (precio * stock)
      final totalValue = book.precio * book.cantidadEnStock;

      // Llenar la fila
      _setCellValue(sheet, 0, rowIndex, book.nombre, cellStyle);
      _setCellValue(sheet, 1, rowIndex, book.codigoBarras, cellStyle);
      _setCellValue(
        sheet,
        2,
        rowIndex,
        book.precio,
        cellStyle,
        isCurrency: true,
      );
      _setCellValue(sheet, 3, rowIndex, book.cantidadEnStock, cellStyle);
      _setCellValue(
        sheet,
        4,
        rowIndex,
        totalValue,
        cellStyle,
        isCurrency: true,
      );
    }
  }

  // Agregar resumen al final del reporte
  void _addSummary(Sheet sheet, List<Book> books) {
    final totalRowIndex = books.length + 5; // Posición para la fila de totales

    // Estilo para la fila de totales
    final totalStyle = CellStyle(bold: true);
    // Note: We cannot use backgroundColorHex with ExcelColor directly

    // Calcular totales
    int totalItems = 0;
    double totalValue = 0.0;

    for (var book in books) {
      totalItems += book.cantidadEnStock;
      totalValue += book.precio * book.cantidadEnStock;
    }

    // Agregar fila de totales
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRowIndex),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRowIndex),
    );

    final totalLabelCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRowIndex),
    );
    totalLabelCell.value = TextCellValue('TOTALES:');
    totalLabelCell.cellStyle = totalStyle;

    final totalItemsCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRowIndex),
    );
    totalItemsCell.value = IntCellValue(totalItems);
    totalItemsCell.cellStyle = totalStyle;

    final totalValueCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRowIndex),
    );
    totalValueCell.value = DoubleCellValue(totalValue);
    totalValueCell.cellStyle = totalStyle;
  }

  // Método auxiliar para establecer valor de celda con estilo
  void _setCellValue(
    Sheet sheet,
    int col,
    int row,
    dynamic value,
    CellStyle? style, {
    bool isCurrency = false,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );

    // Determinar el tipo apropiado de CellValue según el valor
    if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      if (isCurrency) {
        // Para valores monetarios
        cell.value = DoubleCellValue(value);
        // We'll format the cell display outside of the constructor
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
      // Valor por defecto como texto
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

  // Método para ordenar los libros según el campo especificado
  void _sortBooks(List<Book> books, String field, bool descending) {
    books.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (field) {
        case 'nombre':
          valueA = a.nombre;
          valueB = b.nombre;
          break;
        case 'precio':
          valueA = a.precio;
          valueB = b.precio;
          break;
        case 'stock':
          valueA = a.cantidadEnStock;
          valueB = b.cantidadEnStock;
          break;
        case 'valor':
          valueA = a.precio * a.cantidadEnStock;
          valueB = b.precio * b.cantidadEnStock;
          break;
        case 'codigo':
          valueA = a.codigoBarras;
          valueB = b.codigoBarras;
          break;
        default:
          valueA = a.nombre;
          valueB = b.nombre;
      }

      // Comparar los valores
      int comparison;
      if (valueA is String && valueB is String) {
        comparison = valueA.toLowerCase().compareTo(valueB.toLowerCase());
      } else if (valueA is num && valueB is num) {
        comparison = valueA.compareTo(valueB);
      } else {
        comparison = 0;
      }

      // Invertir el orden si es descendente
      return descending ? -comparison : comparison;
    });
  }
}
