import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' show File;
import '../providers/cuaderno_provider.dart';
import '../models/usuario.dart';
import '../models/actividad.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  bool _editando = false;
  bool _guardando = false;
  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    final usuario = context.read<CuadernoProvider>().usuario!;
    // Usamos nombreCompleto para edición; si aún no están los apellidos capturados
    // el getter nombreCompleto construirá la mejor representación.
    _nombreController = TextEditingController(text: usuario.nombreCompleto);
    _emailController = TextEditingController(text: usuario.email);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (_editando)
            TextButton.icon(
              onPressed: _guardando ? null : _cancelarEdicion,
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            TextButton.icon(
              onPressed: () => setState(() => _editando = true),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'Editar',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Consumer<CuadernoProvider>(
        builder: (context, provider, child) {
          final usuario = provider.usuario!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    // Foto de perfil
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFF1976D2),
                          backgroundImage:
                              usuario.fotoUrl != null &&
                                  usuario.fotoUrl!.isNotEmpty
                              ? NetworkImage(usuario.fotoUrl!)
                              : null,
                          child:
                              usuario.fotoUrl == null ||
                                  usuario.fotoUrl!.isEmpty
                              ? Text(
                                  usuario.nombreCompleto
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        if (_editando)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 18,
                              child: _subiendoFoto
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.camera_alt,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: _cambiarFoto,
                                    ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Formulario
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre
                          TextFormField(
                            controller: _nombreController,
                            enabled: _editando,
                            decoration: InputDecoration(
                              labelText: 'Nombre completo',
                              prefixIcon: const Icon(Icons.person),
                              filled: !_editando,
                              fillColor: _editando ? null : Colors.grey[100],
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El nombre es obligatorio';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Email (solo lectura)
                          TextFormField(
                            controller: _emailController,
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: const Icon(Icons.email),
                              filled: true,
                              fillColor: Colors.grey[100],
                              helperText: 'El email no puede modificarse',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tipo de usuario
                          TextFormField(
                            initialValue: usuario.tipo == TipoUsuario.profesor
                                ? 'Profesor'
                                : 'Alumno',
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Tipo de usuario',
                              prefixIcon: const Icon(Icons.badge),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Fecha de registro
                          TextFormField(
                            initialValue: _formatearFecha(
                              usuario.fechaCreacion,
                            ),
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Miembro desde',
                              prefixIcon: const Icon(Icons.calendar_today),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Botón guardar (solo visible en modo edición)
                          if (_editando)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _guardando ? null : _guardarCambios,
                                icon: _guardando
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                  _guardando
                                      ? 'Guardando...'
                                      : 'Guardar Cambios',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Estadísticas (solo para visualización)
                    _buildEstadisticas(provider, usuario),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEstadisticas(CuadernoProvider provider, Usuario usuario) {
    if (usuario.tipo == TipoUsuario.profesor) {
      final totalMaterias = provider.materias.length;
      final totalAlumnos = provider.materias.fold<int>(
        0,
        (sum, materia) => sum + materia.alumnosIds.length,
      );
      final totalEvidencias = provider.contarEvidenciasUnicas();

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen de actividad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                Icons.class_,
                'Materias creadas',
                totalMaterias.toString(),
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                Icons.people,
                'Alumnos inscritos',
                totalAlumnos.toString(),
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                Icons.assignment,
                'Actividades asignadas',
                totalEvidencias.toString(),
              ),
            ],
          ),
        ),
      );
    } else {
      final totalClases = provider.materias.length;
      final evidenciasAlumno = provider.evidencias
          .where((e) => e.alumnoId == usuario.id)
          .toList();
      final evidenciasEntregadas = evidenciasAlumno
          .where((e) => e.estado != EstadoEvidencia.asignado)
          .length;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen de actividad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                Icons.class_,
                'Clases inscritas',
                totalClases.toString(),
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                Icons.assignment,
                'Actividades asignadas',
                evidenciasAlumno.length.toString(),
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                Icons.check_circle,
                'Actividades entregadas',
                evidenciasEntregadas.toString(),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1976D2)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _subiendoFoto = true);

    try {
      if (!mounted) return;
      final provider = context.read<CuadernoProvider>();
      final usuario = provider.usuario!;

      // Subir a Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('perfiles')
          .child('${usuario.id}.jpg');

      await ref.putFile(File(pickedFile.path));
      final url = await ref.getDownloadURL();

      // Actualizar usuario
      // Mantener nombre completo actual al cambiar foto
      await provider.actualizarPerfil(
        nombre: usuario.nombreCompleto,
        fotoUrl: url,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir la foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _subiendoFoto = false);
      }
    }
  }

  void _cancelarEdicion() {
    final usuario = context.read<CuadernoProvider>().usuario!;
    _nombreController.text = usuario.nombreCompleto;
    setState(() => _editando = false);
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final provider = context.read<CuadernoProvider>();
      await provider.actualizarPerfil(nombre: _nombreController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _editando = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }
}
