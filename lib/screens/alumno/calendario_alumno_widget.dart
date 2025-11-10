import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/actividad.dart';
import '../../providers/cuaderno_provider.dart';
import 'detalle_evidencia_alumno_screen.dart';

class CalendarioAlumnoWidget extends StatefulWidget {
  const CalendarioAlumnoWidget({super.key});

  @override
  State<CalendarioAlumnoWidget> createState() => _CalendarioAlumnoWidgetState();
}

class _CalendarioAlumnoWidgetState extends State<CalendarioAlumnoWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final DateTime _firstDay;
  late final DateTime _lastDay;
  String? _materiaFiltro; // null = todas
  bool _soloPendientes = true;

  @override
  void initState() {
    super.initState();
    _firstDay = DateTime(DateTime.now().year - 1, 1, 1);
    _lastDay = DateTime(DateTime.now().year + 1, 12, 31);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CuadernoProvider>();
    final alumnoId = provider.usuario?.id;
    if (alumnoId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filtrar evidencias del alumno
    List<Evidencia> evidencias = provider.evidencias
        .where((e) => e.alumnoId == alumnoId)
        .toList();

    if (_materiaFiltro != null) {
      evidencias = evidencias
          .where((e) => e.materiaId == _materiaFiltro)
          .toList();
    }
    if (_soloPendientes) {
      evidencias = evidencias
          .where((e) => e.estado == EstadoEvidencia.asignado)
          .toList();
    }

    final eventosPorDia = _agruparPorDia(evidencias);
    final materias = provider.materias;

    return Column(
      children: [
        _buildBarraHerramientas(materias),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 3, child: _buildCalendar(eventosPorDia)),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: _buildListaDiaSeleccionado(eventosPorDia, provider),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarraHerramientas(List materias) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 240,
            child: DropdownButtonFormField<String?>(
              initialValue: _materiaFiltro,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Materia',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...materias.map<DropdownMenuItem<String>>(
                  (m) => DropdownMenuItem(value: m.id, child: Text(m.nombre)),
                ),
              ],
              onChanged: (v) => setState(() => _materiaFiltro = v),
            ),
          ),
          const SizedBox(width: 12),
          FilterChip(
            selected: _soloPendientes,
            label: const Text('Solo pendientes'),
            onSelected: (v) => setState(() => _soloPendientes = v),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Hoy',
            icon: const Icon(Icons.today),
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = DateTime.now();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(Map<DateTime, List<Evidencia>> eventosPorDia) {
    return TableCalendar<Evidencia>(
      firstDay: _firstDay,
      lastDay: _lastDay,
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) =>
          _selectedDay != null && isSameDay(day, _selectedDay),
      onPageChanged: (focused) => _focusedDay = focused,
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      eventLoader: (day) => eventosPorDia[DateUtils.dateOnly(day)] ?? const [],
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: CalendarStyle(
        markerDecoration: const BoxDecoration(
          color: Colors.blueGrey,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Color(0xFF1976D2),
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return const SizedBox.shrink();
          final colors = events
              .take(4)
              .map((e) => _colorPorEstado(e.estado))
              .toList();
          return Wrap(
            spacing: 1,
            children: colors
                .map(
                  (c) => Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildListaDiaSeleccionado(
    Map<DateTime, List<Evidencia>> eventosPorDia,
    CuadernoProvider provider,
  ) {
    final fecha = DateUtils.dateOnly(_selectedDay ?? DateTime.now());
    final lista = eventosPorDia[fecha] ?? const <Evidencia>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Eventos para ${DateFormat('EEEE d MMM').format(fecha)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: lista.isEmpty
              ? const Center(child: Text('Sin evidencias este día'))
              : ListView.separated(
                  itemCount: lista.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = lista[index];
                    final atrasado = e.estaAtrasado;
                    final color = _colorPorEstado(e.estado);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color,
                        child: const Icon(
                          Icons.assignment,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(e.titulo),
                      subtitle: Text(
                        'Vence: ${DateFormat('dd/MM HH:mm').format(e.fechaEntrega)}',
                      ),
                      trailing: atrasado
                          ? const Icon(Icons.warning, color: Colors.red)
                          : const Icon(Icons.chevron_right),
                      onTap: () async {
                        // Navegar al detalle
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) =>
                                DetalleEvidenciaAlumnoScreen(evidencia: e),
                          ),
                        );
                        if (!mounted) return;
                        setState(() {}); // refrescar
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Map<DateTime, List<Evidencia>> _agruparPorDia(List<Evidencia> evidencias) {
    final map = <DateTime, List<Evidencia>>{};
    for (final e in evidencias) {
      final fecha = DateUtils.dateOnly(e.fechaEntrega);
      map.putIfAbsent(fecha, () => <Evidencia>[]).add(e);
    }
    return map;
  }

  Color _colorPorEstado(EstadoEvidencia estado) {
    switch (estado) {
      case EstadoEvidencia.asignado:
        return Colors.blueGrey;
      case EstadoEvidencia.entregado:
        return Colors.green;
      case EstadoEvidencia.calificado:
        return Colors.indigo;
      case EstadoEvidencia.devuelto:
        return Colors.orange;
    }
  }
}
