/// Modelo para reportes y estadísticas del módulo web
class ReporteEstadisticas {
  final String materiaId;
  final String materiaNombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final List<EstadisticaAlumno> estadisticasAlumnos;

  ReporteEstadisticas({
    required this.materiaId,
    required this.materiaNombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estadisticasAlumnos,
  });

  // Promedios globales del grupo (solo alumnos con datos suficientes)
  double get promedioAsistenciaGrupo {
    final alumnosConDatos = estadisticasAlumnos
        .where((a) => a.tieneDatosSuficientes)
        .toList();
    if (alumnosConDatos.isEmpty) return 0.0;
    final suma = alumnosConDatos.fold(
      0.0,
      (prev, e) => prev + e.porcentajeAsistencia,
    );
    return suma / alumnosConDatos.length;
  }

  double get promedioEvidenciasGrupo {
    final alumnosConDatos = estadisticasAlumnos
        .where((a) => a.tieneDatosSuficientes)
        .toList();
    if (alumnosConDatos.isEmpty) return 0.0;
    final suma = alumnosConDatos.fold(
      0.0,
      (prev, e) => prev + e.porcentajeEvidencias,
    );
    return suma / alumnosConDatos.length;
  }

  double get promedioPortafolioGrupo {
    final alumnosConDatos = estadisticasAlumnos
        .where((a) => a.tieneDatosSuficientes)
        .toList();
    if (alumnosConDatos.isEmpty) return 0.0;
    final suma = alumnosConDatos.fold(
      0.0,
      (prev, e) => prev + e.porcentajePortafolio,
    );
    return suma / alumnosConDatos.length;
  }

  double get promedioActividadesGrupo {
    final alumnosConDatos = estadisticasAlumnos
        .where((a) => a.tieneDatosSuficientes)
        .toList();
    if (alumnosConDatos.isEmpty) return 0.0;
    final suma = alumnosConDatos.fold(
      0.0,
      (prev, e) => prev + e.porcentajeActividades,
    );
    return suma / alumnosConDatos.length;
  }

  double get promedioExamenesGrupo {
    final alumnosConDatos = estadisticasAlumnos
        .where((a) => a.porcentajePromedioEvaluaciones != null)
        .toList();
    if (alumnosConDatos.isEmpty) return 0.0;
    final suma = alumnosConDatos.fold(
      0.0,
      (prev, e) => prev + (e.porcentajePromedioEvaluaciones ?? 0.0),
    );
    return suma / alumnosConDatos.length;
  }

  int get alumnosEnRiesgo =>
      estadisticasAlumnos.where((a) => a.tieneRiesgo).length;

  int get alumnosExentos =>
      estadisticasAlumnos.where((a) => a.puedeExentar).length;

  int get alumnosConOrdinaria =>
      estadisticasAlumnos.where((a) => a.requiereOrdinaria).length;

  double get promedioCalificacionGrupo {
    final alumnosConCalificacion = estadisticasAlumnos
        .where((a) => a.calificacionFinal != null)
        .toList();
    if (alumnosConCalificacion.isEmpty) return 0.0;
    final suma = alumnosConCalificacion.fold(
      0.0,
      (prev, e) => prev + e.calificacionFinal!,
    );
    return suma / alumnosConCalificacion.length;
  }
}

class EstadisticaAlumno {
  final String alumnoId;
  final String alumnoNombre;
  final double porcentajeAsistencia;
  final double porcentajeEvidencias;
  final double porcentajePortafolio; // % de portafolios entregados
  final double porcentajeActividades; // % de actividades entregadas
  final int
  evaluacionesReprobadas; // Cuántas de las 3 evaluaciones ha reprobado
  final bool tieneRiesgo;
  final bool puedeExentar;
  final bool requiereOrdinaria; // Si reprobó 2+ evaluaciones
  final bool
  tieneDatosSuficientes; // Si hay asistencias O evidencias registradas
  final double?
  calificacionFinal; // Promedio final con criterio: Examen 40% + Portafolio 40% + Actividad 20%

  // Promedios por tipo de actividad
  final double? promedioExamen; // Promedio de exámenes (40%)
  final double? promedioPortafolio; // Promedio de portafolios (40%)
  final double?
  promedioActividad; // Promedio de actividades complementarias (20%)
  final double?
  porcentajePromedioEvaluaciones; // Promedio general de evaluaciones en porcentaje (0-100)

  EstadisticaAlumno({
    required this.alumnoId,
    required this.alumnoNombre,
    required this.porcentajeAsistencia,
    required this.porcentajeEvidencias,
    required this.porcentajePortafolio,
    required this.porcentajeActividades,
    required this.evaluacionesReprobadas,
    required this.tieneRiesgo,
    required this.puedeExentar,
    required this.requiereOrdinaria,
    this.tieneDatosSuficientes = true,
    this.calificacionFinal,
    this.promedioExamen,
    this.promedioPortafolio,
    this.promedioActividad,
    this.porcentajePromedioEvaluaciones,
  });

  String get estadoGeneral {
    if (!tieneDatosSuficientes) return 'Sin datos';
    if (puedeExentar) return 'Exento';
    if (tieneRiesgo) return 'Riesgo';
    if (requiereOrdinaria) return 'Ordinaria';
    return 'Regular';
  }
}
