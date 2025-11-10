import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cuaderno_provider.dart';
import '../../models/actividad.dart';
import 'detalle_evidencia_alumno_screen.dart';

class TareasPendientesScreen extends StatefulWidget {
  const TareasPendientesScreen({super.key});

  @override
  State<TareasPendientesScreen> createState() => _TareasPendientesScreenState();
}

class _TareasPendientesScreenState extends State<TareasPendientesScreen> {
  String _filtro =
      'todas'; // todas, sin_fecha, esta_semana, proxima_semana, mas_tarde

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CuadernoProvider>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Obtener todas las evidencias asignadas al alumno
    final todasLasEvidencias = provider.evidencias
        .where(
          (e) =>
              e.alumnoId == provider.usuario!.id &&
              e.estado == EstadoEvidencia.asignado,
        )
        .toList();

    // Filtrar según el filtro seleccionado
    final evidenciasFiltradas = _filtrarEvidencias(todasLasEvidencias);

    // Agrupar por categorías
    final ahora = DateTime.now();
    final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);

    // Fin de esta semana (domingo a las 23:59:59)
    final finEstaSemana = inicioDia.add(
      Duration(days: 7 - ahora.weekday, hours: 23, minutes: 59, seconds: 59),
    );

    // Fin de la próxima semana (domingo siguiente a las 23:59:59)
    final finProximaSemana = finEstaSemana.add(const Duration(days: 7));

    final vencidas = evidenciasFiltradas.where((e) {
      return e.fechaEntrega.isBefore(ahora);
    }).toList();

    final estaSemana = evidenciasFiltradas.where((e) {
      return e.fechaEntrega.isAfter(ahora) &&
          e.fechaEntrega.isBefore(finEstaSemana);
    }).toList();

    final proximaSemana = evidenciasFiltradas.where((e) {
      return e.fechaEntrega.isAfter(finEstaSemana) &&
          e.fechaEntrega.isBefore(finProximaSemana);
    }).toList();

    final masTarde = evidenciasFiltradas.where((e) {
      return e.fechaEntrega.isAfter(finProximaSemana);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Filtros siempre visibles
          Padding(
            padding: EdgeInsets.all(isMobile ? 8 : 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFiltroChip('Todas', 'todas', todasLasEvidencias.length),
                  const SizedBox(width: 8),
                  _buildFiltroChip(
                    'Esta semana',
                    'esta_semana',
                    estaSemana.length,
                  ),
                  const SizedBox(width: 8),
                  _buildFiltroChip(
                    'Próxima semana',
                    'proxima_semana',
                    proximaSemana.length,
                  ),
                  const SizedBox(width: 8),
                  _buildFiltroChip('Más tarde', 'mas_tarde', masTarde.length),
                ],
              ),
            ),
          ),
          // Contenido
          Expanded(
            child: evidenciasFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No hay tareas pendientes',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¡Buen trabajo!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => provider.cargarDatos(),
                    child: ListView(
                      padding: EdgeInsets.all(isMobile ? 8 : 16),
                      children: [
                        if (vencidas.isNotEmpty) ...[
                          _buildSeccionHeader(
                            'Vencidas',
                            vencidas.length,
                            Colors.red,
                          ),
                          ...vencidas.map(
                            (e) =>
                                _buildTareaCard(e, provider, context, isMobile),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (estaSemana.isNotEmpty &&
                            _filtro != 'proxima_semana' &&
                            _filtro != 'mas_tarde') ...[
                          _buildSeccionHeader(
                            'Esta semana',
                            estaSemana.length,
                            Colors.orange,
                          ),
                          ...estaSemana.map(
                            (e) =>
                                _buildTareaCard(e, provider, context, isMobile),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (proximaSemana.isNotEmpty &&
                            _filtro != 'esta_semana' &&
                            _filtro != 'mas_tarde') ...[
                          _buildSeccionHeader(
                            'Próxima semana',
                            proximaSemana.length,
                            Colors.blue,
                          ),
                          ...proximaSemana.map(
                            (e) =>
                                _buildTareaCard(e, provider, context, isMobile),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (masTarde.isNotEmpty &&
                            _filtro != 'esta_semana' &&
                            _filtro != 'proxima_semana') ...[
                          _buildSeccionHeader(
                            'Más tarde',
                            masTarde.length,
                            Colors.green,
                          ),
                          ...masTarde.map(
                            (e) =>
                                _buildTareaCard(e, provider, context, isMobile),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Evidencia> _filtrarEvidencias(List<Evidencia> evidencias) {
    switch (_filtro) {
      case 'esta_semana':
        final ahora = DateTime.now();
        final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
        final finEstaSemana = inicioDia.add(
          Duration(
            days: 7 - ahora.weekday,
            hours: 23,
            minutes: 59,
            seconds: 59,
          ),
        );
        return evidencias.where((e) {
          return e.fechaEntrega.isAfter(ahora) &&
              e.fechaEntrega.isBefore(finEstaSemana);
        }).toList();
      case 'proxima_semana':
        final ahora = DateTime.now();
        final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
        final finEstaSemana = inicioDia.add(
          Duration(
            days: 7 - ahora.weekday,
            hours: 23,
            minutes: 59,
            seconds: 59,
          ),
        );
        final finProximaSemana = finEstaSemana.add(const Duration(days: 7));
        return evidencias.where((e) {
          return e.fechaEntrega.isAfter(finEstaSemana) &&
              e.fechaEntrega.isBefore(finProximaSemana);
        }).toList();
      case 'mas_tarde':
        final ahora = DateTime.now();
        final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
        final finEstaSemana = inicioDia.add(
          Duration(
            days: 7 - ahora.weekday,
            hours: 23,
            minutes: 59,
            seconds: 59,
          ),
        );
        final finProximaSemana = finEstaSemana.add(const Duration(days: 7));
        return evidencias.where((e) {
          return e.fechaEntrega.isAfter(finProximaSemana);
        }).toList();
      default:
        return evidencias;
    }
  }

  Widget _buildFiltroChip(String label, String valor, int count) {
    final isSelected = _filtro == valor;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtro = selected ? valor : 'todas';
        });
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildSeccionHeader(String titulo, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTareaCard(
    Evidencia evidencia,
    CuadernoProvider provider,
    BuildContext context,
    bool isMobile,
  ) {
    final materia = provider.materias.firstWhere(
      (m) => m.id == evidencia.materiaId,
      orElse: () => provider.materias.first,
    );

    final colorMateria = Color(
      int.parse(materia.color.replaceAll('#', '0xFF')),
    );
    final fechaVencida = evidencia.fechaEntrega.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) =>
                  DetalleEvidenciaAlumnoScreen(evidencia: evidencia),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: colorMateria,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evidencia.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      materia.nombre,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: fechaVencida ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Entrega: ${DateFormat('dd/MM/yyyy').format(evidencia.fechaEntrega)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: fechaVencida ? Colors.red : Colors.grey[600],
                            fontWeight: fechaVencida
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

