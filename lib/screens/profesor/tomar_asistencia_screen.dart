import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cuaderno_provider.dart';
import '../../models/asistencia.dart';
import '../../models/materia.dart';

class TomarAsistenciaScreen extends StatefulWidget {
  final Materia materia;
  const TomarAsistenciaScreen({super.key, required this.materia});

  @override
  State<TomarAsistenciaScreen> createState() => _TomarAsistenciaScreenState();
}

class _TomarAsistenciaScreenState extends State<TomarAsistenciaScreen> {
  DateTime _fecha = DateTime.now();
  final Map<String, TipoAsistencia> _seleccion = {};
  final Map<String, String> _observaciones = {};
  bool _guardando = false;
  bool _cargandoPrefill = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CuadernoProvider>();
      _prefill(provider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CuadernoProvider>();
    final alumnos =
        provider.alumnos
            .where((a) => widget.materia.alumnosIds.contains(a.id))
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Asistencia - ${widget.materia.nombre}'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            onSelected: (v) {
              if (v == 'todos_a') _marcarTodos(TipoAsistencia.asistencia);
              if (v == 'limpiar') _limpiarSeleccion();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'todos_a', child: Text('Marcar todos A')),
              PopupMenuItem(value: 'limpiar', child: Text('Limpiar selección')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
          IconButton(
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: (alumnos.isEmpty || _guardando)
                ? null
                : () => _guardar(provider, alumnos),
          ),
        ],
      ),
      body: alumnos.isEmpty
          ? const Center(child: Text('Sin alumnos inscritos'))
          : (_cargandoPrefill
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: alumnos.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildResumen(alumnos.length);
                      final alumno = alumnos[index - 1];
                      final seleccion = _seleccion[alumno.id];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alumno.nombreCompleto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _buildChip(
                                    alumno.id,
                                    TipoAsistencia.asistencia,
                                    'A',
                                  ),
                                  _buildChip(
                                    alumno.id,
                                    TipoAsistencia.justificacion,
                                    'J',
                                  ),
                                  _buildChip(
                                    alumno.id,
                                    TipoAsistencia.falta,
                                    'F',
                                  ),
                                  _buildChip(
                                    alumno.id,
                                    TipoAsistencia.retardo,
                                    'R',
                                  ),
                                  IconButton(
                                    tooltip: 'Agregar observación',
                                    icon: Icon(
                                      Icons.note_alt_outlined,
                                      color:
                                          (_observaciones[alumno.id] ?? '')
                                              .isNotEmpty
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : null,
                                    ),
                                    onPressed: () =>
                                        _editarObservacion(alumno.id),
                                  ),
                                ],
                              ),
                              if (seleccion != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Seleccionado: ${_toLabel(seleccion)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if ((_observaciones[alumno.id] ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Obs.: ${_observaciones[alumno.id]}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  )),
    );
  }

  Widget _buildResumen(int totalAlumnos) {
    final valores = _seleccion.values;
    int cuenta(TipoAsistencia t) => valores.where((v) => v == t).length;
    final a = cuenta(TipoAsistencia.asistencia);
    final j = cuenta(TipoAsistencia.justificacion);
    final f = cuenta(TipoAsistencia.falta);
    final r = cuenta(TipoAsistencia.retardo);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('A: $a'),
              _pill('J: $j'),
              _pill('F: $f'),
              _pill('R: $r'),
              _pill('Completos: ${_seleccion.length}/$totalAlumnos'),
            ],
          ),
          const SizedBox(height: 4),
          if (_seleccion.length < totalAlumnos)
            Text(
              'Faltan ${totalAlumnos - _seleccion.length} alumnos por marcar',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12)),
  );

  Widget _buildChip(String alumnoId, TipoAsistencia tipo, String label) {
    final seleccionado = _seleccion[alumnoId] == tipo;
    return ChoiceChip(
      label: Text(label),
      selected: seleccionado,
      onSelected: (_) {
        setState(() {
          _seleccion[alumnoId] = tipo;
        });
      },
    );
  }

  String _toLabel(TipoAsistencia t) {
    switch (t) {
      case TipoAsistencia.asistencia:
        return 'Asistencia';
      case TipoAsistencia.justificacion:
        return 'Justificación';
      case TipoAsistencia.falta:
        return 'Falta';
      case TipoAsistencia.retardo:
        return 'Retardo';
    }
  }

  Future<void> _pickDate() async {
    final ahora = DateTime.now();
    final seleccionado = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(ahora.year - 1),
      lastDate: DateTime(ahora.year + 1),
    );
    if (seleccionado != null) {
      setState(() => _fecha = seleccionado);
      final provider = context.read<CuadernoProvider>();
      _prefill(provider);
    }
  }

  Future<void> _guardar(CuadernoProvider provider, List alumnos) async {
    if (_seleccion.length < alumnos.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faltan alumnos por marcar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _guardando = true);
    final registros = _seleccion.entries
        .map(
          (e) => RegistroAsistencia(
            id: '',
            materiaId: widget.materia.id,
            alumnoId: e.key,
            fecha: _fecha,
            tipo: e.value,
            observaciones: _observaciones[e.key],
          ),
        )
        .toList();
    await provider.guardarAsistenciasDia(
      materiaId: widget.materia.id,
      fecha: _fecha,
      registros: registros,
    );
    if (mounted) {
      setState(() => _guardando = false);
      final mensaje = provider.lastError ?? 'Asistencias guardadas';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: provider.lastError == null
              ? Colors.green
              : Colors.red,
        ),
      );
    }
  }

  void _prefill(CuadernoProvider provider) {
    setState(() => _cargandoPrefill = true);
    _seleccion.clear();
    _observaciones.clear();
    final d = _fecha;
    for (final a in provider.asistencias.where(
      (x) =>
          x.materiaId == widget.materia.id &&
          x.fecha.year == d.year &&
          x.fecha.month == d.month &&
          x.fecha.day == d.day,
    )) {
      _seleccion[a.alumnoId] = a.tipo;
      if (a.observaciones != null && a.observaciones!.isNotEmpty) {
        _observaciones[a.alumnoId] = a.observaciones!;
      }
    }
    setState(() => _cargandoPrefill = false);
  }

  void _marcarTodos(TipoAsistencia tipo) {
    final provider = context.read<CuadernoProvider>();
    final alumnos = provider.alumnos
        .where((a) => widget.materia.alumnosIds.contains(a.id))
        .toList();
    setState(() {
      for (final a in alumnos) {
        _seleccion[a.id] = tipo;
      }
    });
  }

  void _limpiarSeleccion() {
    setState(() {
      _seleccion.clear();
      _observaciones.clear();
    });
  }

  Future<void> _editarObservacion(String alumnoId) async {
    final controller = TextEditingController(
      text: _observaciones[alumnoId] ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Observación'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escribe una observación (opcional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        if (result.isEmpty) {
          _observaciones.remove(alumnoId);
        } else {
          _observaciones[alumnoId] = result;
        }
      });
    }
  }
}
