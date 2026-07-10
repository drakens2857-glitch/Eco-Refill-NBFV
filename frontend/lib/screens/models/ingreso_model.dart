class Ingreso {
  final String id;
  final String categoria;
  final String color;
  int cantidad;
  final String fecha;

  Ingreso({
    required this.id,
    required this.categoria,
    required this.color,
    required this.cantidad,
    required this.fecha,
  });

  factory Ingreso.fromMap(Map<String, dynamic> data, String id) {
    return Ingreso(
      id: id,
      categoria: data['categoria'],
      color: data['color'],
      cantidad: data['cantidad'],
      fecha: data['fecha'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoria': categoria,
      'color': color,
      'cantidad': cantidad,
      'fecha': fecha,
    };
  }

  // 🔹 Opcional: útil para depuración
  @override
  String toString() {
    return 'Ingreso(id: $id, categoria: $categoria, color: $color, cantidad: $cantidad, fecha: $fecha)';
  }

  // 🔹 Opcional: clonar y modificar fácilmente
  Ingreso copyWith({
    String? id,
    String? categoria,
    String? color,
    int? cantidad,
    String? fecha,
  }) {
    return Ingreso(
      id: id ?? this.id,
      categoria: categoria ?? this.categoria,
      color: color ?? this.color,
      cantidad: cantidad ?? this.cantidad,
      fecha: fecha ?? this.fecha,
    );
  }
}
