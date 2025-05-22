class Book {
  final String id;
  final String nombre;
  final double precio;
  final int cantidadEnStock;
  final String codigoBarras;

  Book({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidadEnStock,
    this.codigoBarras = '',
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      precio: (json['precio'] ?? 0.0).toDouble(),
      cantidadEnStock: json['cantidadEnStock'] ?? 0,
      codigoBarras: json['codigoBarras'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'cantidadEnStock': cantidadEnStock,
      'codigoBarras': codigoBarras,
    };
  }

  Book copyWith({
    String? id,
    String? nombre,
    double? precio,
    int? cantidadEnStock,
    String? codigoBarras,
  }) {
    return Book(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      cantidadEnStock: cantidadEnStock ?? this.cantidadEnStock,
      codigoBarras: codigoBarras ?? this.codigoBarras,
    );
  }
}
