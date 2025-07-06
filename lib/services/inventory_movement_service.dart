import '../firebase_provider/api_provider.dart';
import '../models/inventory_movement_model.dart';

class InventoryMovementService {
  static final FirebaseApiProvider fireProvider = FirebaseApiProvider(
    idProject: 'pandevida-td',
    model: 'inventory_movements',
  );

  // Obtener todos los movimientos de inventario
  Future<Map> getAll() async {
    List<InventoryMovement> movements = [];
    Map<String, dynamic> data = await fireProvider.getAll();

    if (data['error']) {
      return data;
    } else {
      data['data'].forEach((key, value) {
        // Se asigna la key como id para tener la referencia en Firebase
        var movementData = value;
        movementData['id'] = key;
        movements.add(InventoryMovement.fromJson(movementData));
      });
      return {'error': false, 'data': movements};
    }
  }

  // Obtener un movimiento por su ID
  Future<InventoryMovement> getById(String id) async {
    Map<String, dynamic> data = await fireProvider.get(id);
    data['id'] = id; // Aseguramos que el ID esté presente
    return InventoryMovement.fromJson(data);
  }

  // Agregar un nuevo movimiento de inventario
  Future<Map<String, dynamic>> add(InventoryMovement movement) async {
    try {
      var movementData = movement.toJson();
      // Eliminamos el ID del objeto si está vacío para que Firebase genere uno automático
      if (movement.id.isEmpty) {
        movementData.remove('id');
      }
      return await fireProvider.add(movementData);
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // Actualizar un movimiento existente
  Future<Map<String, dynamic>> update(InventoryMovement movement) async {
    try {
      return await fireProvider.update(movement.id, movement.toJson());
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // Eliminar un movimiento
  Future<Map<String, dynamic>> delete(String id) async {
    return await fireProvider.delete(id);
  }

  // Obtener los movimientos por libro
  Future<Map<String, dynamic>> getByBookId(String bookId) async {
    try {
      final results = await fireProvider.queryByFieldFormatted(
        field: 'bookId',
        value: bookId,
      );

      if (results.isEmpty) {
        return {
          'error': true,
          'message': 'No se encontraron movimientos para el libro ID: $bookId',
        };
      }

      List<InventoryMovement> movements =
          results.map((data) => InventoryMovement.fromJson(data)).toList();

      return {'error': false, 'data': movements};
    } catch (e) {
      return {
        'error': true,
        'message': 'Error al buscar movimientos por libro: ${e.toString()}',
      };
    }
  }

  // Obtener movimientos por tipo
  Future<Map<String, dynamic>> getByType(MovementType type) async {
    try {
      final results = await fireProvider.queryByFieldFormatted(
        field: 'type',
        value: describeEnum(type),
      );

      if (results.isEmpty) {
        return {
          'error': true,
          'message':
              'No se encontraron movimientos del tipo: ${describeEnum(type)}',
        };
      }

      List<InventoryMovement> movements =
          results.map((data) => InventoryMovement.fromJson(data)).toList();

      return {'error': false, 'data': movements};
    } catch (e) {
      return {
        'error': true,
        'message': 'Error al buscar movimientos por tipo: ${e.toString()}',
      };
    }
  }

  // Obtener movimientos por rango de fechas
  Future<Map<String, dynamic>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Primero obtenemos todos los movimientos
      final allMovementsResult = await getAll();

      if (allMovementsResult['error'] == true) {
        return allMovementsResult as Map<String, dynamic>;
      }

      final List<InventoryMovement> allMovements = allMovementsResult['data'];

      if (allMovements.isEmpty) {
        return {
          'error': true,
          'message': 'No hay movimientos disponibles para filtrar',
        };
      }

      // Filtramos los movimientos que están dentro del rango de fechas
      final List<InventoryMovement> filteredMovements =
          allMovements
              .where(
                (movement) =>
                    movement.timestamp.isAfter(startDate) &&
                    movement.timestamp.isBefore(
                      endDate.add(const Duration(days: 1)),
                    ),
              )
              .toList();

      if (filteredMovements.isEmpty) {
        return {
          'error': true,
          'message':
              'No se encontraron movimientos en el rango de fechas especificado',
        };
      }

      return {'error': false, 'data': filteredMovements};
    } catch (e) {
      return {
        'error': true,
        'message':
            'Error al buscar movimientos por rango de fechas: ${e.toString()}',
      };
    }
  }
}
