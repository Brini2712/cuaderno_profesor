import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/materia.dart';
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
    final alumnos = provider.alumnos
        .where((a) => materia.alumnosIds.contains(a.id))
        .toList();
    if (alumnos.isEmpty) {
      return const Center(child: Text('Sin alumnos inscritos'));
    }
    return ListView.builder(
      itemCount: alumnos.length,
      itemBuilder: (ctx, i) {
        final u = alumnos[i];
        return ListTile(
          leading: CircleAvatar(
            child: Text(u.nombre.substring(0, 1).toUpperCase()),
          ),
          title: Text(u.nombre),
          subtitle: Text(u.email),
        );
      },
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
    double acumEvidencias = 0;
    int riesgo = 0;
    int exento = 0;
    for (final a in alumnos) {
      final pa = provider.calcularPorcentajeAsistencia(a.id, materia.id);
      final pe = provider.calcularPorcentajeEvidencias(a.id, materia.id);
      acumAsistencia += pa;
      acumEvidencias += pe;
      if (provider.tieneRiesgoReprobacion(a.id, materia.id)) riesgo++;
      if (provider.puedeExentar(a.id, materia.id)) exento++;
    }
    final promA = acumAsistencia / alumnos.length;
    final promE = acumEvidencias / alumnos.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _stat('Promedio asistencia', '${promA.toStringAsFixed(1)}%'),
        _stat('Promedio evidencias', '${promE.toStringAsFixed(1)}%'),
        _stat('Alumnos con riesgo', '$riesgo'),
        _stat('Alumnos exentables', '$exento'),
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
