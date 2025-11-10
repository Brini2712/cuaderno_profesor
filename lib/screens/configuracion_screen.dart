import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/cuaderno_provider.dart';
import '../providers/theme_provider.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _notificacionesActivas = true;
  bool _recordatoriosEvidencias = true;
  bool _recordatoriosAsistencia = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Consumer<CuadernoProvider>(
        builder: (context, provider, child) {
          final usuario = provider.usuario!;
          return ListView(
            children: [
              // Sección de Notificaciones
              _buildSeccionHeader('Notificaciones'),
              SwitchListTile(
                title: const Text('Notificaciones generales'),
                subtitle: const Text('Recibir notificaciones de la aplicación'),
                value: _notificacionesActivas,
                onChanged: (value) {
                  setState(() => _notificacionesActivas = value);
                },
                secondary: const Icon(Icons.notifications),
              ),
              if (_notificacionesActivas) ...[
                SwitchListTile(
                  title: const Text('Recordatorios de actividades'),
                  subtitle: const Text(
                    'Notificar sobre actividades próximas a vencer',
                  ),
                  value: _recordatoriosEvidencias,
                  onChanged: (value) {
                    setState(() => _recordatoriosEvidencias = value);
                  },
                  secondary: const Icon(Icons.assignment),
                ),
                SwitchListTile(
                  title: const Text('Recordatorios de asistencia'),
                  subtitle: const Text(
                    'Notificar sobre registro de asistencia',
                  ),
                  value: _recordatoriosAsistencia,
                  onChanged: (value) {
                    setState(() => _recordatoriosAsistencia = value);
                  },
                  secondary: const Icon(Icons.how_to_reg),
                ),
              ],
              const Divider(),

              // Sección de Apariencia
              _buildSeccionHeader('Apariencia'),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return SwitchListTile(
                    title: const Text('Modo oscuro'),
                    subtitle: const Text('Usar tema oscuro en la aplicación'),
                    value: themeProvider.modoOscuro,
                    onChanged: (value) {
                      themeProvider.toggleModoOscuro();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? '🌙 Modo oscuro activado'
                                : '☀️ Modo claro activado',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    secondary: const Icon(Icons.dark_mode),
                  );
                },
              ),
              const Divider(),

              // Sección de Cuenta
              _buildSeccionHeader('Cuenta'),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Correo electrónico'),
                subtitle: Text(usuario.email),
                trailing: const Icon(Icons.info_outline),
                onTap: () {
                  _mostrarDialogoInfo(
                    context,
                    'Correo electrónico',
                    'Tu correo electrónico no puede ser modificado una vez creada la cuenta.',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Cambiar contraseña'),
                subtitle: const Text('Actualizar tu contraseña'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _mostrarCambiarContrasena(context),
              ),
              const Divider(),

              // Sección de Ayuda
              _buildSeccionHeader('Ayuda y soporte'),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Centro de ayuda'),
                subtitle: const Text('Preguntas frecuentes y tutoriales'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función próximamente')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.contact_support),
                title: const Text('Contactar soporte'),
                subtitle: const Text('Enviar un mensaje al equipo de soporte'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _contactarSoporte(context),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Acerca de'),
                subtitle: const Text('Versión 1.0.0'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _mostrarAcercaDe(context),
              ),
              const Divider(),

              // Sección de Datos
              _buildSeccionHeader('Datos y privacidad'),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Exportar mis datos'),
                subtitle: const Text('Descargar una copia de tus datos'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función próximamente')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Política de privacidad'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función próximamente')),
                  );
                },
              ),
              const Divider(),

              // Cerrar sesión y eliminar cuenta
              _buildSeccionHeader('Zona peligrosa'),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.orange),
                ),
                onTap: () => _confirmarCerrarSesion(context, provider),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Eliminar cuenta',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _confirmarEliminarCuenta(context),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeccionHeader(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        titulo.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _mostrarDialogoInfo(
    BuildContext context,
    String titulo,
    String mensaje,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _mostrarCambiarContrasena(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña actual',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña actual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contraseña actualizada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _contactarSoporte(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contactar soporte'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Puedes contactarnos por:'),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email, size: 20),
                SizedBox(width: 8),
                Text('soporte@cuadernoprofesor.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 20),
                SizedBox(width: 8),
                Text('+52 (123) 456-7890'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarAcercaDe(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Cuaderno Profesor',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.school,
        size: 48,
        color: Color(0xFF1976D2),
      ),
      children: const [
        Text('Sistema de gestión académica para profesores y alumnos.'),
        SizedBox(height: 8),
        Text('Desarrollado con Flutter y Firebase.'),
      ],
    );
  }

  void _confirmarCerrarSesion(BuildContext context, CuadernoProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.cerrarSesion();
              if (!context.mounted) return;
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminarCuenta(BuildContext context) {
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⚠️ Esta acción es irreversible. Se eliminarán todos tus datos permanentemente.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Escribe "ELIMINAR" para confirmar:'),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmController,
                decoration: const InputDecoration(
                  hintText: 'ELIMINAR',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != 'ELIMINAR') {
                    return 'Debes escribir ELIMINAR para confirmar';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Función próximamente'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
  }
}
