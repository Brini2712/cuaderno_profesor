class Calificacion {
  final String id;
  final String materiaId;
  final String alumnoId;
  final double? examen; // 40%
  final double? portafolioEvidencias; // 40%
  final double? actividadComplementaria; // 20%
  final DateTime fechaActualizacion;

  Calificacion({
    required this.id,
    required this.materiaId,
    required this.alumnoId,
    this.examen,
    this.portafolioEvidencias,
    this.actividadComplementaria,
    required this.fechaActualizacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materiaId': materiaId,
      'alumnoId': alumnoId,
      'examen': examen,
      'portafolioEvidencias': portafolioEvidencias,
      'actividadComplementaria': actividadComplementaria,
      'fechaActualizacion': fechaActualizacion.millisecondsSinceEpoch,
    };
  }

  factory Calificacion.fromMap(Map<String, dynamic> map) {
    return Calificacion(
      id: map['id'] ?? '',
      materiaId: map['materiaId'] ?? '',
      alumnoId: map['alumnoId'] ?? '',
      examen: map['examen']?.toDouble(),
      portafolioEvidencias: map['portafolioEvidencias']?.toDouble(),
      actividadComplementaria: map['actividadComplementaria']?.toDouble(),
      fechaActualizacion: DateTime.fromMillisecondsSinceEpoch(map['fechaActualizacion'] ?? 0),
    );
  }

  double? get calificacionFinal {
    if (examen == null || portafolioEvidencias == null || actividadComplementaria == null) {
      return null;
    }
    return (examen! * 0.4) + (portafolioEvidencias! * 0.4) + (actividadComplementaria! * 0.2);
  }

  bool get estaCompleta {
    return examen != null && portafolioEvidencias != null && actividadComplementaria != null;
  }

  Calificacion copyWith({
    String? id,
    String? materiaId,
    String? alumnoId,
    double? examen,
    double? portafolioEvidencias,
    double? actividadComplementaria,
    DateTime? fechaActualizacion,
  }) {
    return Calificacion(
      id: id ?? this.id,
      materiaId: materiaId ?? this.materiaId,
      alumnoId: alumnoId ?? this.alumnoId,
      examen: examen ?? this.examen,
      portafolioEvidencias: portafolioEvidencias ?? this.portafolioEvidencias,
      actividadComplementaria: actividadComplementaria ?? this.actividadComplementaria,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}