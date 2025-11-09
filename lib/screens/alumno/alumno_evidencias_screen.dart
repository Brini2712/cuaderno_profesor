import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/evidencia.dart';
import '../../models/materia.dart';
import '../../providers/cuaderno_provider.dart';
import 'detalle_evidencia_alumno_screen.dart';

class AlumnoEvidenciasScreen extends StatefulWidget {
  final Materia materia;
  const AlumnoEvidenciasScreen({super.key, required this.materia});

  @override
  State<AlumnoEvidenciasScreen> createState() => _AlumnoEvidenciasScreenState();
}

class _AlumnoEvidenciasScreenState extends State<AlumnoEvidenciasScreen> {
  EstadoEvidencia? _filtroEstado;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CuadernoProvider>();
    final misEvidencias = provider.evidencias
        .where(
          (e) =>
              e.materiaId == widget.materia.id &&
              e.alumnoId == provider.usuario!.id,
        )
        .toList();

    final evidenciasFiltradas = misEvidencias.where((e) {
      if (_filtroEstado != null && e.estado != _filtroEstado) return false;
      return true;
    }).toList();

    final totalEsperadas = widget.materia.totalEvidenciasEsperadas;
    final porcentaje = provider.calcularPorcentajeEvidencias(
      provider.usuario!.id,
      widget.materia.id,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Evidencias - ${widget.materia.nombre}'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) {
              setState(() {
                if (v == 'todos') {
                  _filtroEstado = null;
                } else if (v == 'asignado') {
                  _filtroEstado = EstadoEvidencia.asignado;
                } else if (v == 'entregado') {
                  _filtroEstado = EstadoEvidencia.entregado;
                } else if (v == 'calificado') {
                  _filtroEstado = EstadoEvidencia.calificado;
                } else if (v == 'devuelto') {
                  _filtroEstado = EstadoEvidencia.devuelto;
                }
              });
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'todos', child: Text('Todos')),
              PopupMenuItem(value: 'asignado', child: Text('Asignados')),
              PopupMenuItem(value: 'entregado', child: Text('Entregados')),
              PopupMenuItem(value: 'calificado', child: Text('Calificados')),
              PopupMenuItem(value: 'devuelto', child: Text('Devueltos')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progreso de evidencias',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: porcentaje / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          porcentaje >= 50 ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${misEvidencias.length} de $totalEsperadas (${porcentaje.toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: evidenciasFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          misEvidencias.isEmpty
                              ? 'Sin evidencias aún'
                              : 'Sin evidencias en este filtro',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: evidenciasFiltradas.length,
                    itemBuilder: (ctx, i) {
                      final ev = evidenciasFiltradas[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _colorPorTipo(ev.tipo),
                            child: Icon(
                              _iconoPorTipo(ev.tipo),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(ev.titulo),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ev.descripcion),
                              const SizedBox(height: 4),
                              Text(
                                '${_labelTipo(ev.tipo)} • ${_labelEstado(ev.estado)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (ev.calificacionNumerica != null)
                                Text(
                                  'Calificación: ${ev.calificacionNumerica!.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              if (ev.observaciones != null &&
                                  ev.observaciones!.isNotEmpty)
                                Text(
                                  'Obs.: ${ev.observaciones}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                            ],
                          ),
                          trailing: ev.estado == EstadoEvidencia.asignado
                              ? ElevatedButton.icon(
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Entregar'),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DetalleEvidenciaAlumnoScreen(
                                              evidencia: ev,
                                            ),
                                      ),
                                    );
                                  },
                                )
                              : Icon(
                                  ev.estado == EstadoEvidencia.entregado
                                      ? Icons.check_circle
                                      : ev.estado == EstadoEvidencia.calificado
                                      ? Icons.verified
                                      : Icons.assignment_return,
                                  color: ev.estado == EstadoEvidencia.entregado
                                      ? Colors.blue
                                      : Colors.green,
                                ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetalleEvidenciaAlumnoScreen(evidencia: ev),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _colorPorTipo(TipoEvidencia t) {
    switch (t) {
      case TipoEvidencia.portafolio:
        return Colors.blue;
      case TipoEvidencia.actividad:
        return Colors.green;
      case TipoEvidencia.examen:
        return Colors.orange;
    }
  }

  IconData _iconoPorTipo(TipoEvidencia t) {
    switch (t) {
      case TipoEvidencia.portafolio:
        return Icons.folder;
      case TipoEvidencia.actividad:
        return Icons.assignment;
      case TipoEvidencia.examen:
        return Icons.quiz;
    }
  }

  String _labelTipo(TipoEvidencia t) {
    switch (t) {
      case TipoEvidencia.portafolio:
        return 'Portafolio';
      case TipoEvidencia.actividad:
        return 'Actividad';
      case TipoEvidencia.examen:
        return 'Examen';
    }
  }

  String _labelEstado(EstadoEvidencia e) {
    switch (e) {
      case EstadoEvidencia.asignado:
        return 'Asignado';
      case EstadoEvidencia.entregado:
        return 'Entregado';
      case EstadoEvidencia.calificado:
        return 'Calificado';
      case EstadoEvidencia.devuelto:
        return 'Devuelto';
    }
  }
}
