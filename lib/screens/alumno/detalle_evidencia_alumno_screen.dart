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
        // Título grande
        Text(
          widget.evidencia.titulo,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
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
                    _estadoChip(estado),
                  ],
                ),
                const SizedBox(height: 16),
                if (estado == EstadoEvidencia.calificado &&
                    widget.evidencia.calificacionNumerica != null) ...[
                  Text(
                    '${widget.evidencia.calificacionNumerica!.toStringAsFixed(1)} / ${widget.evidencia.puntosTotales.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
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
                  OutlinedButton.icon(
                    onPressed: _agregarArchivo,
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir o crear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
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
                if (_enlaceCtrl.text.isNotEmpty ||
                    (!estaEntregado || fueDevuelto)) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _enlaceCtrl,
                    decoration: InputDecoration(
                      hintText: 'Añadir enlace',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    enabled: !estaEntregado || fueDevuelto,
                  ),
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
                ),
                if (estado == EstadoEvidencia.calificado &&
                    widget.evidencia.comentarioProfesor != null &&
                    widget.evidencia.comentarioProfesor!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Comentario del profesor:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.evidencia.comentarioProfesor!,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ],
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

  void _agregarArchivo() {
    // TODO: Implementar selección de archivos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de adjuntar archivos próximamente'),
        duration: Duration(seconds: 2),
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
}
