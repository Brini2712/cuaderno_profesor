enum TipoAsistencia { asistencia, justificacion, falta, retardo }

class RegistroAsistencia {
  final String id;
  final String materiaId;
  final String alumnoId;
  final DateTime fecha;
  final TipoAsistencia tipo;
  final String? observaciones;

  RegistroAsistencia({
    required this.id,
    required this.materiaId,
    required this.alumnoId,
    required this.fecha,
    required this.tipo,
    this.observaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materiaId': materiaId,
      'alumnoId': alumnoId,
      'fecha': fecha.millisecondsSinceEpoch,
      'tipo': tipo.toString().split('.').last,
      'observaciones': observaciones,
    };
  }

  factory RegistroAsistencia.fromMap(Map<String, dynamic> map) {
    return RegistroAsistencia(
      id: map['id'] ?? '',
      materiaId: map['materiaId'] ?? '',
      alumnoId: map['alumnoId'] ?? '',
      fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha'] ?? 0),
      tipo: TipoAsistencia.values.firstWhere(
        (e) => e.toString().split('.').last == map['tipo'],
        orElse: () => TipoAsistencia.falta,
      ),
      observaciones: map['observaciones'],
    );
  }

  String get tipoCorto {
    switch (tipo) {
      case TipoAsistencia.asistencia:
        return 'A';
      case TipoAsistencia.justificacion:
        return 'J';
      case TipoAsistencia.falta:
        return 'F';
      case TipoAsistencia.retardo:
        return 'R';
    }
  }

  RegistroAsistencia copyWith({
    String? id,
    String? materiaId,
    String? alumnoId,
    DateTime? fecha,
    TipoAsistencia? tipo,
    String? observaciones,
  }) {
    return RegistroAsistencia(
      id: id ?? this.id,
      materiaId: materiaId ?? this.materiaId,
      alumnoId: alumnoId ?? this.alumnoId,
      fecha: fecha ?? this.fecha,
      tipo: tipo ?? this.tipo,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}
