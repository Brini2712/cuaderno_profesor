import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/actividad.dart';
import '../../models/materia.dart';
import '../../providers/cuaderno_provider.dart';
import 'calificar_evidencia_screen.dart';

class DetalleEvidenciaProfesorScreen extends StatefulWidget {
  final Materia materia;
  final String tituloEvidencia;

  const DetalleEvidenciaProfesorScreen({
    super.key,
    required this.materia,
    required this.tituloEvidencia,
  });

  @override
  State<DetalleEvidenciaProfesorScreen> createState() =>
      _DetalleEvidenciaProfesorScreenState();
}

class _DetalleEvidenciaProfesorScreenState
    extends State<DetalleEvidenciaProfesorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CuadernoProvider>();

    // Obtener todas las evidencias con este título en esta materia
    final evidencias = provider.evidencias
        .where(
          (e) =>
              e.materiaId == widget.materia.id &&
              e.titulo == widget.tituloEvidencia,
        )
        .toList();

    final entregadas = evidencias
        .where(
          (e) =>
              e.estado == EstadoEvidencia.entregado ||
              e.estado == EstadoEvidencia.calificado,
        )
        .length;
    final calificadas = evidencias
        .where((e) => e.estado == EstadoEvidencia.calificado)
        .length;
    final pendientes = evidencias
        .where((e) => e.estado == EstadoEvidencia.asignado)
        .length;

    // Información general de la evidencia (tomamos la primera como plantilla)
    final evidenciaModelo = evidencias.isNotEmpty ? evidencias.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tituloEvidencia),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Estadísticas
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip(
                      label: 'Entregadas',
                      value: '$entregadas/${evidencias.length}',
                      color: Colors.blue,
                    ),
                    _buildStatChip(
                      label: 'Calificadas',
                      value: '$calificadas/${evidencias.length}',
                      color: Colors.green,
                    ),
                    _buildStatChip(
                      label: 'Pendientes',
                      value: pendientes.toString(),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(text: 'Instrucciones'),
                  Tab(text: 'Entregas'),
                  Tab(text: 'Calificadas'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInstruccionesTab(evidenciaModelo),
          _buildEntregasTab(provider, evidencias, [EstadoEvidencia.entregado]),
          _buildEntregasTab(provider, evidencias, [EstadoEvidencia.calificado]),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          value.split('/').first,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      label: Text(label),
    );
  }

  Widget _buildInstruccionesTab(Evidencia? evidencia) {
    if (evidencia == null) {
      return const Center(child: Text('No hay información disponible'));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Descripción',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          evidencia.descripcion.isEmpty
              ? 'Sin descripción'
              : evidencia.descripcion,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildInfoCard(
              icon: Icons.calendar_today,
              label: 'Fecha de entrega',
              value:
                  '${evidencia.fechaEntrega.day}/${evidencia.fechaEntrega.month}/${evidencia.fechaEntrega.year}',
            ),
            const SizedBox(width: 16),
            _buildInfoCard(
              icon: Icons.assessment,
              label: 'Puntos',
              value: evidencia.puntosTotales.toStringAsFixed(0),
            ),
            const SizedBox(width: 16),
            _buildInfoCard(
              icon: Icons.category,
              label: 'Tipo',
              value: _getTipoLabel(evidencia.tipo),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntregasTab(
    CuadernoProvider provider,
    List<Evidencia> todasEvidencias,
    List<EstadoEvidencia> estadosFiltro,
  ) {
    final evidenciasFiltradas = todasEvidencias
        .where((e) => estadosFiltro.contains(e.estado))
        .toList();

    if (evidenciasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              estadosFiltro.contains(EstadoEvidencia.entregado)
                  ? 'No hay entregas pendientes de calificar'
                  : 'No hay evidencias calificadas aún',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: evidenciasFiltradas.length,
      itemBuilder: (ctx, i) {
        final evidencia = evidenciasFiltradas[i];
        final alumno = provider.alumnos.firstWhere(
          (a) => a.id == evidencia.alumnoId,
          orElse: () => provider.alumnos.first,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: evidencia.estado == EstadoEvidencia.calificado
                  ? Colors.green
                  : Colors.blue,
              child: Text(
                // Inicial basada en apellido paterno si existe, si no primer caracter del nombreCompleto
                (alumno.apellidoPaterno?.isNotEmpty == true
                        ? alumno.apellidoPaterno!
                        : alumno.nombreCompleto)
                    .substring(0, 1)
                    .toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(alumno.nombreCompleto),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (evidencia.fechaEntregaAlumno != null)
                  Text(
                    'Entregado: ${evidencia.fechaEntregaAlumno!.day}/${evidencia.fechaEntregaAlumno!.month} ${evidencia.fechaEntregaAlumno!.hour}:${evidencia.fechaEntregaAlumno!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                if (evidencia.calificacionNumerica != null)
                  Text(
                    'Calificación: ${evidencia.calificacionNumerica!.toStringAsFixed(1)}/${evidencia.puntosTotales}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )
                else if (evidencia.calificacion != null)
                  Text(
                    'Calificación: ${_letraCalif(evidencia.calificacion!)} (${evidencia.valorNumerico})/${evidencia.puntosTotales}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                if (evidencia.comentarioAlumno != null &&
                    evidencia.comentarioAlumno!.isNotEmpty)
                  Text(
                    evidencia.comentarioAlumno!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
              ],
            ),
            trailing: evidencia.estado == EstadoEvidencia.entregado
                ? const Icon(Icons.rate_review, color: Colors.blue)
                : evidencia.estaAtrasado
                ? const Icon(Icons.warning, color: Colors.red)
                : const Icon(Icons.check_circle, color: Colors.green),
            onTap: () => _abrirCalificar(evidencia),
          ),
        );
      },
    );
  }

  void _abrirCalificar(Evidencia evidencia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CalificarEvidenciaScreen(evidencia: evidencia),
      ),
    );
  }

  String _getTipoLabel(TipoEvidencia tipo) {
    switch (tipo) {
      case TipoEvidencia.portafolio:
        return 'Portafolio';
      case TipoEvidencia.actividad:
        return 'Actividad';
      case TipoEvidencia.examen:
        return 'Examen';
    }
  }

  String _letraCalif(CalificacionEvidencia c) {
    switch (c) {
      case CalificacionEvidencia.A:
        return 'A';
      case CalificacionEvidencia.B:
        return 'B';
      case CalificacionEvidencia.C:
        return 'C';
    }
  }
}
