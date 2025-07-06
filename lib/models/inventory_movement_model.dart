import 'book_model.dart';

/// Tipo de movimiento de inventario
enum MovementType {
  /// Entrada de productos al inventario
  entrada,

  /// Salida de productos del inventario
  salida,

  /// Ajuste positivo de inventario (tras conteo físico)
  ajustePositivo,

  /// Ajuste negativo de inventario (tras conteo físico)
  ajusteNegativo,

  /// Devolución de productos
  devolucion,

  /// Transferencia entre ubicaciones
  transferencia,

  /// Producto dañado o caducado
  merma,

  /// Donación de productos
  donacion,
}

/// Modelo para representar entradas y salidas de inventario
class InventoryMovement {
  /// Identificador único del movimiento
  final String id;

  /// Identificador del libro relacionado
  final String bookId;

  /// Referencia opcional al objeto libro completo
  final Book? book;

  /// Tipo de movimiento (entrada o salida)
  final MovementType type;

  /// Cantidad de unidades en el movimiento
  final int quantity;

  /// Fecha y hora del movimiento
  final DateTime timestamp;

  /// Motivo o descripción del movimiento
  final String reason;

  /// Usuario que realizó el movimiento
  final String userId;

  InventoryMovement({
    required this.id,
    required this.bookId,
    this.book,
    required this.type,
    required this.quantity,
    required this.timestamp,
    this.reason = '',
    required this.userId,
  });

  /// Crea una instancia de InventoryMovement desde un mapa JSON
  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: json['id'] ?? '',
      bookId: json['bookId'] ?? '',
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
      type: _parseMovementType(json['type']),
      quantity: json['quantity'] ?? 0,
      timestamp:
          json['timestamp'] != null
              ? (json['timestamp'] is DateTime
                  ? json['timestamp']
                  : DateTime.parse(json['timestamp']))
              : DateTime.now(),
      reason: json['reason'] ?? '',
      userId: json['userId'] ?? '',
    );
  }

  /// Convierte esta instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'type': describeEnum(type),
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(),
      'reason': reason,
      'userId': userId,
    };
  }

  /// Crea una copia de este objeto con las propiedades especificadas reemplazadas
  InventoryMovement copyWith({
    String? id,
    String? bookId,
    Book? book,
    MovementType? type,
    int? quantity,
    DateTime? timestamp,
    String? reason,
    String? userId,
    String? documentNumber,
  }) {
    return InventoryMovement(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      book: book ?? this.book,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      timestamp: timestamp ?? this.timestamp,
      reason: reason ?? this.reason,
      userId: userId ?? this.userId,
    );
  }

  /// Convierte un string al enum MovementType
  static MovementType _parseMovementType(dynamic value) {
    if (value is MovementType) return value;

    final stringValue = value?.toString().toLowerCase() ?? '';

    switch (stringValue) {
      case 'entrada':
        return MovementType.entrada;
      case 'salida':
        return MovementType.salida;
      case 'ajustepositivo':
      case 'ajuste_positivo':
        return MovementType.ajustePositivo;
      case 'ajustenegativo':
      case 'ajuste_negativo':
        return MovementType.ajusteNegativo;
      case 'devolucion':
        return MovementType.devolucion;
      case 'transferencia':
        return MovementType.transferencia;
      case 'merma':
        return MovementType.merma;
      case 'donacion':
        return MovementType.donacion;
      default:
        return MovementType.entrada;
    }
  }
}

/// Función auxiliar para convertir enum a string
String describeEnum(Object enumEntry) {
  final String description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}
