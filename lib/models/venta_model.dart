// Modelo para representar los artículos en una venta
class ItemVenta {
  final String idLibro;
  final String nombreLibro;
  final double precioUnitario;
  final int cantidad;
  final double subtotal; // precio * cantidad

  ItemVenta({
    required this.idLibro,
    required this.nombreLibro,
    required this.precioUnitario,
    required this.cantidad,
    required this.subtotal,
  });

  factory ItemVenta.fromJson(Map<String, dynamic> json) {
    return ItemVenta(
      idLibro: json['idLibro'] ?? '',
      nombreLibro: json['nombreLibro'] ?? '',
      precioUnitario: (json['precioUnitario'] ?? 0.0).toDouble(),
      cantidad: json['cantidad'] ?? 0,
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idLibro': idLibro,
      'nombreLibro': nombreLibro,
      'precioUnitario': precioUnitario,
      'cantidad': cantidad,
      'subtotal': subtotal,
    };
  }
}

// Modelo para representar pagos a plazos
class Pago {
  final String id;
  final double monto;
  final DateTime fecha;
  final String? comprobante; // URL de la imagen del comprobante
  final bool pagado;
  final String? comentarios;

  Pago({
    required this.id,
    required this.monto,
    required this.fecha,
    this.comprobante,
    this.pagado = false,
    this.comentarios,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'] ?? '',
      monto: (json['monto'] ?? 0.0).toDouble(),
      fecha:
          json['fecha'] != null
              ? DateTime.parse(json['fecha'])
              : DateTime.now(),
      comprobante: json['comprobante'],
      pagado: json['pagado'] ?? false,
      comentarios: json['comentarios'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'comprobante': comprobante,
      'pagado': pagado,
      'comentarios': comentarios,
    };
  }
}

// Modelo principal de venta
class VentaModel {
  //este id se obtinee de firebase, al momentoo de crear la venta no se le asigna
  final String id;
  // son los libros que se vendieron
  final List<ItemVenta> items;
  // fecha en que se realizó la venta
  final DateTime fechaVenta;
  final double subtotal;
  // este tendra el valor del descuento aplicado, por ejemplo 10% de 100, seria 10, siempre seria descuentso de 30% para abajo,
  final double descuento;
  final double total;

  // Información del cliente
  //la informacion del cliente solo se toma si es pago a plazos
  final bool esPagoAPlazo;
  final String? nombreCliente;
  final String? telefonoCliente;
  // es proveedor solo es un parametro para saber si es venta a mayorista o no, en la vista lo mostraremos como es mayorista?
  final bool esProveedor;

  // Información de pago

  // es pago a plazos solo se toma si es pago a plazos
  final List<Pago> pagos;
  final double? montoInicial;
  final String? comprobanteInicial; // URL de la imagen del comprobante inicial

  // Información de envío
  final bool esEnvio;
  final String? numeroEnvio;
  final double? costoEnvio;
  final String? direccionEnvio;
  final String? evidenciaEnvio; // URL de la imagen del comprobante de envío

  // Información administrativa
  final String vendedor; //ID del vendedor
  final String? sucursal; // Ubicación o sucursal donde se realizó la venta
  final String estado; // "Completada", "Pendiente", "Cancelada"
  final String? notas; // Notas adicionales sobre la venta

  VentaModel({
    required this.id,
    required this.items,
    required this.fechaVenta,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.vendedor,
    this.nombreCliente,
    this.telefonoCliente,
    this.esProveedor = false,
    this.esPagoAPlazo = false,
    this.pagos = const [],
    this.montoInicial,
    this.comprobanteInicial,
    this.esEnvio = false,
    this.numeroEnvio,
    this.costoEnvio,
    this.direccionEnvio,
    this.evidenciaEnvio,
    this.sucursal,
    this.estado = 'Completada',
    this.notas,
  });

  factory VentaModel.fromJson(Map<String, dynamic> json) {
    List<ItemVenta> itemsList = [];
    if (json['items'] != null) {
      itemsList =
          (json['items'] as List)
              .map((item) => ItemVenta.fromJson(item))
              .toList();
    }

    List<Pago> pagosList = [];
    if (json['pagos'] != null) {
      pagosList =
          (json['pagos'] as List).map((pago) => Pago.fromJson(pago)).toList();
    }

    return VentaModel(
      id: json['id'] ?? '',
      items: itemsList,
      fechaVenta:
          json['fechaVenta'] != null
              ? DateTime.parse(json['fechaVenta'])
              : DateTime.now(),
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      descuento: (json['descuento'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      vendedor: json['vendedor'] ?? '',
      nombreCliente: json['nombreCliente'],
      telefonoCliente: json['telefonoCliente'],
      esProveedor: json['esProveedor'] ?? false,
      esPagoAPlazo: json['esPagoAPlazo'] ?? false,
      pagos: pagosList,
      montoInicial:
          json['montoInicial'] != null
              ? (json['montoInicial'] as num).toDouble()
              : null,
      comprobanteInicial: json['comprobanteInicial'],
      esEnvio: json['esEnvio'] ?? false,
      numeroEnvio: json['numeroEnvio'],
      costoEnvio:
          json['costoEnvio'] != null
              ? (json['costoEnvio'] as num).toDouble()
              : null,
      direccionEnvio: json['direccionEnvio'],
      evidenciaEnvio: json['evidenciaEnvio'],
      sucursal: json['sucursal'],
      estado: json['estado'] ?? 'Completada',
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'fechaVenta': fechaVenta.toIso8601String(),
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,
      'vendedor': vendedor,
      'nombreCliente': nombreCliente,
      'telefonoCliente': telefonoCliente,
      'esProveedor': esProveedor,
      'esPagoAPlazo': esPagoAPlazo,
      'pagos': pagos.map((pago) => pago.toJson()).toList(),
      'montoInicial': montoInicial,
      'comprobanteInicial': comprobanteInicial,
      'esEnvio': esEnvio,
      'numeroEnvio': numeroEnvio,
      'costoEnvio': costoEnvio,
      'direccionEnvio': direccionEnvio,
      'evidenciaEnvio': evidenciaEnvio,
      'sucursal': sucursal,
      'estado': estado,
      'notas': notas,
    };
  }

  // Método para calcular total pendiente por pagar (para pagos a plazos)
  double get totalPendiente {
    if (!esPagoAPlazo) return 0.0;

    double pagado = 0.0;
    // // Sumamos el monto inicial si existe
    // if (montoInicial != null) {
    //   pagado += montoInicial!;
    // }

    // Sumamos todos los pagos marcados como pagados
    for (var pago in pagos) {
      if (pago.pagado) {
        pagado += pago.monto;
      }
    }

    // El total pendiente es el total de la venta menos lo que ya se ha pagado
    return total - pagado;
  }

  // Método para saber si la venta está completamente pagada
  bool get estaPagada {
    if (!esPagoAPlazo) return true; // Pago único se considera pagado
    return totalPendiente <= 0;
  }

  // Método para calcular el total de productos vendidos
  int get cantidadProductos {
    int cantidad = 0;
    for (var item in items) {
      cantidad += item.cantidad;
    }
    return cantidad;
  }

  // Método para crear una copia con cambios
  VentaModel copyWith({
    String? id,
    List<ItemVenta>? items,
    DateTime? fechaVenta,
    double? subtotal,
    double? descuento,
    double? total,
    String? vendedor,
    String? nombreCliente,
    String? telefonoCliente,
    bool? esProveedor,
    bool? esPagoAPlazo,
    List<Pago>? pagos,
    double? montoInicial,
    String? comprobanteInicial,
    bool? esEnvio,
    String? numeroEnvio,
    double? costoEnvio,
    String? direccionEnvio,
    String? evidenciaEnvio,
    String? sucursal,
    String? estado,
    String? notas,
  }) {
    return VentaModel(
      id: id ?? this.id,
      items: items ?? this.items,
      fechaVenta: fechaVenta ?? this.fechaVenta,
      subtotal: subtotal ?? this.subtotal,
      descuento: descuento ?? this.descuento,
      total: total ?? this.total,
      vendedor: vendedor ?? this.vendedor,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      telefonoCliente: telefonoCliente ?? this.telefonoCliente,
      esProveedor: esProveedor ?? this.esProveedor,
      esPagoAPlazo: esPagoAPlazo ?? this.esPagoAPlazo,
      pagos: pagos ?? this.pagos,
      montoInicial: montoInicial ?? this.montoInicial,
      comprobanteInicial: comprobanteInicial ?? this.comprobanteInicial,
      esEnvio: esEnvio ?? this.esEnvio,
      numeroEnvio: numeroEnvio ?? this.numeroEnvio,
      costoEnvio: costoEnvio ?? this.costoEnvio,
      direccionEnvio: direccionEnvio ?? this.direccionEnvio,
      evidenciaEnvio: evidenciaEnvio ?? this.evidenciaEnvio,
      sucursal: sucursal ?? this.sucursal,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
    );
  }
}
