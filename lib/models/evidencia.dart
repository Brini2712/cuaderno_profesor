enum CalificacionEvidencia { A, B, C }

class Evidencia {
  final String id;
  final String materiaId;
  final String alumnoId;
  final String titulo;
  final String descripcion;
  final CalificacionEvidencia calificacion;
  final String? imagenUrl;
  final DateTime fechaEntrega;
  final DateTime fechaRegistro;
  final String profesorId;

  Evidencia({
    required this.id,
    required this.materiaId,
    required this.alumnoId,
    required this.titulo,
    required this.descripcion,
    required this.calificacion,
    this.imagenUrl,
    required this.fechaEntrega,
    required this.fechaRegistro,
    required this.profesorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materiaId': materiaId,
      'alumnoId': alumnoId,
      'titulo': titulo,
      'descripcion': descripcion,
      'calificacion': calificacion.toString().split('.').last,
      'imagenUrl': imagenUrl,
      'fechaEntrega': fechaEntrega.millisecondsSinceEpoch,
      'fechaRegistro': fechaRegistro.millisecondsSinceEpoch,
      'profesorId': profesorId,
    };
  }

  factory Evidencia.fromMap(Map<String, dynamic> map) {
    return Evidencia(
      id: map['id'] ?? '',
      materiaId: map['materiaId'] ?? '',
      alumnoId: map['alumnoId'] ?? '',
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      calificacion: CalificacionEvidencia.values.firstWhere(
        (e) => e.toString().split('.').last == map['calificacion'],
        orElse: () => CalificacionEvidencia.C,
      ),
      imagenUrl: map['imagenUrl'],
      fechaEntrega: DateTime.fromMillisecondsSinceEpoch(map['fechaEntrega'] ?? 0),
      fechaRegistro: DateTime.fromMillisecondsSinceEpoch(map['fechaRegistro'] ?? 0),
      profesorId: map['profesorId'] ?? '',
    );
  }

  int get valorNumerico {
    switch (calificacion) {
      case CalificacionEvidencia.A:
        return 10;
      case CalificacionEvidencia.B:
        return 8;
      case CalificacionEvidencia.C:
        return 6;
    }
  }

  Evidencia copyWith({
    String? id,
    String? materiaId,
    String? alumnoId,
    String? titulo,
    String? descripcion,
    CalificacionEvidencia? calificacion,
    String? imagenUrl,
    DateTime? fechaEntrega,
    DateTime? fechaRegistro,
    String? profesorId,
  }) {
    return Evidencia(
      id: id ?? this.id,
      materiaId: materiaId ?? this.materiaId,
      alumnoId: alumnoId ?? this.alumnoId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      calificacion: calificacion ?? this.calificacion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      profesorId: profesorId ?? this.profesorId,
    );
  }
}
