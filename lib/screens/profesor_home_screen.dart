import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cuaderno_provider.dart';
import '../providers/notificaciones_provider.dart';
import '../models/materia.dart';
import '../widgets/materia_card.dart';
import '../widgets/crear_materia_dialog.dart';
import 'profesor/tomar_asistencia_screen.dart';
import 'profesor/detalle_materia_screen.dart';
import 'profesor/materia_search_delegate.dart';
import 'profesor/gestion_evidencias_screen.dart';
import 'perfil_screen.dart';
import 'configuracion_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class ProfesorHomeScreen extends StatefulWidget {
  const ProfesorHomeScreen({super.key});

  @override
  State<ProfesorHomeScreen> createState() => _ProfesorHomeScreenState();
}

class _ProfesorHomeScreenState extends State<ProfesorHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CuadernoProvider>(context, listen: false);
      if (provider.usuario == null) {
        context.go('/login');
        return;
      }

      // Iniciar escucha de notificaciones
      final notificacionesProvider = Provider.of<NotificacionesProvider>(
        context,
        listen: false,
      );
      notificacionesProvider.escucharNotificaciones(provider.usuario!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CuadernoProvider>(
      builder: (context, provider, child) {
        if (provider.usuario == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              // Menú lateral estilo Google Classroom
              NavigationRail(
                backgroundColor: Colors.white,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                labelType: NavigationRailLabelType.all,
                leading: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Logo o título
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.school,
                        size: 32,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icono de notificaciones con badge
                          Consumer<NotificacionesProvider>(
                            builder: (context, notifProvider, _) {
                              final noLeidas =
                                  notifProvider.notificacionesNoLeidas;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                    ),
                                    onPressed: () =>
                                        context.push('/notificaciones'),
                                    tooltip: 'Notificaciones',
                                  ),
                                  if (noLeidas > 0)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          noLeidas > 9
                                              ? '9+'
                                              : noLeidas.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => const ConfiguracionScreen(),
                                ),
                              );
                            },
                            tooltip: 'Ajustes',
                          ),
                          const SizedBox(height: 8),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'logout') {
                                _cerrarSesion(provider);
                              } else if (value == 'profile') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => const PerfilScreen(),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'profile',
                                child: Row(
                                  children: const [
                                    Icon(Icons.person),
                                    SizedBox(width: 8),
                                    Text('Mi Perfil'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: const [
                                    Icon(Icons.logout),
                                    SizedBox(width: 8),
                                    Text('Cerrar Sesión'),
                                  ],
                                ),
                              ),
                            ],
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFF1976D2),
                              child: Text(
                                provider.usuario?.nombre
                                        .substring(0, 1)
                                        .toUpperCase() ??
                                    'P',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('Inicio'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.class_outlined),
                    selectedIcon: Icon(Icons.class_),
                    label: Text('Materias'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.how_to_reg_outlined),
                    selectedIcon: Icon(Icons.how_to_reg),
                    label: Text('Asistencia'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.assignment_outlined),
                    selectedIcon: Icon(Icons.assignment),
                    label: Text('Evidencias'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.assessment_outlined),
                    selectedIcon: Icon(Icons.assessment),
                    label: Text('Reportes'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              // Contenido principal
              Expanded(
                child: Column(
                  children: [
                    // AppBar personalizado
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getTituloPorSeccion(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedIndex == 1)
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () {
                                showSearch(
                                  context: context,
                                  delegate: MateriaSearchDelegate(),
                                );
                              },
                              tooltip: 'Buscar materia',
                            ),
                        ],
                      ),
                    ),
                    // Contenido
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: [
                          _buildInicioTab(provider),
                          _buildMateriasTab(provider),
                          _buildAsistenciasTab(provider),
                          _buildEvidenciasTab(provider),
                          _buildReportesTab(provider),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _selectedIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: () => _mostrarCrearMateria(provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear materia'),
                )
              : null,
        );
      },
    );
  }

  String _getTituloPorSeccion() {
    switch (_selectedIndex) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Materias';
      case 2:
        return 'Asistencia';
      case 3:
        return 'Evidencias';
      case 4:
        return 'Reportes';
      default:
        return 'Cuaderno Profesor';
    }
  }

  Widget _buildInicioTab(CuadernoProvider provider) {
    final totalMaterias = provider.materias.length;
    final totalAlumnos = provider.alumnos.length;
    final materiasActivas = provider.materias
        .where((m) => m.alumnosIds.isNotEmpty)
        .length;

    return RefreshIndicator(
      onRefresh: () => provider.cargarDatos(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Saludo
          Text(
            '¡Hola, ${provider.usuario?.nombre ?? "Profesor"}!',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 8),
          Text(
            'Bienvenido a tu cuaderno digital',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Tarjetas de resumen
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard(
                icon: Icons.class_,
                title: 'Materias',
                value: totalMaterias.toString(),
                subtitle: '$materiasActivas activas',
                color: Colors.blue,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _buildStatCard(
                icon: Icons.people,
                title: 'Alumnos',
                value: totalAlumnos.toString(),
                subtitle: 'Total registrados',
                color: Colors.green,
              ),
              _buildStatCard(
                icon: Icons.assignment,
                title: 'Evidencias',
                value: provider.contarEvidenciasUnicas().toString(),
                subtitle: 'Conjuntos únicos',
                color: Colors.orange,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              _buildStatCard(
                icon: Icons.how_to_reg,
                title: 'Asistencias',
                value: provider.asistencias.length.toString(),
                subtitle: 'Registros totales',
                color: Colors.purple,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Materias recientes
          if (provider.materias.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Materias recientes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...provider.materias
                .take(3)
                .map(
                  (materia) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(
                          int.parse(materia.color.replaceAll('#', '0xFF')),
                        ),
                        child: const Icon(Icons.book, color: Colors.white),
                      ),
                      title: Text(materia.nombre),
                      subtitle: Text(
                        '${materia.alumnosIds.length} alumnos • ${materia.descripcion}',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _navegarAMateria(materia),
                    ),
                  ),
                ),
          ] else
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.class_, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes materias aún',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _mostrarCrearMateria(provider),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear tu primera materia'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMateriasTab(CuadernoProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.cargarDatos(),
      child: provider.materias.isEmpty
          ? _buildEmptyState(
              icon: Icons.class_,
              title: 'No tienes materias',
              subtitle: 'Crea tu primera materia para empezar',
              actionText: 'Crear Materia',
              onAction: () => _mostrarCrearMateria(provider),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.materias.length,
              itemBuilder: (context, index) {
                final materia = provider.materias[index];
                return MateriaCard(
                  materia: materia,
                  onTap: () => _navegarAMateria(materia),
                  onEditar: () => _editarMateria(context, provider, materia),
                  onEliminar: () =>
                      _confirmarEliminar(context, provider, materia),
                  onCopiarCodigo: () => _copiarCodigo(context, materia),
                );
              },
            ),
    );
  }

  Widget _buildAsistenciasTab(CuadernoProvider provider) {
    if (provider.materias.isEmpty) {
      return _buildEmptyState(
        icon: Icons.how_to_reg,
        title: 'Sin materias para tomar asistencia',
        subtitle: 'Crea una materia y agrega alumnos para comenzar',
        actionText: 'Crear Materia',
        onAction: () => _mostrarCrearMateria(provider),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.materias.length,
      itemBuilder: (context, index) {
        final m = provider.materias[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Container(
              width: 6,
              height: double.infinity,
              color: Color(int.parse(m.color.replaceAll('#', '0xFF'))),
            ),
            title: Text(
              m.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(m.descripcion),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.fact_check),
              label: const Text('Tomar asistencia'),
              onPressed: () => _abrirTomarAsistencia(m),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEvidenciasTab(CuadernoProvider provider) {
    if (provider.materias.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment,
        title: 'Sin materias para gestionar evidencias',
        subtitle: 'Crea una materia primero',
        actionText: 'Crear Materia',
        onAction: () => _mostrarCrearMateria(provider),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.materias.length,
      itemBuilder: (context, index) {
        final m = provider.materias[index];
        final numEvidencias = provider.contarEvidenciasUnicas(materiaId: m.id);
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Container(
              width: 6,
              height: double.infinity,
              color: Color(int.parse(m.color.replaceAll('#', '0xFF'))),
            ),
            title: Text(
              m.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('$numEvidencias evidencias registradas'),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.assignment),
              label: const Text('Gestionar'),
              onPressed: () => _abrirGestionEvidencias(m),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportesTab(CuadernoProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.analytics, size: 64, color: Colors.blue[700]),
          ),
          const SizedBox(height: 24),
          const Text(
            'Reportes y Estadísticas',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Accede a la versión web para visualizar reportes completos',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/reportes');
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Abrir Reportes Web'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onAction, child: Text(actionText)),
          ],
        ],
      ),
    );
  }

  void _mostrarCrearMateria(CuadernoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => CrearMateriaDialog(
        onCrear: (materia) async {
          await provider.agregarMateria(materia);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Materia creada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _navegarAMateria(Materia materia) {
    // Navegar a la pantalla de detalle
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetalleMateriaScreen(materia: materia)),
    );
  }

  void _abrirTomarAsistencia(Materia m) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TomarAsistenciaScreen(materia: m)),
    );
  }

  void _abrirGestionEvidencias(Materia m) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GestionEvidenciasScreen(materia: m)),
    );
  }

  void _copiarCodigo(BuildContext ctx, Materia materia) {
    final code = materia.codigoAcceso ?? '';
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Código copiado')));
  }

  void _confirmarEliminar(
    BuildContext ctx,
    CuadernoProvider provider,
    Materia materia,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar materia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas eliminar definitivamente "${materia.nombre}"?'),
            const SizedBox(height: 12),
            const Text(
              'Esta acción eliminará también evidencias, asistencias y calificaciones asociadas. No se puede deshacer.',
              style: TextStyle(fontSize: 13, color: Colors.redAccent),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await provider.eliminarMateria(
                materia.id,
                soft: false,
                cascade: true,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Materia eliminada definitivamente'
                        : (provider.lastError ?? 'No se pudo eliminar'),
                  ),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );
  }

  void _editarMateria(
    BuildContext ctx,
    CuadernoProvider provider,
    Materia materia,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => CrearMateriaDialog(
        onCrear: (m) async {
          final editado = materia.copyWith(
            nombre: m.nombre,
            descripcion: m.descripcion,
            color: m.color,
            grupo: m.grupo,
          );
          final ok = await provider.actualizarMateria(editado);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok
                    ? 'Materia actualizada'
                    : (provider.lastError ?? 'Error actualizando'),
              ),
              backgroundColor: ok ? Colors.green : Colors.red,
            ),
          );
        },
      ),
    );
  }

  void _cerrarSesion(CuadernoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await provider.cerrarSesion();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
