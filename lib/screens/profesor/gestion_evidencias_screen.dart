import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/evidencia.dart';
import '../../models/materia.dart';
import '../../providers/cuaderno_provider.dart';
import 'detalle_evidencia_profesor_screen.dart';

class GestionEvidenciasScreen extends StatefulWidget {
  final Materia materia;
  const GestionEvidenciasScreen({super.key, required this.materia});

  @override
  State<GestionEvidenciasScreen> createState() =>
      _GestionEvidenciasScreenState();
}

class _GestionEvidenciasScreenState extends State<GestionEvidenciasScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // Multiselección
  final Set<EstadoEvidencia> _estadosSeleccionados = {};
  final Set<TipoEvidencia> _tiposSeleccionados = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CuadernoProvider>();
    final todasEvidencias = provider.evidencias
        .where((e) => e.materiaId == widget.materia.id)
        .toList();

    // Agrupar evidencias por título (cada evidencia se crea para todos los alumnos)
    final evidenciasAgrupadas = <String, Evidencia>{};
    for (final ev in todasEvidencias) {
      if (!evidenciasAgrupadas.containsKey(ev.titulo)) {
        evidenciasAgrupadas[ev.titulo] = ev;
      }
    }

    final evidenciasUnicas = evidenciasAgrupadas.values.toList();

    bool coincideEstadosSeleccionados(Evidencia e) {
      if (_estadosSeleccionados.isEmpty) return true;
      final instancias = todasEvidencias.where((x) => x.titulo == e.titulo);
      // Debe coincidir con AL MENOS uno de los estados seleccionados
      for (final estado in _estadosSeleccionados) {
        if (instancias.any((x) => x.estado == estado)) return true;
      }
      return false;
    }

    bool coincideTiposSeleccionados(Evidencia e) {
      return _tiposSeleccionados.isEmpty ||
          _tiposSeleccionados.contains(e.tipo);
    }

    final evidenciasFiltradas = evidenciasUnicas.where((e) {
      if (!coincideEstadosSeleccionados(e)) return false;
      if (!coincideTiposSeleccionados(e)) return false;
      return true;
    }).toList();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Evidencias - ${widget.materia.nombre}'),
        actions: [
          IconButton(
            tooltip: 'Filtros',
            icon: const Icon(Icons.filter_list),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _buildFiltrosDrawer(),
      body: evidenciasFiltradas.isEmpty
          ? const Center(
              child: Text('No hay evidencias para los filtros seleccionados'),
            )
          : ListView.separated(
              itemCount: evidenciasFiltradas.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final ev = evidenciasFiltradas[i];

                // Contar estadísticas para esta evidencia
                final todasInstancias = todasEvidencias
                    .where((e) => e.titulo == ev.titulo)
                    .toList();
                final totalAlumnos = todasInstancias.length;
                final entregadas = todasInstancias
                    .where(
                      (e) =>
                          e.estado == EstadoEvidencia.entregado ||
                          e.estado == EstadoEvidencia.calificado,
                    )
                    .length;
                final calificados = todasInstancias
                    .where((e) => e.estado == EstadoEvidencia.calificado)
                    .length;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _colorPorTipo(ev.tipo).withOpacity(0.15),
                    child: Icon(
                      _iconoPorTipo(ev.tipo),
                      color: _colorPorTipo(ev.tipo),
                    ),
                  ),
                  title: Text(
                    ev.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        'Entregadas: $entregadas/$totalAlumnos  ·  Calificadas: $calificados',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'editar') _editarEvidencia(ev);
                      if (v == 'eliminar') _confirmarEliminar(ev);
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetalleEvidenciaProfesorScreen(
                          materia: widget.materia,
                          tituloEvidencia: ev.titulo,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearEvidencia,
        icon: const Icon(Icons.add),
        label: const Text('Nueva evidencia'),
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

  // Drawer lateral con filtros de Estado y Tipo
  Widget _buildFiltrosDrawer() {
    // Recalcular estadísticas rápidas para chips (agrupado por título)
    final provider = context.watch<CuadernoProvider>();
    final todas = provider.evidencias
        .where((e) => e.materiaId == widget.materia.id)
        .toList();
    final agrupadas = <String, Evidencia>{};
    for (final e in todas) {
      agrupadas.putIfAbsent(e.titulo, () => e);
    }
    final unicas = agrupadas.values.toList();

    // Cuenta títulos que tienen al menos una instancia en ese estado
    int countEstado(EstadoEvidencia estado) {
      final titulos = <String>{};
      for (final e in todas) {
        if (e.estado == estado) titulos.add(e.titulo);
      }
      return titulos.length;
    }

    int countTipo(TipoEvidencia tipo) =>
        unicas.where((e) => e.tipo == tipo).length;

    final total = unicas.length;
    final asignados = countEstado(EstadoEvidencia.asignado);
    final entregados = countEstado(EstadoEvidencia.entregado);
    final calificados = countEstado(EstadoEvidencia.calificado);
    final devueltos = countEstado(EstadoEvidencia.devuelto);

    final portafolio = countTipo(TipoEvidencia.portafolio);
    final actividad = countTipo(TipoEvidencia.actividad);
    final examen = countTipo(TipoEvidencia.examen);

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              Text(
                'Total evidencias: $total',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              const Text(
                'Estado',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text('Asignados ($asignados)'),
                    selected: _estadosSeleccionados.contains(
                      EstadoEvidencia.asignado,
                    ),
                    onSelected: (_) =>
                        setState(() => _toggleEstado(EstadoEvidencia.asignado)),
                  ),
                  FilterChip(
                    label: Text('Entregados ($entregados)'),
                    selected: _estadosSeleccionados.contains(
                      EstadoEvidencia.entregado,
                    ),
                    onSelected: (_) => setState(
                      () => _toggleEstado(EstadoEvidencia.entregado),
                    ),
                  ),
                  FilterChip(
                    label: Text('Calificados ($calificados)'),
                    selected: _estadosSeleccionados.contains(
                      EstadoEvidencia.calificado,
                    ),
                    onSelected: (_) => setState(
                      () => _toggleEstado(EstadoEvidencia.calificado),
                    ),
                  ),
                  FilterChip(
                    label: Text('Devueltos ($devueltos)'),
                    selected: _estadosSeleccionados.contains(
                      EstadoEvidencia.devuelto,
                    ),
                    onSelected: (_) =>
                        setState(() => _toggleEstado(EstadoEvidencia.devuelto)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text('Portafolio ($portafolio)'),
                    selected: _tiposSeleccionados.contains(
                      TipoEvidencia.portafolio,
                    ),
                    onSelected: (_) =>
                        setState(() => _toggleTipo(TipoEvidencia.portafolio)),
                  ),
                  FilterChip(
                    label: Text('Actividad ($actividad)'),
                    selected: _tiposSeleccionados.contains(
                      TipoEvidencia.actividad,
                    ),
                    onSelected: (_) =>
                        setState(() => _toggleTipo(TipoEvidencia.actividad)),
                  ),
                  FilterChip(
                    label: Text('Examen ($examen)'),
                    selected: _tiposSeleccionados.contains(
                      TipoEvidencia.examen,
                    ),
                    onSelected: (_) =>
                        setState(() => _toggleTipo(TipoEvidencia.examen)),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _estadosSeleccionados.clear();
                        _tiposSeleccionados.clear();
                      });
                    },
                    child: const Text('Limpiar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleEstado(EstadoEvidencia e) {
    if (_estadosSeleccionados.contains(e)) {
      _estadosSeleccionados.remove(e);
    } else {
      _estadosSeleccionados.add(e);
    }
  }

  void _toggleTipo(TipoEvidencia t) {
    if (_tiposSeleccionados.contains(t)) {
      _tiposSeleccionados.remove(t);
    } else {
      _tiposSeleccionados.add(t);
    }
  }

  void _crearEvidencia() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormularioEvidenciaScreen(materia: widget.materia),
      ),
    );
  }

  void _editarEvidencia(Evidencia ev) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FormularioEvidenciaScreen(materia: widget.materia, evidencia: ev),
      ),
    );
  }

  void _confirmarEliminar(Evidencia ev) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar evidencia'),
        content: Text(
          '¿Eliminar "${ev.titulo}"?\n\nSe eliminará para todos los alumnos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<CuadernoProvider>();

              // Encontrar todas las instancias de esta evidencia
              final todasInstancias = provider.evidencias
                  .where(
                    (e) => e.titulo == ev.titulo && e.materiaId == ev.materiaId,
                  )
                  .toList();

              // Eliminar todas las instancias
              int eliminadas = 0;
              for (final instancia in todasInstancias) {
                final ok = await provider.eliminarEvidencia(instancia.id);
                if (ok) eliminadas++;
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      eliminadas == todasInstancias.length
                          ? 'Evidencia eliminada ($eliminadas alumnos)'
                          : 'Error: solo se eliminaron $eliminadas de ${todasInstancias.length}',
                    ),
                    backgroundColor: eliminadas == todasInstancias.length
                        ? Colors.green
                        : Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class FormularioEvidenciaScreen extends StatefulWidget {
  final Materia materia;
  final Evidencia? evidencia;
  const FormularioEvidenciaScreen({
    super.key,
    required this.materia,
    this.evidencia,
  });

  @override
  State<FormularioEvidenciaScreen> createState() =>
      _FormularioEvidenciaScreenState();
}

class _FormularioEvidenciaScreenState extends State<FormularioEvidenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _calificacionCtrl;
  late TextEditingController _observacionesCtrl;
  String? _alumnoSeleccionado;
  TipoEvidencia _tipo = TipoEvidencia.actividad;
  EstadoEvidencia _estado = EstadoEvidencia.asignado;
  DateTime _fechaEntrega = DateTime.now();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.evidencia?.titulo ?? '');
    _descripcionCtrl = TextEditingController(
      text: widget.evidencia?.descripcion ?? '',
    );
    _calificacionCtrl = TextEditingController(
      text: widget.evidencia?.calificacionNumerica?.toString() ?? '',
    );
    _observacionesCtrl = TextEditingController(
      text: widget.evidencia?.observaciones ?? '',
    );
    if (widget.evidencia != null) {
      // En edición, mantenemos el alumno original
      _alumnoSeleccionado = widget.evidencia!.alumnoId;
      _tipo = widget.evidencia!.tipo;
      _estado = widget.evidencia!.estado;
      _fechaEntrega = widget.evidencia!.fechaEntrega;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _calificacionCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CuadernoProvider>();
    final totalAlumnos = widget.materia.alumnosIds.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.evidencia == null ? 'Nueva evidencia' : 'Editar evidencia',
        ),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.evidencia == null ? 'Crear' : 'Actualizar',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Título y Descripción (sección principal)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Título',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Ingresa un título'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descripcionCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Instrucciones (opcional)',
                      border: InputBorder.none,
                    ),
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Para (Asignar a)
            if (widget.evidencia == null)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Para'),
                subtitle: Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Todos los alumnos ($totalAlumnos)',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
              ),

            // Tipo
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Tipo'),
              trailing: DropdownButton<TipoEvidencia>(
                value: _tipo,
                underline: const SizedBox(),
                items: TipoEvidencia.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(_labelTipo(t)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 4,
              ),
            ),

            // Estado
            if (widget.evidencia != null)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Estado'),
                trailing: DropdownButton<EstadoEvidencia>(
                  value: _estado,
                  underline: const SizedBox(),
                  items: EstadoEvidencia.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(_labelEstado(e)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _estado = v!),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
              ),

            // Puntos (Calificación)
            ListTile(
              leading: const Icon(Icons.assessment_outlined),
              title: const Text('Puntos'),
              trailing: SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _calificacionCtrl,
                  decoration: const InputDecoration(
                    hintText: '100',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final num = double.tryParse(v);
                    if (num == null || num < 0 || num > 100) {
                      return 'Ingresa 0-100';
                    }
                    return null;
                  },
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
            ),

            // Fecha de entrega
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Fecha de entrega'),
              trailing: TextButton(
                onPressed: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaEntrega,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (fecha != null) {
                    setState(() => _fechaEntrega = fecha);
                  }
                },
                child: Text(
                  '${_fechaEntrega.day}/${_fechaEntrega.month}/${_fechaEntrega.year}',
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 4,
              ),
            ),

            const Divider(height: 1),

            // Observaciones
            Container(
              padding: const EdgeInsets.all(24),
              child: TextFormField(
                controller: _observacionesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  hintText: 'Añade comentarios adicionales...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // En modo edición, validar que haya alumno seleccionado
    if (widget.evidencia != null && _alumnoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un alumno'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    final provider = context.read<CuadernoProvider>();
    final calNum = _calificacionCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_calificacionCtrl.text.trim());

    final evidencia = Evidencia(
      id: widget.evidencia?.id ?? '',
      materiaId: widget.materia.id,
      // En modo creación, alumnoId será vacío y se asignará en el provider
      alumnoId: _alumnoSeleccionado ?? '',
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      tipo: _tipo,
      estado: _estado,
      calificacionNumerica: calNum,
      fechaEntrega: _fechaEntrega,
      fechaRegistro: widget.evidencia?.fechaRegistro ?? DateTime.now(),
      profesorId: provider.usuario!.id,
      observaciones: _observacionesCtrl.text.trim().isEmpty
          ? null
          : _observacionesCtrl.text.trim(),
    );

    bool ok;
    if (widget.evidencia == null) {
      await provider.agregarEvidencia(evidencia);
      ok = provider.lastError == null;
    } else {
      ok = await provider.actualizarEvidencia(evidencia);
    }

    if (mounted) {
      setState(() => _guardando = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidencia guardada'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.lastError ?? 'Error guardando'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
