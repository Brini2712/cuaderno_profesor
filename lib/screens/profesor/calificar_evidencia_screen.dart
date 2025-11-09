import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/evidencia.dart';
import '../../providers/cuaderno_provider.dart';

class CalificarEvidenciaScreen extends StatefulWidget {
  final Evidencia evidencia;

  const CalificarEvidenciaScreen({super.key, required this.evidencia});

  @override
  State<CalificarEvidenciaScreen> createState() =>
      _CalificarEvidenciaScreenState();
}

class _CalificarEvidenciaScreenState extends State<CalificarEvidenciaScreen> {
  late TextEditingController _calificacionCtrl;
  late TextEditingController _comentarioCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _calificacionCtrl = TextEditingController(
      text: widget.evidencia.calificacionNumerica?.toString() ?? '',
    );
    _comentarioCtrl = TextEditingController(
      text: widget.evidencia.comentarioProfesor ?? '',
    );
  }

  @override
  void dispose() {
    _calificacionCtrl.dispose();
    _comentarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CuadernoProvider>();
    final alumno = provider.alumnos.firstWhere(
      (a) => a.id == widget.evidencia.alumnoId,
      orElse: () => provider.alumnos.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Calificar - ${alumno.nombre}'),
        actions: [
          if (widget.evidencia.estado == EstadoEvidencia.calificado)
            TextButton(
              onPressed: _guardando ? null : _devolverParaCorreccion,
              child: const Text('Devolver'),
            ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _guardando ? null : _guardarCalificacion,
            child: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        children: [
          // Información de la entrega
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        alumno.nombre.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alumno.nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.evidencia.fechaEntregaAlumno != null)
                            Text(
                              'Entregado el ${widget.evidencia.fechaEntregaAlumno!.day}/${widget.evidencia.fechaEntregaAlumno!.month}/${widget.evidencia.fechaEntregaAlumno!.year} a las ${widget.evidencia.fechaEntregaAlumno!.hour}:${widget.evidencia.fechaEntregaAlumno!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.evidencia.fueEntregadoATiempo)
                      const Chip(
                        label: Text('A tiempo'),
                        backgroundColor: Colors.green,
                        labelStyle: TextStyle(color: Colors.white),
                      )
                    else if (widget.evidencia.fechaEntregaAlumno != null)
                      const Chip(
                        label: Text('Tarde'),
                        backgroundColor: Colors.orange,
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Trabajo del alumno
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trabajo del alumno',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (widget.evidencia.comentarioAlumno != null &&
                    widget.evidencia.comentarioAlumno!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.evidencia.comentarioAlumno!),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.evidencia.archivosAdjuntos.isNotEmpty) ...[
                  const Text(
                    'Archivos adjuntos:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ...widget.evidencia.archivosAdjuntos.map(
                    (url) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text(url.split('/').last),
                        trailing: const Icon(Icons.download),
                        onTap: () {
                          // TODO: Implementar descarga
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.evidencia.enlaceExterno != null &&
                    widget.evidencia.enlaceExterno!.isNotEmpty) ...[
                  const Text(
                    'Enlace externo:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.link),
                      title: Text(
                        widget.evidencia.enlaceExterno!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () {
                        // TODO: Abrir enlace
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Calificación
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calificación y comentarios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _calificacionCtrl,
                        decoration: InputDecoration(
                          labelText: 'Puntos',
                          hintText: widget.evidencia.puntosTotales.toString(),
                          border: const OutlineInputBorder(),
                          suffixText: '/ ${widget.evidencia.puntosTotales}',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _comentarioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Comentario privado para el alumno',
                    hintText:
                        'Añade comentarios sobre el trabajo del alumno...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarCalificacion() async {
    final calificacion = double.tryParse(_calificacionCtrl.text.trim());
    if (calificacion == null ||
        calificacion < 0 ||
        calificacion > widget.evidencia.puntosTotales) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ingresa una calificación entre 0 y ${widget.evidencia.puntosTotales}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    final provider = context.read<CuadernoProvider>();

    final evidenciaActualizada = widget.evidencia.copyWith(
      calificacionNumerica: calificacion,
      comentarioProfesor: _comentarioCtrl.text.trim(),
      estado: EstadoEvidencia.calificado,
      fechaCalificacion: DateTime.now(),
    );

    final ok = await provider.actualizarEvidencia(evidenciaActualizada);

    if (mounted) {
      setState(() => _guardando = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calificación guardada'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.lastError ?? 'Error al guardar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _devolverParaCorreccion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Devolver para corrección'),
        content: const Text(
          '¿Quieres devolver este trabajo al alumno para que lo corrija?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Devolver'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _guardando = true);
    final provider = context.read<CuadernoProvider>();

    final evidenciaActualizada = widget.evidencia.copyWith(
      estado: EstadoEvidencia.devuelto,
      comentarioProfesor: _comentarioCtrl.text.trim(),
    );

    final ok = await provider.actualizarEvidencia(evidenciaActualizada);

    if (mounted) {
      setState(() => _guardando = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trabajo devuelto para corrección'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.lastError ?? 'Error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
