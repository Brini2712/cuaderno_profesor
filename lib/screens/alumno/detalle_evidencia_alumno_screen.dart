import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    _enlaceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estaEntregado =
        widget.evidencia.estado != EstadoEvidencia.asignado &&
        widget.evidencia.estado != EstadoEvidencia.devuelto;
    final fueDevuelto = widget.evidencia.estado == EstadoEvidencia.devuelto;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de evidencia'),
        actions: [
          if (!estaEntregado || fueDevuelto)
            FilledButton(
              onPressed: _guardando ? null : _entregar,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(fueDevuelto ? 'Reenviar' : 'Entregar'),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.all(24),
            color: _getColorEstado(widget.evidencia.estado).withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconoEstado(widget.evidencia.estado),
                      color: _getColorEstado(widget.evidencia.estado),
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.evidencia.titulo,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getLabelEstado(widget.evidencia.estado),
                            style: TextStyle(
                              color: _getColorEstado(widget.evidencia.estado),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label:
                          'Entrega: ${widget.evidencia.fechaEntrega.day}/${widget.evidencia.fechaEntrega.month}',
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.assessment,
                      label: '${widget.evidencia.puntosTotales} puntos',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Instrucciones
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instrucciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.evidencia.descripcion.isEmpty
                      ? 'Sin instrucciones adicionales'
                      : widget.evidencia.descripcion,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),

          // Si ya está entregado, mostrar calificación
          if (widget.evidencia.estado == EstadoEvidencia.calificado) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.green.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.grade, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Calificación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.evidencia.calificacionNumerica!.toStringAsFixed(1)} / ${widget.evidencia.puntosTotales}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (widget.evidencia.comentarioProfesor != null &&
                      widget.evidencia.comentarioProfesor!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Comentarios del profesor:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(widget.evidencia.comentarioProfesor!),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Si fue devuelto, mostrar mensaje
          if (fueDevuelto) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.orange.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_return, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Trabajo devuelto para corrección',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  if (widget.evidencia.comentarioProfesor != null &&
                      widget.evidencia.comentarioProfesor!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(widget.evidencia.comentarioProfesor!),
                  ],
                ],
              ),
            ),
          ],

          const Divider(height: 1),

          // Formulario de entrega (si no está calificado)
          if (widget.evidencia.estado != EstadoEvidencia.calificado)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu trabajo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _comentarioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Comentario (opcional)',
                      hintText:
                          'Añade cualquier aclaración sobre tu trabajo...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    enabled: !estaEntregado || fueDevuelto,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _enlaceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Enlace externo (opcional)',
                      hintText: 'https://...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    enabled: !estaEntregado || fueDevuelto,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: estaEntregado && !fueDevuelto
                        ? null
                        : _agregarArchivo,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Adjuntar archivo'),
                  ),
                  if (_archivosAdjuntos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._archivosAdjuntos.map(
                      (archivo) => ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(archivo.split('/').last),
                        trailing: estaEntregado && !fueDevuelto
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _archivosAdjuntos.remove(archivo);
                                  });
                                },
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Mostrar trabajo entregado si ya fue enviado
          if (estaEntregado &&
              widget.evidencia.estado != EstadoEvidencia.calificado &&
              !fueDevuelto)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu trabajo entregado',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entregado el ${widget.evidencia.fechaEntregaAlumno!.day}/${widget.evidencia.fechaEntregaAlumno!.month}/${widget.evidencia.fechaEntregaAlumno!.year}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (widget.evidencia.comentarioAlumno != null &&
                      widget.evidencia.comentarioAlumno!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(widget.evidencia.comentarioAlumno!),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Chip(avatar: Icon(icon, size: 16), label: Text(label));
  }

  Color _getColorEstado(EstadoEvidencia estado) {
    switch (estado) {
      case EstadoEvidencia.asignado:
        return Colors.orange;
      case EstadoEvidencia.entregado:
        return Colors.blue;
      case EstadoEvidencia.calificado:
        return Colors.green;
      case EstadoEvidencia.devuelto:
        return Colors.red;
    }
  }

  IconData _getIconoEstado(EstadoEvidencia estado) {
    switch (estado) {
      case EstadoEvidencia.asignado:
        return Icons.assignment;
      case EstadoEvidencia.entregado:
        return Icons.check_circle;
      case EstadoEvidencia.calificado:
        return Icons.grade;
      case EstadoEvidencia.devuelto:
        return Icons.assignment_return;
    }
  }

  String _getLabelEstado(EstadoEvidencia estado) {
    switch (estado) {
      case EstadoEvidencia.asignado:
        return 'Asignado - Sin entregar';
      case EstadoEvidencia.entregado:
        return 'Entregado - Pendiente de calificación';
      case EstadoEvidencia.calificado:
        return 'Calificado';
      case EstadoEvidencia.devuelto:
        return 'Devuelto para corrección';
    }
  }

  void _agregarArchivo() {
    // TODO: Implementar selección de archivos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de adjuntar archivos próximamente'),
      ),
    );
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
}
