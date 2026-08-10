class Ingreso {
  final String id;
  final String categoria;
  final String color;
  int cantidad;
  final String fecha;
  final String? registradoPor;
  final String? notas;

  Ingreso({
    required this.id,
    required this.categoria,
    required this.color,
    required this.cantidad,
    required this.fecha,
    this.registradoPor,
    this.notas,
  });

  factory Ingreso.fromMap(Map<String, dynamic> data, String id) {
    return Ingreso(
      id: id,
      categoria: data['categoria'],
      color: data['color'],
      cantidad: data['cantidad'],
      fecha: data['fecha'],
      registradoPor: data['registradoPor'],
      notas: data['notas'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoria': categoria,
      'color': color,
      'cantidad': cantidad,
      'fecha': fecha,
      'registradoPor': registradoPor,
      'notas': notas,
    };
  }

  @override
  String toString() {
    return 'Ingreso(id: $id, categoria: $categoria, color: $color, cantidad: $cantidad, fecha: $fecha, registradoPor: $registradoPor, notas: $notas)';
  }

  Ingreso copyWith({
    String? id,
    String? categoria,
    String? color,
    int? cantidad,
    String? fecha,
    String? registradoPor,
    String? notas,
  }) {
    return Ingreso(
      id: id ?? this.id,
      categoria: categoria ?? this.categoria,
      color: color ?? this.color,
      cantidad: cantidad ?? this.cantidad,
      fecha: fecha ?? this.fecha,
      registradoPor: registradoPor ?? this.registradoPor,
      notas: notas ?? this.notas,
    );
  }
}
