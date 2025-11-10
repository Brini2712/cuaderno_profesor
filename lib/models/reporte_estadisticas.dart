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

  // Promedios globales del grupo
  double get promedioAsistenciaGrupo {
    if (estadisticasAlumnos.isEmpty) return 0.0;
    final suma = estadisticasAlumnos.fold(
      0.0,
      (prev, e) => prev + e.porcentajeAsistencia,
    );
    return suma / estadisticasAlumnos.length;
  }

  double get promedioEvidenciasGrupo {
    if (estadisticasAlumnos.isEmpty) return 0.0;
    final suma = estadisticasAlumnos.fold(
      0.0,
      (prev, e) => prev + e.porcentajeEvidencias,
    );
    return suma / estadisticasAlumnos.length;
  }

  int get alumnosEnRiesgo =>
      estadisticasAlumnos.where((a) => a.tieneRiesgo).length;

  int get alumnosExentos =>
      estadisticasAlumnos.where((a) => a.puedeExentar).length;

  int get alumnosConOrdinaria =>
      estadisticasAlumnos.where((a) => a.requiereOrdinaria).length;
}

class EstadisticaAlumno {
  final String alumnoId;
  final String alumnoNombre;
  final double porcentajeAsistencia;
  final double porcentajeEvidencias;
  final int
  evaluacionesReprobadas; // Cuántas de las 3 evaluaciones ha reprobado
  final bool tieneRiesgo;
  final bool puedeExentar;
  final bool requiereOrdinaria; // Si reprobó 2+ evaluaciones
  final bool
  tieneDatosSuficientes; // Si hay asistencias O evidencias registradas

  EstadisticaAlumno({
    required this.alumnoId,
    required this.alumnoNombre,
    required this.porcentajeAsistencia,
    required this.porcentajeEvidencias,
    required this.evaluacionesReprobadas,
    required this.tieneRiesgo,
    required this.puedeExentar,
    required this.requiereOrdinaria,
    this.tieneDatosSuficientes = true,
  });

  String get estadoGeneral {
    if (!tieneDatosSuficientes) return 'Sin datos';
    if (puedeExentar) return 'Exento';
    if (tieneRiesgo) return 'Riesgo';
    if (requiereOrdinaria) return 'Ordinaria';
    return 'Regular';
  }
}
