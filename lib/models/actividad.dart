enum CalificacionEvidencia { A, B, C }

enum TipoEvidencia { portafolio, actividad, examen }

enum EstadoEvidencia {
  asignado, // Asignado pero no entregado
  entregado, // Entregado por el alumno
  calificado, // Calificado por el profesor
  devuelto, // Devuelto para corrección
}

enum EvaluacionPeriodo { eval1, eval2, eval3, ordinario }

class Evidencia {
  final String id;
  final String materiaId;
  final String alumnoId;
  final String titulo;
  final String descripcion;
  final TipoEvidencia tipo;
  final EstadoEvidencia estado;
  final CalificacionEvidencia? calificacion;
  final double? calificacionNumerica; // 0-100
  final double puntosTotales; // Puntos máximos de la evidencia
  final String? imagenUrl;
  final DateTime fechaEntrega;
  final DateTime fechaRegistro;
  final String profesorId;
  final String? observaciones;
  final EvaluacionPeriodo periodo; // New field for evaluation period

  // Campos para la entrega del alumno
  final DateTime? fechaEntregaAlumno;
  final String? comentarioAlumno;
  final List<String> archivosAdjuntos; // URLs de archivos
  final String? enlaceExterno;

  // Campos para la calificación del profesor
  final String? comentarioProfesor;
  final DateTime? fechaCalificacion;

  Evidencia({
    required this.id,
    required this.materiaId,
    required this.alumnoId,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    this.estado = EstadoEvidencia.asignado,
    this.calificacion,
    this.calificacionNumerica,
    this.puntosTotales = 100,
    this.imagenUrl,
    required this.fechaEntrega,
    required this.fechaRegistro,
    required this.profesorId,
    this.observaciones,
    this.fechaEntregaAlumno,
    this.comentarioAlumno,
    this.archivosAdjuntos = const [],
    this.enlaceExterno,
    this.comentarioProfesor,
    this.fechaCalificacion,
    this.periodo = EvaluacionPeriodo.eval1, // Default value for new field
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materiaId': materiaId,
      'alumnoId': alumnoId,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo.toString().split('.').last,
      'estado': estado.toString().split('.').last,
      'calificacion': calificacion?.toString().split('.').last,
      'calificacionNumerica': calificacionNumerica,
      'puntosTotales': puntosTotales,
      'imagenUrl': imagenUrl,
      'fechaEntrega': fechaEntrega.millisecondsSinceEpoch,
      'fechaRegistro': fechaRegistro.millisecondsSinceEpoch,
      'profesorId': profesorId,
      'observaciones': observaciones,
      'fechaEntregaAlumno': fechaEntregaAlumno?.millisecondsSinceEpoch,
      'comentarioAlumno': comentarioAlumno,
      'archivosAdjuntos': archivosAdjuntos,
      'enlaceExterno': enlaceExterno,
      'comentarioProfesor': comentarioProfesor,
      'fechaCalificacion': fechaCalificacion?.millisecondsSinceEpoch,
      'periodo': periodo
          .toString()
          .split('.')
          .last, // Include new field in toMap
    };
  }

  factory Evidencia.fromMap(Map<String, dynamic> map) {
    return Evidencia(
      id: map['id'] ?? '',
      materiaId: map['materiaId'] ?? '',
      alumnoId: map['alumnoId'] ?? '',
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      tipo: TipoEvidencia.values.firstWhere(
        (e) => e.toString().split('.').last == map['tipo'],
        orElse: () => TipoEvidencia.actividad,
      ),
      estado: EstadoEvidencia.values.firstWhere(
        (e) => e.toString().split('.').last == map['estado'],
        orElse: () => EstadoEvidencia.asignado,
      ),
      calificacion: map['calificacion'] != null
          ? CalificacionEvidencia.values.firstWhere(
              (e) => e.toString().split('.').last == map['calificacion'],
              orElse: () => CalificacionEvidencia.C,
            )
          : null,
      calificacionNumerica: map['calificacionNumerica']?.toDouble(),
      puntosTotales: map['puntosTotales']?.toDouble() ?? 100,
      imagenUrl: map['imagenUrl'],
      fechaEntrega: DateTime.fromMillisecondsSinceEpoch(
        map['fechaEntrega'] ?? 0,
      ),
      fechaRegistro: DateTime.fromMillisecondsSinceEpoch(
        map['fechaRegistro'] ?? 0,
      ),
      profesorId: map['profesorId'] ?? '',
      observaciones: map['observaciones'],
      fechaEntregaAlumno: map['fechaEntregaAlumno'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fechaEntregaAlumno'])
          : null,
      comentarioAlumno: map['comentarioAlumno'],
      archivosAdjuntos: List<String>.from(map['archivosAdjuntos'] ?? []),
      enlaceExterno: map['enlaceExterno'],
      comentarioProfesor: map['comentarioProfesor'],
      fechaCalificacion: map['fechaCalificacion'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fechaCalificacion'])
          : null,
      periodo: map['periodo'] != null
          ? EvaluacionPeriodo.values.firstWhere(
              (p) => p.toString().split('.').last == map['periodo'],
              orElse: () => EvaluacionPeriodo.eval1,
            )
          : EvaluacionPeriodo.eval1, // Default value for new field
    );
  }

  int get valorNumerico {
    if (calificacionNumerica != null) return calificacionNumerica!.round();
    if (calificacion == null) return 0;
    switch (calificacion!) {
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
    TipoEvidencia? tipo,
    EstadoEvidencia? estado,
    CalificacionEvidencia? calificacion,
    double? calificacionNumerica,
    double? puntosTotales,
    String? imagenUrl,
    DateTime? fechaEntrega,
    DateTime? fechaRegistro,
    String? profesorId,
    String? observaciones,
    DateTime? fechaEntregaAlumno,
    String? comentarioAlumno,
    List<String>? archivosAdjuntos,
    String? enlaceExterno,
    String? comentarioProfesor,
    DateTime? fechaCalificacion,
    EvaluacionPeriodo? periodo, // Include new field in copyWith
  }) {
    return Evidencia(
      id: id ?? this.id,
      materiaId: materiaId ?? this.materiaId,
      alumnoId: alumnoId ?? this.alumnoId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      calificacion: calificacion ?? this.calificacion,
      calificacionNumerica: calificacionNumerica ?? this.calificacionNumerica,
      puntosTotales: puntosTotales ?? this.puntosTotales,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      profesorId: profesorId ?? this.profesorId,
      observaciones: observaciones ?? this.observaciones,
      fechaEntregaAlumno: fechaEntregaAlumno ?? this.fechaEntregaAlumno,
      comentarioAlumno: comentarioAlumno ?? this.comentarioAlumno,
      archivosAdjuntos: archivosAdjuntos ?? this.archivosAdjuntos,
      enlaceExterno: enlaceExterno ?? this.enlaceExterno,
      comentarioProfesor: comentarioProfesor ?? this.comentarioProfesor,
      fechaCalificacion: fechaCalificacion ?? this.fechaCalificacion,
      periodo: periodo ?? this.periodo, // Handle new field in copyWith
    );
  }

  bool get estaAtrasado =>
      DateTime.now().isAfter(fechaEntrega) &&
      estado == EstadoEvidencia.asignado;
  bool get fueEntregadoATiempo =>
      fechaEntregaAlumno != null && fechaEntregaAlumno!.isBefore(fechaEntrega);
}
