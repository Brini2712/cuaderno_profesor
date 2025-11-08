class Materia {
  final String id;
  final String nombre;
  final String descripcion;
  final String color;
  final String profesorId;
  final List<String> alumnosIds;
  final DateTime fechaCreacion;
  final String? codigoAcceso;
  // Número esperado de evidencias por parcial/periodo para esta materia
  final int totalEvidenciasEsperadas;
  // Pesos de evaluación (por defecto: Examen 40%, Portafolio 40%, Actividad 20%)
  final double pesoExamen;
  final double pesoPortafolio;
  final double pesoActividad;

  Materia({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.color,
    required this.profesorId,
    this.alumnosIds = const [],
    required this.fechaCreacion,
    this.codigoAcceso,
    this.totalEvidenciasEsperadas = 10,
    this.pesoExamen = 0.4,
    this.pesoPortafolio = 0.4,
    this.pesoActividad = 0.2,
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
      'totalEvidenciasEsperadas': totalEvidenciasEsperadas,
      'pesoExamen': pesoExamen,
      'pesoPortafolio': pesoPortafolio,
      'pesoActividad': pesoActividad,
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
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(
        map['fechaCreacion'] ?? 0,
      ),
      codigoAcceso: map['codigoAcceso'],
      totalEvidenciasEsperadas: (map['totalEvidenciasEsperadas'] ?? 10) is int
          ? (map['totalEvidenciasEsperadas'] ?? 10)
          : (map['totalEvidenciasEsperadas'] ?? 10).toInt(),
      pesoExamen: (map['pesoExamen'] ?? 0.4).toDouble(),
      pesoPortafolio: (map['pesoPortafolio'] ?? 0.4).toDouble(),
      pesoActividad: (map['pesoActividad'] ?? 0.2).toDouble(),
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
    int? totalEvidenciasEsperadas,
    double? pesoExamen,
    double? pesoPortafolio,
    double? pesoActividad,
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
      totalEvidenciasEsperadas:
          totalEvidenciasEsperadas ?? this.totalEvidenciasEsperadas,
      pesoExamen: pesoExamen ?? this.pesoExamen,
      pesoPortafolio: pesoPortafolio ?? this.pesoPortafolio,
      pesoActividad: pesoActividad ?? this.pesoActividad,
    );
  }
}
