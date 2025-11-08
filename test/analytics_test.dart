import 'package:flutter_test/flutter_test.dart';
import 'package:cuaderno_profesor/utils/analytics.dart';
import 'package:cuaderno_profesor/models/asistencia.dart';

RegistroAsistencia r(String tipo) => RegistroAsistencia(
  id: '1',
  materiaId: 'm1',
  alumnoId: 'a1',
  fecha: DateTime.now(),
  tipo: TipoAsistencia.values.firstWhere(
    (e) => e.toString().split('.').last == tipo,
  ),
);

void main() {
  group('AnalyticsUtils', () {
    test('porcentaje asistencia con retardos', () {
      final registros = [
        r('asistencia'),
        r('asistencia'),
        r('retardo'),
        r('retardo'),
        r('retardo'), // 3 retardos = 1 falta equivalente
      ];
      final pct = AnalyticsUtils.porcentajeAsistencia(registros);
      // asistencias efectivas: 2 - 1 falta equivalente = 1 sobre 5 -> 20%
      expect(pct, closeTo(20.0, 0.001));
    });

    test('porcentaje evidencias', () {
      final pct = AnalyticsUtils.porcentajeEvidencias(
        entregadas: 5,
        esperadas: 10,
      );
      expect(pct, 50.0);
    });

    test('riesgo reprobación true', () {
      final riesgo = AnalyticsUtils.riesgoReprobacion(
        porcentajeAsistencia: 70,
        porcentajeEvidencias: 40,
      );
      expect(riesgo, isTrue);
    });

    test('exentar true', () {
      final exenta = AnalyticsUtils.puedeExentar(
        porcentajeAsistencia: 96,
        porcentajeEvidencias: 92,
      );
      expect(exenta, isTrue);
    });
  });
}
