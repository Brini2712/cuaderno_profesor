import 'package:flutter/material.dart';
import '../models/materia.dart';

class CrearMateriaDialog extends StatefulWidget {
  final Function(Materia) onCrear;

  const CrearMateriaDialog({super.key, required this.onCrear});

  @override
  State<CrearMateriaDialog> createState() => _CrearMateriaDialogState();
}

class _CrearMateriaDialogState extends State<CrearMateriaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _grupoController = TextEditingController();

  String _colorSeleccionado = '#2196F3';

  final List<String> _coloresDisponibles = [
    '#2196F3', // Azul
    '#4CAF50', // Verde
    '#FF9800', // Naranja
    '#9C27B0', // Púrpura
    '#F44336', // Rojo
    '#607D8B', // Azul gris
    '#795548', // Marrón
    '#E91E63', // Rosa
    '#00BCD4', // Cian
    '#8BC34A', // Verde claro
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _grupoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Materia'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la materia',
                hintText: 'Ej: Matemáticas I',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el nombre de la materia';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _grupoController,
              decoration: const InputDecoration(
                labelText: 'Número de grupo (opcional)',
                hintText: 'Ej: 501',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Descripción de la materia',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecciona un color:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _coloresDisponibles.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _colorSeleccionado = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _colorSeleccionado == color
                            ? Colors.black
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: _colorSeleccionado == color
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _crearMateria, child: const Text('Crear')),
      ],
    );
  }

  void _crearMateria() {
    if (_formKey.currentState?.validate() ?? false) {
      final codigoAcceso = _generarCodigoAcceso();

      final materia = Materia(
        id: '', // Se asignará en el provider
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        color: _colorSeleccionado,
        profesorId: '', // Se asignará en el provider
        fechaCreacion: DateTime.now(),
        codigoAcceso: codigoAcceso,
        grupo: _grupoController.text.trim().isEmpty
            ? null
            : _grupoController.text.trim(),
      );

      widget.onCrear(materia);
      Navigator.of(context).pop();
    }
  }

  String _generarCodigoAcceso() {
    // Generar un código aleatorio de 6 caracteres
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String codigo = '';

    for (int i = 0; i < 6; i++) {
      codigo += chars[(random + i) % chars.length];
    }

    return codigo;
  }
}
