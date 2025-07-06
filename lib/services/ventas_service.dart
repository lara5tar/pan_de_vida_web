import '../firebase_provider/api_provider.dart';
import '../models/venta_model.dart';

class VentasService {
  static final FirebaseApiProvider fireProvider = FirebaseApiProvider(
    idProject: 'pandevida-td',
    model: 'ventas',
  );

  // Obtener todas las ventas
  Future<Map> getAll() async {
    List<VentaModel> ventas = [];
    Map<String, dynamic> data = await fireProvider.getAll();

    if (data['error'] == true) {
      return data;
    } else {
      // Si la estructura contiene 'documents', estamos recibiendo formato Firestore API
      if (data['data'] != null && data['data']['documents'] != null) {
        // Procesar documentos en formato Firestore API
        List<dynamic> documents = data['data']['documents'];
        for (var doc in documents) {
          // Asegurarnos de que el documento es un Map<String, dynamic>
          if (doc is Map) {
            Map<String, dynamic> docMap = {};
            doc.forEach((key, value) {
              docMap[key.toString()] = value;
            });
            // Procesamos cada documento con el helper
            Map<String, dynamic> processedData = fireProvider
                .processFirestoreDocument(docMap);
            ventas.add(VentaModel.fromJson(processedData));
          }
        }
      } else {
        // Si es el formato actual (clave-valor)
        data['data'].forEach((key, value) {
          // Verificamos si el valor tiene estructura Firestore con 'fields'
          if (value is Map) {
            // Convertir explícitamente a Map<String, dynamic>
            Map<String, dynamic> valueMap = {};
            value.forEach((k, v) {
              valueMap[k.toString()] = v;
            });

            if (valueMap.containsKey('fields')) {
              // Procesamos el documento
              Map<String, dynamic> processedData = fireProvider
                  .processFirestoreDocument(valueMap);
              processedData['id'] = key; // Aseguramos que el ID esté presente
              ventas.add(VentaModel.fromJson(processedData));
            } else {
              // Formato actual sin estructura Firestore
              valueMap['id'] = key;
              ventas.add(VentaModel.fromJson(valueMap));
            }
          }
        });
      }
      return {'error': false, 'data': ventas};
    }
  }

  // Obtener una venta por su ID
  Future<VentaModel> getById(String id) async {
    try {
      // Obtenemos los datos directamente de Firebase
      Map<String, dynamic> rawData = await fireProvider.get(id);

      // Primero verificar si la respuesta contiene datos en 'data'
      if (rawData.containsKey('data')) {
        // Si usa la estructura con 'error', 'statusCode', 'message', 'data'
        Map<String, dynamic> ventaData = rawData['data'];

        // Ya viene en formato procesado, usarlo directamente
        ventaData['id'] = id; // Aseguramos que el ID esté presente
        return VentaModel.fromJson(ventaData);
      }
      // Si el documento tiene la estructura de Firestore (con 'fields')
      else if (rawData.containsKey('fields')) {
        // Procesamos el documento usando el helper de FirestoreApiProvider
        Map<String, dynamic> processedData = fireProvider
            .processFirestoreDocument(rawData);
        processedData['id'] = id; // Aseguramos que el ID esté presente
        return VentaModel.fromJson(processedData);
      } else {
        // Si ya viene en formato procesado o tiene otra estructura
        rawData['id'] = id;
        return VentaModel.fromJson(rawData);
      }
    } catch (e) {
      // Creamos un modelo vacío en caso de error
      return VentaModel(
        id: id,
        items: [],
        fechaVenta: DateTime.now(),
        subtotal: 0,
        descuento: 0,
        total: 0,
        vendedor: '',
      );
    }
  }

  // Crear una nueva venta (usando ID automático)
  Future<Map<String, dynamic>> add(VentaModel venta) async {
    try {
      // Se usa add() para generar ID automático
      var ventaData = venta.toJson();
      // Eliminamos el ID del objeto si está vacío para que Firebase genere uno automático
      if (venta.id.isEmpty) {
        ventaData.remove('id');
      }
      return await fireProvider.add(ventaData);
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // Actualizar una venta existente
  Future<Map<String, dynamic>> update(VentaModel venta) async {
    try {
      return await fireProvider.update(venta.id, venta.toJson());
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // Eliminar una venta
  Future<Map<String, dynamic>> delete(String id) async {
    return await fireProvider.delete(id);
  }

  // Buscar ventas por fecha
  Future<Map<String, dynamic>> findByDate(DateTime fecha) async {
    try {
      // Convertir la fecha a formato ISO para comparar solo el día
      String fechaISO = fecha.toIso8601String().split('T')[0];

      // Usar queryByFieldFormatted para buscar directamente en Firestore
      // Como Firestore almacena fechaVenta como string ISO 8601, buscamos por el prefijo del día
      List<Map<String, dynamic>>
      result = await fireProvider.queryByFieldFormatted(
        field: 'fechaVenta',
        // Usamos el prefijo del día, para que coincida con cualquier hora de ese día
        value: fechaISO,
      );

      // Si no se encontraron resultados con el método optimizado, usar el método alternativo
      if (result.isEmpty) {
        return await _findByDateAlternative(fecha);
      }

      // Convertir los documentos a objetos VentaModel
      List<VentaModel> ventasFiltradas =
          result.map((doc) => VentaModel.fromJson(doc)).toList();

      if (ventasFiltradas.isEmpty) {
        return {
          'error': true,
          'message':
              'No se encontraron ventas para la fecha: ${fecha.toString().split(' ')[0]}',
        };
      }

      return {'error': false, 'data': ventasFiltradas};
    } catch (e) {
      // Si hay un error, usamos el método alternativo
      return await _findByDateAlternative(fecha);
    }
  }

  // Método alternativo que usa getAll y filtra localmente (el método original)
  Future<Map<String, dynamic>> _findByDateAlternative(DateTime fecha) async {
    try {
      // Convertir la fecha a formato ISO para comparar solo el día
      String fechaISO = fecha.toIso8601String().split('T')[0];

      // Obtenemos todas las ventas y luego filtramos por fecha
      final allVentasResult = await getAll();

      if (allVentasResult['error'] == true) {
        return allVentasResult as Map<String, dynamic>;
      }

      final List<VentaModel> allVentas = allVentasResult['data'];

      // Filtramos ventas que coincidan con la fecha (solo comparando día)
      final List<VentaModel> ventasFiltradas =
          allVentas.where((venta) {
            String ventaFechaISO =
                venta.fechaVenta.toIso8601String().split('T')[0];
            return ventaFechaISO == fechaISO;
          }).toList();

      if (ventasFiltradas.isEmpty) {
        return {
          'error': true,
          'message':
              'No se encontraron ventas para la fecha: ${fecha.toString().split(' ')[0]}',
        };
      }

      return {'error': false, 'data': ventasFiltradas};
    } catch (e) {
      return {
        'error': true,
        'message': 'Error al buscar ventas por fecha: ${e.toString()}',
      };
    }
  }

  // Buscar ventas por nombre del cliente
  Future<Map<String, dynamic>> findByClientName(String clientName) async {
    try {
      final allVentasResult = await getAll();

      if (allVentasResult['error'] == true) {
        return allVentasResult as Map<String, dynamic>;
      }

      final List<VentaModel> allVentas = allVentasResult['data'];

      // Convertimos el término de búsqueda a minúsculas
      final lowercaseSearchTerm = clientName.toLowerCase();

      // Filtramos ventas que contengan el nombre del cliente
      final List<VentaModel> ventasFiltradas =
          allVentas.where((venta) {
            return venta.nombreCliente != null &&
                venta.nombreCliente!.toLowerCase().contains(
                  lowercaseSearchTerm,
                );
          }).toList();

      if (ventasFiltradas.isEmpty) {
        return {
          'error': true,
          'message': 'No se encontraron ventas para el cliente: $clientName',
        };
      }

      return {'error': false, 'data': ventasFiltradas};
    } catch (e) {
      return {
        'error': true,
        'message': 'Error al buscar ventas por cliente: ${e.toString()}',
      };
    }
  }

  // Buscar ventas a plazos que tengan pagos pendientes
  Future<Map<String, dynamic>> findVentasConPagosPendientes() async {
    try {
      final allVentasResult = await getAll();

      if (allVentasResult['error'] == true) {
        return allVentasResult as Map<String, dynamic>;
      }

      final List<VentaModel> allVentas = allVentasResult['data'];

      // Filtramos ventas a plazos que no estén pagadas completamente
      final List<VentaModel> ventasPendientes =
          allVentas.where((venta) {
            return venta.esPagoAPlazo && !venta.estaPagada;
          }).toList();

      if (ventasPendientes.isEmpty) {
        return {
          'error': true,
          'message': 'No se encontraron ventas con pagos pendientes',
        };
      }

      return {'error': false, 'data': ventasPendientes};
    } catch (e) {
      return {
        'error': true,
        'message':
            'Error al buscar ventas con pagos pendientes: ${e.toString()}',
      };
    }
  }

  // Buscar ventas por vendedor
  Future<Map<String, dynamic>> findByVendedor(String vendedor) async {
    try {
      final allVentasResult = await getAll();

      if (allVentasResult['error'] == true) {
        return allVentasResult as Map<String, dynamic>;
      }

      final List<VentaModel> allVentas = allVentasResult['data'];

      // Convertimos el término de búsqueda a minúsculas
      final lowercaseSearchTerm = vendedor.toLowerCase();

      // Filtramos ventas por vendedor
      final List<VentaModel> ventasFiltradas =
          allVentas.where((venta) {
            return venta.vendedor.toLowerCase().contains(lowercaseSearchTerm);
          }).toList();

      if (ventasFiltradas.isEmpty) {
        return {
          'error': true,
          'message': 'No se encontraron ventas para el vendedor: $vendedor',
        };
      }

      return {'error': false, 'data': ventasFiltradas};
    } catch (e) {
      return {
        'error': true,
        'message': 'Error al buscar ventas por vendedor: ${e.toString()}',
      };
    }
  }

  // Buscar ventas por rango de fechas
  Future<Map<String, dynamic>> findByDateRange(
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      final allVentasResult = await getAll();

      if (allVentasResult['error'] == true) {
        return allVentasResult as Map<String, dynamic>;
      }

      final List<VentaModel> allVentas = allVentasResult['data'];

      // Normalizamos las fechas para tener solo la parte de fecha
      final DateTime startDate = DateTime(
        fechaInicio.year,
        fechaInicio.month,
        fechaInicio.day,
      );
      final DateTime endDate = DateTime(
        fechaFin.year,
        fechaFin.month,
        fechaFin.day,
        23,
        59,
        59,
      );

      // Filtramos ventas dentro del rango de fechas
      final List<VentaModel> ventasFiltradas =
          allVentas.where((venta) {
            return venta.fechaVenta.isAfter(startDate) &&
                venta.fechaVenta.isBefore(endDate);
          }).toList();

      if (ventasFiltradas.isEmpty) {
        return {
          'error': true,
          'message':
              'No se encontraron ventas entre ${startDate.toString().split(' ')[0]} y ${endDate.toString().split(' ')[0]}',
        };
      }

      return {'error': false, 'data': ventasFiltradas};
    } catch (e) {
      return {
        'error': true,
        'message':
            'Error al buscar ventas por rango de fechas: ${e.toString()}',
      };
    }
  }

  // Registrar un nuevo pago para una venta a plazos
  Future<Map<String, dynamic>> registrarPago(
    String ventaId,
    Pago nuevoPago,
  ) async {
    try {
      // Enfoque alternativo: obtener la venta actual como objeto VentaModel
      VentaModel venta = await getById(ventaId);

      // Agregar el nuevo pago a la lista existente de pagos
      List<Pago> pagosActualizados = List.from(venta.pagos);
      pagosActualizados.add(nuevoPago);

      // Crear una venta actualizada usando copyWith para preservar todos los campos
      VentaModel ventaActualizada = venta.copyWith(
        pagos: pagosActualizados,
        esPagoAPlazo: true,
      );

      // Convertir todo el objeto a JSON para la actualización completa
      final ventaData = ventaActualizada.toJson();

      // Usar update normal que reemplaza todo el documento con datos completos
      return await fireProvider.update(ventaId, ventaData);
    } catch (e) {
      return {
        'error': true,
        'message': 'Error al registrar pago: ${e.toString()}',
      };
    }
  }

  // Actualizar estado de una venta
  Future<Map<String, dynamic>> actualizarEstado(
    String ventaId,
    String nuevoEstado,
  ) async {
    try {
      VentaModel venta = await getById(ventaId);

      // Crear una versión actualizada de la venta con el nuevo estado
      VentaModel ventaActualizada = venta.copyWith(estado: nuevoEstado);

      // Actualizar la venta en la base de datos
      return await update(ventaActualizada);
    } catch (e) {
      return {
        'error': true,
        'message': 'Error al actualizar estado: ${e.toString()}',
      };
    }
  }

  // Obtener ventas con envío usando queryByField
  Future<Map<String, dynamic>> getVentasConEnvio() async {
    try {
      // Usar queryByFieldFormatted para obtener solo las ventas con envío
      // Este método devuelve una List<Map<String, dynamic>>, no un Map
      final List<Map<String, dynamic>> result = await fireProvider
          .queryByFieldFormatted(field: 'esEnvio', value: 'true');

      // Convertir los documentos a objetos VentaModel
      List<VentaModel> ventasConEnvio = [];

      for (var doc in result) {
        ventasConEnvio.add(VentaModel.fromJson(doc));
      }

      return {'error': false, 'data': ventasConEnvio};
    } catch (e) {
      // Si hay un error, usamos el método alternativo
      return {
        'error': true,
        'message': 'Error al buscar ventas con envío: ${e.toString()}',
      };
    }
  }

  // Actualizar la evidencia de envío de una venta
  Future<Map<String, dynamic>> actualizarEvidenciaEnvio(
    String ventaId,
    String evidenciaUrl,
  ) async {
    try {
      // Obtener la venta actual
      VentaModel venta = await getById(ventaId);

      // Actualizar sólo el campo de evidencia de envío
      VentaModel ventaActualizada = venta.copyWith(
        evidenciaEnvio: evidenciaUrl,
      );

      // Actualizar la venta en la base de datos
      return await update(ventaActualizada);
    } catch (e) {
      return {
        'error': true,
        'message': 'Error al actualizar evidencia de envío: ${e.toString()}',
      };
    }
  }
}
