import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/evidencia.dart';
import '../../providers/cuaderno_provider.dart';

class DetalleEvidenciaAlumnoScreen extends StatefulWidget {
  final Evidencia evidencia;

  const DetalleEvidenciaAlumnoScreen({super.key, required this.evidencia});

  @override
  State<DetalleEvidenciaAlumnoScreen> createState() =>
      _DetalleEvidenciaAlumnoScreenState();
}

class _DetalleEvidenciaAlumnoScreenState
    extends State<DetalleEvidenciaAlumnoScreen> {
  late TextEditingController _comentarioCtrl;
  late TextEditingController _enlaceCtrl;
  bool _guardando = false;
  final List<String> _archivosAdjuntos = [];
  bool _subiendo = false;
  String _restante = '';
  Timer? _countdownTimer;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _comentarioCtrl = TextEditingController(
      text: widget.evidencia.comentarioAlumno ?? '',
    );
    _enlaceCtrl = TextEditingController(
      text: widget.evidencia.enlaceExterno ?? '',
    );
    _archivosAdjuntos.addAll(widget.evidencia.archivosAdjuntos);
    _iniciarCountdown();
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    _enlaceCtrl.dispose();
    _countdownTimer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estaEntregado =
        widget.evidencia.estado != EstadoEvidencia.asignado &&
        widget.evidencia.estado != EstadoEvidencia.devuelto;
    final fueDevuelto = widget.evidencia.estado == EstadoEvidencia.devuelto;
    final width = MediaQuery.of(context).size.width;
    final usarLayoutDesktop = width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.evidencia.titulo),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: usarLayoutDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna principal (instrucciones)
                Expanded(flex: 2, child: _buildInstrucciones()),
                // Panel lateral derecho (tu trabajo)
                Container(
                  width: 360,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(left: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: _buildPanelTrabajo(estaEntregado, fueDevuelto),
                ),
              ],
            )
          : ListView(
              children: [
                _buildInstrucciones(),
                const Divider(height: 1),
                _buildPanelTrabajo(estaEntregado, fueDevuelto),
              ],
            ),
    );
  }

  Widget _buildInstrucciones() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        // Encabezado con avatar + título (hero)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: 'ev-${widget.evidencia.id}',
              child: CircleAvatar(
                radius: 22,
                backgroundColor: _colorPorTipo(widget.evidencia.tipo),
                child: Icon(
                  _iconoPorTipo(widget.evidencia.tipo),
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.evidencia.titulo,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Línea puntos + fecha (fecha alineada a la derecha estilo Classroom)
        Row(
          children: [
            Text(
              '${widget.evidencia.puntosTotales.toInt()} puntos',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const Spacer(),
            Text(
              'Fecha de entrega: ${_formatearFecha(widget.evidencia.fechaEntrega)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Descripción/instrucciones
        Text(
          widget.evidencia.descripcion.isEmpty
              ? 'Sin instrucciones adicionales'
              : widget.evidencia.descripcion,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 40),
        // Comentarios de la clase (placeholder)
        const Divider(height: 1),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              'Comentarios de la clase',
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comentarios de la clase próximamente'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.add_comment_outlined, size: 18),
          label: const Text('Añadir comentario'),
          style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
        ),
      ],
    );
  }

  // Helpers para icono/color (coherentes con la lista)
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

  Widget _buildPanelTrabajo(bool estaEntregado, bool fueDevuelto) {
    final estado = widget.evidencia.estado;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        // CARD: Tu trabajo
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tu trabajo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _estadoChip(estado),
                    ),
                  ],
                ),
                if (_restante.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _restante,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.evidencia.estaAtrasado
                          ? Colors.red[700]
                          : Colors.grey[700],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (estado == EstadoEvidencia.calificado &&
                    widget.evidencia.calificacionNumerica != null) ...[
                  if (widget.evidencia.fechaCalificacion != null) ...[
                    Text(
                      'Calificado el ${_formatearFecha(widget.evidencia.fechaCalificacion!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    '${widget.evidencia.calificacionNumerica!.toStringAsFixed(1)} / ${widget.evidencia.puntosTotales.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  if (widget.evidencia.comentarioProfesor != null &&
                      widget.evidencia.comentarioProfesor!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comentario del profesor:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.evidencia.comentarioProfesor!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
                if (fueDevuelto)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.assignment_return,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trabajo devuelto',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                ),
                              ),
                              if (widget.evidencia.comentarioProfesor != null &&
                                  widget
                                      .evidencia
                                      .comentarioProfesor!
                                      .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  widget.evidencia.comentarioProfesor!,
                                  style: TextStyle(color: Colors.orange[900]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (fueDevuelto) const SizedBox(height: 16),
                if (!estaEntregado || fueDevuelto)
                  PopupMenuButton<String>(
                    enabled: !_subiendo,
                    onSelected: (value) {
                      switch (value) {
                        case 'archivo':
                          _agregarArchivo();
                          break;
                        case 'enlace':
                          _mostrarDialogoEnlace();
                          break;
                        case 'google_drive':
                          _mostrarMensajeProximamente('Google Drive');
                          break;
                        case 'docs':
                          _mostrarMensajeProximamente('Documentos');
                          break;
                        case 'sheets':
                          _mostrarMensajeProximamente('Hojas de cálculo');
                          break;
                        case 'slides':
                          _mostrarMensajeProximamente('Presentaciones');
                          break;
                        case 'drawings':
                          _mostrarMensajeProximamente('Dibujos');
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'google_drive',
                        child: Row(
                          children: [
                            Icon(Icons.cloud, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            const Text('Google Drive'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'enlace',
                        child: Row(
                          children: [
                            Icon(Icons.link, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            const Text('Enlace'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archivo',
                        child: Row(
                          children: [
                            Icon(Icons.attach_file, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            const Text('Archivo'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        enabled: false,
                        height: 32,
                        child: Text(
                          'Crear',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'docs',
                        child: Row(
                          children: [
                            Icon(Icons.description, color: Colors.blue[600]),
                            const SizedBox(width: 12),
                            const Text('Documentos'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'sheets',
                        child: Row(
                          children: [
                            Icon(Icons.table_chart, color: Colors.green[600]),
                            const SizedBox(width: 12),
                            const Text('Hojas de cálculo'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'slides',
                        child: Row(
                          children: [
                            Icon(Icons.slideshow, color: Colors.orange[600]),
                            const SizedBox(width: 12),
                            const Text('Presentaciones'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'drawings',
                        child: Row(
                          children: [
                            Icon(Icons.palette, color: Colors.red[600]),
                            const SizedBox(width: 12),
                            const Text('Dibujos'),
                          ],
                        ),
                      ),
                    ],
                    child: OutlinedButton.icon(
                      onPressed: _subiendo ? null : null,
                      icon: _subiendo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(_subiendo ? 'Subiendo...' : 'Añadir o crear'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                    ),
                  ),
                if (_archivosAdjuntos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ..._archivosAdjuntos.map(
                    (archivo) => Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.insert_drive_file,
                          color: Colors.blue[700],
                        ),
                        title: Text(archivo.split('/').last),
                        onTap: () => _abrirUrl(archivo),
                        trailing: (!estaEntregado || fueDevuelto)
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _archivosAdjuntos.remove(archivo);
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
                // Campo de enlace: SOLO mostrar si ya hay un enlace agregado (vía menú)
                // Antes aparecía siempre mientras no estuviera entregado, se elimina para que
                // la opción viva únicamente dentro del popup y aquí solo sea edición/preview.
                if (_enlaceCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _enlaceCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enlace',
                      prefixIcon: const Icon(Icons.link),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Quitar enlace',
                        onPressed:
                            (!_subiendo && (!estaEntregado || fueDevuelto))
                            ? () {
                                setState(() {
                                  _enlaceCtrl.clear();
                                });
                                _autoSave();
                              }
                            : null,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    enabled: !estaEntregado || fueDevuelto,
                    onChanged: (_) => _autoSave(),
                  ),
                  if (_enlaceCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildEnlacePreview(_enlaceCtrl.text),
                  ],
                ],
                const SizedBox(height: 20),
                if (!estaEntregado || fueDevuelto)
                  FilledButton(
                    onPressed: _guardando ? null : _entregar,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue[700],
                    ),
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            fueDevuelto ? 'Reenviar' : 'Marcar como completado',
                            style: const TextStyle(fontSize: 16),
                          ),
                  )
                else if (estado == EstadoEvidencia.calificado ||
                    estado == EstadoEvidencia.entregado)
                  OutlinedButton(
                    onPressed: _guardando ? null : _anularEntrega,
                    child: const Text('Volver a entregar'),
                  ),
                if (estaEntregado &&
                    !fueDevuelto &&
                    widget.evidencia.fechaEntregaAlumno != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Entregado el ${_formatearFecha(widget.evidencia.fechaEntregaAlumno!)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (!widget.evidencia.fueEntregadoATiempo) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Entregado con retraso',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // CARD: Comentarios privados
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comentarios privados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _comentarioCtrl,
                  decoration: InputDecoration(
                    hintText: 'Añade un comentario privado para tu profesor',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                  enabled: !estaEntregado || fueDevuelto,
                  onChanged: (_) => _autoSave(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _estadoChip(EstadoEvidencia estado) {
    Color bg;
    String label;
    switch (estado) {
      case EstadoEvidencia.asignado:
        bg = Colors.orange[100]!;
        label = 'Sin entregar';
        break;
      case EstadoEvidencia.entregado:
        bg = Colors.blue[100]!;
        label = 'Entregado';
        break;
      case EstadoEvidencia.calificado:
        bg = Colors.green[100]!;
        label = 'Calificado';
        break;
      case EstadoEvidencia.devuelto:
        bg = Colors.red[100]!;
        label = 'Devuelto';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}, ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _entregar() async {
    setState(() => _guardando = true);
    final provider = context.read<CuadernoProvider>();

    final evidenciaActualizada = widget.evidencia.copyWith(
      estado: EstadoEvidencia.entregado,
      fechaEntregaAlumno: DateTime.now(),
      comentarioAlumno: _comentarioCtrl.text.trim(),
      enlaceExterno: _enlaceCtrl.text.trim(),
      archivosAdjuntos: _archivosAdjuntos,
    );

    final ok = await provider.actualizarEvidencia(evidenciaActualizada);

    if (mounted) {
      setState(() => _guardando = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trabajo entregado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.lastError ?? 'Error al entregar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _anularEntrega() async {
    setState(() => _guardando = true);
    final provider = context.read<CuadernoProvider>();
    final evidenciaActualizada = widget.evidencia.copyWith(
      estado: EstadoEvidencia.asignado,
      fechaEntregaAlumno: null,
    );
    final ok = await provider.actualizarEvidencia(evidenciaActualizada);
    if (mounted) {
      setState(() => _guardando = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega anulada, puedes volver a modificar'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.lastError ?? 'Error al anular entrega'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ======= Extras aplicados =======
  void _iniciarCountdown() {
    void actualizar() {
      final now = DateTime.now();
      final due = widget.evidencia.fechaEntrega;
      final diff = due.difference(now);
      if (diff.isNegative) {
        setState(() {
          _restante = 'Entrega vencida el ${_formatearFecha(due)}';
        });
      } else {
        final d = diff.inDays;
        final h = diff.inHours % 24;
        final m = diff.inMinutes % 60;
        setState(() {
          _restante = d > 0 ? 'Faltan ${d}d ${h}h ${m}m' : 'Faltan ${h}h ${m}m';
        });
      }
    }

    actualizar();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => actualizar(),
    );
  }

  Future<void> _agregarArchivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.bytes == null) return;
      setState(() => _subiendo = true);

      final ref = FirebaseStorage.instance
          .ref()
          .child('evidencias')
          .child(widget.evidencia.materiaId)
          .child(widget.evidencia.alumnoId)
          .child(widget.evidencia.id)
          .child(file.name);

      final task = await ref.putData(file.bytes!, SettableMetadata());
      final url = await task.ref.getDownloadURL();
      setState(() {
        _archivosAdjuntos.add(url);
      });

      // Persistir en Firestore
      if (!mounted) return;
      final provider = context.read<CuadernoProvider>();
      final updated = widget.evidencia.copyWith(
        archivosAdjuntos: _archivosAdjuntos,
      );
      await provider.actualizarEvidencia(updated);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Archivo subido')));
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains("LateInitializationError")
            ? 'No se pudo iniciar Firebase Storage. En tu proyecto Firebase el módulo Storage no está habilitado (o requiere actualizar el plan). Abre la consola > Storage y crea el bucket; luego vuelve a correr la app.'
            : 'Error subiendo archivo: $e';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _abrirUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await canLaunchUrl(uri)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enlace inválido')));
    }
  }

  void _autoSave() {
    // Solo si aún puede editar
    final editable = widget.evidencia.estado != EstadoEvidencia.calificado;
    if (!editable) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), () async {
      final provider = context.read<CuadernoProvider>();
      final updated = widget.evidencia.copyWith(
        comentarioAlumno: _comentarioCtrl.text.trim(),
        enlaceExterno: _enlaceCtrl.text.trim(),
        archivosAdjuntos: _archivosAdjuntos,
      );
      await provider.actualizarEvidencia(updated);
    });
  }

  Widget _buildEnlacePreview(String url) {
    if (url.trim().isEmpty) return const SizedBox.shrink();
    final host = Uri.tryParse(url)?.host ?? '';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.link),
      title: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        host,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: TextButton(
        onPressed: () => _abrirUrl(url),
        child: const Text('Abrir'),
      ),
      onTap: () => _abrirUrl(url),
    );
  }

  void _mostrarDialogoEnlace() {
    final controller = TextEditingController(text: _enlaceCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir enlace'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://ejemplo.com',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _enlaceCtrl.text = controller.text.trim();
              });
              _autoSave();
              Navigator.pop(ctx);
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _mostrarMensajeProximamente(String funcion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$funcion próximamente'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
