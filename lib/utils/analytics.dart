import '../models/asistencia.dart';

class AnalyticsUtils {
  // 3 retardos = 1 falta equivalente
  static double porcentajeAsistencia(List<RegistroAsistencia> registros) {
    if (registros.isEmpty) return 0.0;

    final asistencias = registros
        .where(
          (a) =>
              a.tipo == TipoAsistencia.asistencia ||
              a.tipo == TipoAsistencia.justificacion,
        )
        .length;
    final retardos = registros
        .where((a) => a.tipo == TipoAsistencia.retardo)
        .length;
    final faltasEquivalentes = (retardos / 3).floor();
    final asistenciasEfectivas = asistencias - faltasEquivalentes;
    final total = registros.length;
    return (asistenciasEfectivas / total) * 100;
  }

  static double porcentajeEvidencias({
    required int entregadas,
    required int esperadas,
  }) {
    if (esperadas <= 0) return entregadas > 0 ? 100.0 : 0.0;
    return (entregadas / esperadas) * 100;
  }

  static bool riesgoReprobacion({
    required double porcentajeAsistencia,
    required double porcentajeEvidencias,
  }) {
    return porcentajeAsistencia < 80 || porcentajeEvidencias < 50;
  }

  static bool puedeExentar({
    required double porcentajeAsistencia,
    required double porcentajeEvidencias,
  }) {
    return porcentajeAsistencia >= 95 && porcentajeEvidencias >= 90;
  }
}
