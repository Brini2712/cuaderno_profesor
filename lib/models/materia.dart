class Materia {
  final String id;
  final String nombre;
  final String descripcion;
  final String color;
  final String profesorId;
  final List<String> alumnosIds;
  final DateTime fechaCreacion;
  final String? codigoAcceso;

  Materia({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.color,
    required this.profesorId,
    this.alumnosIds = const [],
    required this.fechaCreacion,
    this.codigoAcceso,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'color': color,
      'profesorId': profesorId,
      'alumnosIds': alumnosIds,
      'fechaCreacion': fechaCreacion.millisecondsSinceEpoch,
      'codigoAcceso': codigoAcceso,
    };
  }

  factory Materia.fromMap(Map<String, dynamic> map) {
    return Materia(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      color: map['color'] ?? '#2196F3',
      profesorId: map['profesorId'] ?? '',
      alumnosIds: List<String>.from(map['alumnosIds'] ?? []),
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(map['fechaCreacion'] ?? 0),
      codigoAcceso: map['codigoAcceso'],
    );
  }

  Materia copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? color,
    String? profesorId,
    List<String>? alumnosIds,
    DateTime? fechaCreacion,
    String? codigoAcceso,
  }) {
    return Materia(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      color: color ?? this.color,
      profesorId: profesorId ?? this.profesorId,
      alumnosIds: alumnosIds ?? this.alumnosIds,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      codigoAcceso: codigoAcceso ?? this.codigoAcceso,
    );
  }
}