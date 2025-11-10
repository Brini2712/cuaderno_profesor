import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/asistencia.dart';
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
    final isMobile = MediaQuery.of(context).size.width < 600;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.materia.grupo != null && widget.materia.grupo!.isNotEmpty
              ? '${widget.materia.nombre} - Grupo ${widget.materia.grupo}'
              : widget.materia.nombre,
          style: TextStyle(fontSize: isMobile ? 16 : 20),
        ),
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
          // Estadísticas detalladas
          _buildEstadisticasDetalladas(provider, isMobile),
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
                    padding: EdgeInsets.all(isMobile ? 8 : 16),
                    itemCount: evidenciasFiltradas.length,
                    itemBuilder: (ctx, i) {
                      final ev = evidenciasFiltradas[i];
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + i * 40),
                        tween: Tween(begin: 20, end: 0),
                        curve: Curves.easeOut,
                        builder: (context, dy, child) {
                          return Opacity(
                            opacity: (1 - (dy / 20)).clamp(0, 1),
                            child: Transform.translate(
                              offset: Offset(0, dy),
                              child: child,
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: isMobile ? 4 : 8,
                            ),
                            leading: Hero(
                              tag: 'ev-${ev.id}',
                              child: CircleAvatar(
                                radius: isMobile ? 20 : 24,
                                backgroundColor: _colorPorTipo(ev.tipo),
                                child: Icon(
                                  _iconoPorTipo(ev.tipo),
                                  color: Colors.white,
                                  size: isMobile ? 18 : 24,
                                ),
                              ),
                            ),
                            title: Text(
                              ev.titulo,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ev.descripcion,
                                  maxLines: isMobile ? 2 : 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_labelTipo(ev.tipo)} • ${_labelEstado(ev.estado)}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
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
                                        : ev.estado ==
                                              EstadoEvidencia.calificado
                                        ? Icons.verified
                                        : Icons.assignment_return,
                                    color:
                                        ev.estado == EstadoEvidencia.entregado
                                        ? Colors.blue
                                        : Colors.green,
                                  ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DetalleEvidenciaAlumnoScreen(
                                    evidencia: ev,
                                  ),
                                ),
                              );
                            },
                          ),
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

  Widget _buildEstadisticasDetalladas(
    CuadernoProvider provider,
    bool isMobile,
  ) {
    // Obtener asistencias de esta materia
    final asistencias = provider.asistencias
        .where(
          (a) =>
              a.alumnoId == provider.usuario!.id &&
              a.materiaId == widget.materia.id,
        )
        .toList();

    final totalClases = asistencias.length;
    final asistenciasPresente = asistencias
        .where((a) => a.tipo == TipoAsistencia.asistencia)
        .length;
    final porcentajeAsistencia = totalClases > 0
        ? (asistenciasPresente / totalClases) * 100
        : 0;

    // Obtener evidencias de esta materia
    final evidencias = provider.evidencias
        .where(
          (e) =>
              e.alumnoId == provider.usuario!.id &&
              e.materiaId == widget.materia.id,
        )
        .toList();

    final totalEvidencias = evidencias.length;
    final evidenciasEntregadas = evidencias
        .where((e) => e.estado != EstadoEvidencia.asignado)
        .length;
    final porcentajeEvidencias = totalEvidencias > 0
        ? (evidenciasEntregadas / totalEvidencias) * 100
        : 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  size: isMobile ? 20 : 24,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Estadísticas de la asignatura',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: isMobile ? 8 : 12,
            alignment: WrapAlignment.start,
            children: [
              _buildStatCompact(
                'Total de Clases',
                totalClases.toString(),
                Icons.class_,
                Colors.blue,
                isMobile,
              ),
              _buildStatCompact(
                'Asistencia',
                asistenciasPresente.toString(),
                Icons.check_circle,
                Colors.green,
                isMobile,
              ),
              _buildStatCompact(
                '% Asistencia',
                '${porcentajeAsistencia.toStringAsFixed(1)}%',
                Icons.percent,
                porcentajeAsistencia >= 80 ? Colors.green : Colors.red,
                isMobile,
              ),
              _buildStatCompact(
                'Total de Evidencias',
                totalEvidencias.toString(),
                Icons.assignment,
                Colors.purple,
                isMobile,
              ),
              _buildStatCompact(
                'Evidencias Entregadas',
                evidenciasEntregadas.toString(),
                Icons.assignment_turned_in,
                Colors.orange,
                isMobile,
              ),
              _buildStatCompact(
                '% Evidencias Entregadas',
                '${porcentajeEvidencias.toStringAsFixed(1)}%',
                Icons.trending_up,
                porcentajeEvidencias >= 50 ? Colors.green : Colors.red,
                isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCompact(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Container(
      width: isMobile ? (MediaQuery.of(context).size.width - 64) / 3 : 140,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isMobile ? 24 : 32),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
