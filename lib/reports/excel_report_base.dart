import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

// Clase abstracta que servirá como base para todos los tipos de reportes Excel
abstract class ExcelReportBase {
  // Nombre de archivo por defecto que se puede sobrescribir en las clases hijas
  String get fileName => 'reporte.xlsx';

  // Método abstracto que debe implementar cada tipo de reporte
  // para generar su propio contenido específico
  Future<Excel> generateContent();

  // Método para generar y descargar el reporte
  Future<bool> generateAndDownload(BuildContext context) async {
    try {
      // Mostrar indicador de carga
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Generando reporte...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Generar el contenido específico del reporte (implementado en las subclases)
      final excel = await generateContent();

      // Guardar y descargar el archivo
      await _saveAndDownload(excel);

      // Verificar que el contexto todavía sea válido
      if (!context.mounted) return true;

      // Notificar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte $fileName generado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      return true;
    } catch (e) {
      // Verificar que el contexto todavía sea válido
      if (!context.mounted) return false;

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Método para guardar y descargar el archivo Excel
  Future<void> _saveAndDownload(Excel excel) async {
    // Convertir a bytes
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('No se pudo codificar el archivo Excel');
    }

    if (kIsWeb) {
      // En web, descarga el archivo directamente al navegador
      _downloadForWeb(bytes);
    }
    // No handling for non-web platforms as they are handled by the parent method
  }

  // Método para descargar en web
  void _downloadForWeb(List<int> bytes) {
    if (kIsWeb) {
      // Crear un blob a partir de los bytes
      final blob = html.Blob([bytes]);

      // Crear URL para el blob
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Crear un elemento anchor para la descarga
      final anchor =
          html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..style.display = 'none';

      // Agregar al DOM, hacer clic y luego limpiar
      html.document.body!.children.add(anchor);
      anchor.click();

      // Eliminar el elemento y liberar la URL
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    }
  }

  // Métodos de utilidad que pueden usar las clases hijas

  // Crear una nueva hoja o usar una existente
  Sheet getOrCreateSheet(Excel excel, String name) {
    if (excel.sheets.containsKey(name)) {
      return excel.sheets[name]!;
    }
    return excel[name];
  }

  // Agregar encabezado con estilo
  void addHeader(Sheet sheet, List<String> headers) {
    // Agregar encabezados
    for (int col = 0; col < headers.length; col++) {
      // Create a cell value
      final cellValue = TextCellValue(headers[col]);

      // Apply styling properties
      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Use updateCell to set both value and style at once
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        cellValue,
        cellStyle: headerStyle,
      );
    }
  }

  // Ajustar el ancho de las columnas basado en el contenido
  void autoFitColumns(Sheet sheet, int rowCount, int colCount) {
    for (int col = 0; col < colCount; col++) {
      double maxWidth = 12.0; // Ancho mínimo por defecto

      for (int row = 0; row < rowCount; row++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        if (cell.value is TextCellValue) {
          final textValue = (cell.value as TextCellValue).value;
          // Fix for accessing the length property
          final length = textValue.toString().length;
          maxWidth = maxWidth > length ? maxWidth : length.toDouble();
        }
      }

      // Establecer ancho de columna
      sheet.setColumnWidth(
        col,
        maxWidth + 4,
      ); // Añadir un poco de espacio extra
    }
  }
}
