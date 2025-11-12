import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/materia.dart';
import '../../models/usuario.dart';
import '../../providers/cuaderno_provider.dart';

class DetalleMateriaScreen extends StatelessWidget {
  final Materia materia;
  const DetalleMateriaScreen({super.key, required this.materia});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(materia.nombre),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Alumnos'),
              Tab(text: 'Estadísticas'),
              Tab(text: 'Código'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _InfoTab(materia: materia),
            _AlumnosTab(materia: materia),
            _EstadisticasTab(materia: materia),
            _CodigoTab(materia: materia),
          ],
        ),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final Materia materia;
  const _InfoTab({required this.materia});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tile('Nombre', materia.nombre),
        _tile('Descripción', materia.descripcion),
        _tile('Color', materia.color),
        _tile('Evidencias esperadas', '${materia.totalEvidenciasEsperadas}'),
        _tile(
          'Pesos',
          'Examen ${_pct(materia.pesoExamen)}, Portafolio ${_pct(materia.pesoPortafolio)}, Actividad ${_pct(materia.pesoActividad)}',
        ),
        _tile(
          'Fecha creación',
          '${materia.fechaCreacion.day}/${materia.fechaCreacion.month}/${materia.fechaCreacion.year}',
        ),
      ],
    );
  }

  String _pct(double v) => '${(v * 100).toStringAsFixed(0)}%';
  Widget _tile(String title, String value) => Card(
    child: ListTile(title: Text(title), subtitle: Text(value)),
  );
}

class _AlumnosTab extends StatelessWidget {
  final Materia materia;
  const _AlumnosTab({required this.materia});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CuadernoProvider>();
    final alumnos =
        provider.alumnos
            .where((a) => materia.alumnosIds.contains(a.id))
            .toList()
          ..sort((a, b) {
            int cmpApPat = (a.apellidoPaterno ?? '').compareTo(
              b.apellidoPaterno ?? '',
            );
            if (cmpApPat != 0) return cmpApPat;
            int cmpApMat = (a.apellidoMaterno ?? '').compareTo(
              b.apellidoMaterno ?? '',
            );
            if (cmpApMat != 0) return cmpApMat;
            return a.nombre.compareTo(b.nombre);
          });
    if (alumnos.isEmpty) {
      return const Center(child: Text('Sin alumnos inscritos'));
    }
    return ListView.builder(
      itemCount: alumnos.length,
      itemBuilder: (ctx, i) {
        final u = alumnos[i];
        return ListTile(
          leading: CircleAvatar(
            child: Text(
              (u.apellidoPaterno?.isNotEmpty == true
                      ? u.apellidoPaterno!
                      : u.nombreCompleto)
                  .substring(0, 1)
                  .toUpperCase(),
            ),
          ),
          title: Text(u.nombreCompleto),
          subtitle: Text(u.email),
          trailing: IconButton(
            icon: const Icon(Icons.person_remove),
            tooltip: 'Remover alumno',
            onPressed: () => _confirmarRemoverAlumno(context, provider, u),
          ),
        );
      },
    );
  }

  void _confirmarRemoverAlumno(
    BuildContext context,
    CuadernoProvider provider,
    Usuario alumno,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover alumno'),
        content: Text(
          '¿Remover a "${alumno.nombreCompleto}" de la materia? Se eliminarán sus evidencias, asistencias y calificaciones asociadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await provider.removerAlumnoDeMateria(
                materia.id,
                alumno.id,
                cascade: true,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Alumno removido'
                        : (provider.lastError ?? 'Error removiendo alumno'),
                  ),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

class _EstadisticasTab extends StatelessWidget {
  final Materia materia;
  const _EstadisticasTab({required this.materia});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CuadernoProvider>();
    final alumnos = provider.alumnos
        .where((a) => materia.alumnosIds.contains(a.id))
        .toList();
    if (alumnos.isEmpty) {
      return const Center(child: Text('Sin alumnos para estadísticas'));
    }
    double acumAsistencia = 0;
    double acumExamenes = 0;
    double acumPortafolio = 0;
    double acumActividades = 0;
    for (final a in alumnos) {
      final pa = provider.calcularPorcentajeAsistencia(a.id, materia.id);
      final pex = provider.calcularPorcentajeExamenes(a.id, materia.id);
      final pp = provider.calcularPorcentajePortafolio(a.id, materia.id);
      final pac = provider.calcularPorcentajeActividades(a.id, materia.id);
      acumAsistencia += pa;
      acumExamenes += pex;
      acumPortafolio += pp;
      acumActividades += pac;
    }
    final promA = acumAsistencia / alumnos.length;
    final promEx = acumExamenes / alumnos.length;
    final promP = acumPortafolio / alumnos.length;
    final promAc = acumActividades / alumnos.length;

    // Obtener listas de alumnos con riesgo y exento
    final alumnosConRiesgo = alumnos
        .where((a) => provider.tieneRiesgoReprobacion(a.id, materia.id))
        .toList();
    final alumnosExentos = alumnos
        .where((a) => provider.puedeExentar(a.id, materia.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _stat('% Asistencia', '${promA.toStringAsFixed(1)}%'),
        _stat('% Entrega examen', '${promEx.toStringAsFixed(1)}%'),
        _stat('% Entrega portafolio', '${promP.toStringAsFixed(1)}%'),
        _stat('% Entrega actividad', '${promAc.toStringAsFixed(1)}%'),
        const SizedBox(height: 8),

        // Alumnos con riesgo de reprobación
        if (alumnosConRiesgo.isNotEmpty)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
            child: ExpansionTile(
              backgroundColor: Colors.red.shade50,
              collapsedBackgroundColor: Colors.red.shade50,
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text(
                'Alumnos con riesgo de reprobación',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Toca para ver ${alumnosConRiesgo.length} alumno${alumnosConRiesgo.length != 1 ? 's' : ''}',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
              children: [
                Container(
                  color: Colors.white,
                  child: Column(
                    children: alumnosConRiesgo.map((alumno) {
                      final asistencia = provider.calcularPorcentajeAsistencia(
                        alumno.id,
                        materia.id,
                      );
                      final evidencias = provider.calcularPorcentajeEvidencias(
                        alumno.id,
                        materia.id,
                      );
                      final promedioEval = provider
                          .calcularPorcentajePromedioEvaluaciones(
                            alumno.id,
                            materia.id,
                          );
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade200,
                          child: Text(
                            alumno.nombreCompleto.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(alumno.nombreCompleto),
                        subtitle: Text(
                          'Asistencia: ${asistencia.toStringAsFixed(1)}% • '
                          'Evidencias: ${evidencias.toStringAsFixed(1)}%'
                          '${promedioEval != null ? ' • Exámenes: ${promedioEval.toStringAsFixed(1)}%' : ''}',
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

        // Alumnos que pueden exentar
        if (alumnosExentos.isNotEmpty)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
            child: ExpansionTile(
              backgroundColor: Colors.green.shade50,
              collapsedBackgroundColor: Colors.green.shade50,
              leading: const Icon(Icons.star, color: Colors.green),
              title: const Text(
                'Alumnos que pueden exentar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Toca para ver ${alumnosExentos.length} alumno${alumnosExentos.length != 1 ? 's' : ''}',
                style: TextStyle(color: Colors.green.shade700, fontSize: 12),
              ),
              children: [
                Container(
                  color: Colors.white,
                  child: Column(
                    children: alumnosExentos.map((alumno) {
                      final asistencia = provider.calcularPorcentajeAsistencia(
                        alumno.id,
                        materia.id,
                      );
                      final evidencias = provider.calcularPorcentajeEvidencias(
                        alumno.id,
                        materia.id,
                      );
                      final promedioEval = provider
                          .calcularPorcentajePromedioEvaluaciones(
                            alumno.id,
                            materia.id,
                          );
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade200,
                          child: Text(
                            alumno.nombreCompleto.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(alumno.nombreCompleto),
                        subtitle: Text(
                          'Asistencia: ${asistencia.toStringAsFixed(1)}% • '
                          'Evidencias: ${evidencias.toStringAsFixed(1)}%'
                          '${promedioEval != null ? ' • Exámenes: ${promedioEval.toStringAsFixed(1)}%' : ''}',
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

        if (alumnosConRiesgo.isEmpty && alumnosExentos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No hay alumnos con riesgo ni candidatos a exentar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _stat(String title, String value) => Card(
    child: ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );
}

class _CodigoTab extends StatelessWidget {
  final Materia materia;
  const _CodigoTab({required this.materia});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CuadernoProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Código actual:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(
            materia.codigoAcceso ?? 'Sin código',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: materia.codigoAcceso == null
                    ? null
                    : () => _copiar(context, materia.codigoAcceso!),
                icon: const Icon(Icons.copy),
                label: const Text('Copiar'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final nuevo = provider.regenerarCodigoMateria(materia.id);
                  if (nuevo != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Nuevo código: $nuevo')),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerar'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Al regenerar se invalida el código anterior para nuevos alumnos. Los ya inscritos no pierden acceso.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _copiar(BuildContext context, String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Código copiado')));
  }
}
