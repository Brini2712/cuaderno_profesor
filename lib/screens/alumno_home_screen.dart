import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cuaderno_provider.dart';
import '../providers/notificaciones_provider.dart';
import 'package:go_router/go_router.dart';
import '../models/materia.dart';
import '../models/evidencia.dart';
import 'alumno/alumno_evidencias_screen.dart';
import 'alumno/calendario_alumno_widget.dart';
import 'perfil_screen.dart';
import 'configuracion_screen.dart';

class AlumnoHomeScreen extends StatefulWidget {
  const AlumnoHomeScreen({super.key});

  @override
  State<AlumnoHomeScreen> createState() => _AlumnoHomeScreenState();
}

class _AlumnoHomeScreenState extends State<AlumnoHomeScreen> {
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Consumer<CuadernoProvider>(
      builder: (context, provider, child) {
        if (provider.usuario == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Layout móvil con BottomNavigationBar
        if (isMobile) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_getTituloPorSeccion()),
              actions: [
                if (_selectedIndex == 1)
                  IconButton(
                    icon: const Icon(Icons.add_box_outlined),
                    onPressed: () => _mostrarUnirseAClase(provider),
                    tooltip: 'Unirse a clase',
                  ),
                // Icono de campanita con badge
                Consumer<NotificacionesProvider>(
                  builder: (context, notifProvider, _) {
                    final noLeidas = notifProvider.notificacionesNoLeidas;
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () => context.push('/notificaciones'),
                          tooltip: 'Notificaciones',
                        ),
                        if (noLeidas > 0)
                          Positioned(
                            right: 8,
                            top: 8,
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
                                noLeidas > 9 ? '9+' : noLeidas.toString(),
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
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      _cerrarSesion(provider);
                    } else if (value == 'join') {
                      _mostrarUnirseAClase(provider);
                    } else if (value == 'profile') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const PerfilScreen(),
                        ),
                      );
                    } else if (value == 'settings') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const ConfiguracionScreen(),
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
                      value: 'settings',
                      child: Row(
                        children: const [
                          Icon(Icons.settings),
                          SizedBox(width: 8),
                          Text('Configuración'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'join',
                      child: Row(
                        children: const [
                          Icon(Icons.add_box),
                          SizedBox(width: 8),
                          Text('Unirse a Clase'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
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
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF1976D2),
                      radius: 16,
                      child: Text(
                        provider.usuario?.nombre
                                .substring(0, 1)
                                .toUpperCase() ??
                            'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildInicioTab(provider),
                _buildMisClasesTab(provider),
                _buildCalendarioTab(provider),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.class_outlined),
                  activeIcon: Icon(Icons.class_),
                  label: 'Mis clases',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_today),
                  label: 'Calendario',
                ),
              ],
            ),
            floatingActionButton: _selectedIndex == 1
                ? FloatingActionButton(
                    onPressed: () => _mostrarUnirseAClase(provider),
                    child: const Icon(Icons.add),
                  )
                : null,
          );
        }

        // Layout desktop/tablet con NavigationRail
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
                          // Icono de notificaciones
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
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'logout') {
                                _cerrarSesion(provider);
                              } else if (value == 'join') {
                                _mostrarUnirseAClase(provider);
                              } else if (value == 'profile') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => const PerfilScreen(),
                                  ),
                                );
                              } else if (value == 'settings') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        const ConfiguracionScreen(),
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
                                value: 'settings',
                                child: Row(
                                  children: const [
                                    Icon(Icons.settings),
                                    SizedBox(width: 8),
                                    Text('Configuración'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'join',
                                child: Row(
                                  children: const [
                                    Icon(Icons.add_box),
                                    SizedBox(width: 8),
                                    Text('Unirse a Clase'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
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
                                    'A',
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
                    label: Text('Mis clases'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_today_outlined),
                    selectedIcon: Icon(Icons.calendar_today),
                    label: Text('Calendario'),
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
                            color: Colors.black.withOpacity(0.05),
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
                          IconButton(
                            icon: const Icon(Icons.add_box_outlined),
                            onPressed: () => _mostrarUnirseAClase(provider),
                            tooltip: 'Unirse a clase',
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
                          _buildMisClasesTab(provider),
                          _buildCalendarioTab(provider),
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
                  onPressed: () => _mostrarUnirseAClase(provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Unirse a clase'),
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
        return 'Mis clases';
      case 2:
        return 'Calendario';
      default:
        return 'Mi Progreso';
    }
  }

  Widget _buildInicioTab(CuadernoProvider provider) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () => provider.cargarDatos(),
      child: provider.materias.isEmpty
          ? _buildEmptyState(provider)
          : ListView(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              children: [
                Text(
                  '¡Hola, ${provider.usuario?.nombre ?? "Alumno"}!',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),
                _buildResumenGeneral(provider),
                SizedBox(height: isMobile ? 20 : 32),
                Text(
                  'Mis clases',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                ...provider.materias.map(
                  (materia) => _buildMateriaCard(materia, provider),
                ),
              ],
            ),
    );
  }

  Widget _buildResumenGeneral(CuadernoProvider provider) {
    final totalClases = provider.materias.length;
    final totalEvidencias = provider.evidencias
        .where((e) => e.alumnoId == provider.usuario!.id)
        .length;
    final evidenciasEntregadas = provider.evidencias
        .where(
          (e) =>
              e.alumnoId == provider.usuario!.id &&
              e.estado != EstadoEvidencia.asignado,
        )
        .length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCardAlumno(
          icon: Icons.class_,
          title: 'Clases',
          value: totalClases.toString(),
          color: Colors.blue,
        ),
        _buildStatCardAlumno(
          icon: Icons.assignment,
          title: 'Evidencias',
          value: '$evidenciasEntregadas/$totalEvidencias',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCardAlumno({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: isMobile ? (screenWidth - 40) / 2 : 180,
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: isMobile ? 24 : 28),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMateriaCard(Materia materia, CuadernoProvider provider) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navegarADetalleMateria(materia.id),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: isMobile ? 40 : 50,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(materia.color.replaceAll('#', '0xFF')),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      materia.nombre,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      materia.descripcion,
                      maxLines: isMobile ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: isMobile ? 14 : 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMisClasesTab(CuadernoProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.cargarDatos(),
      child: provider.materias.isEmpty
          ? _buildEmptyState(provider)
          : _buildMateriasList(provider),
    );
  }

  Widget _buildCalendarioTab(CuadernoProvider provider) {
    return const CalendarioAlumnoWidget();
  }

  Widget _buildEmptyState(CuadernoProvider provider) {
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
            child: Icon(Icons.school, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            'No estás inscrito en ninguna clase',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Únete a una clase usando el código proporcionado por tu profesor',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _mostrarUnirseAClase(provider),
            icon: const Icon(Icons.add),
            label: const Text('Unirse a Clase'),
          ),
        ],
      ),
    );
  }

  Widget _buildMateriasList(CuadernoProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.materias.length,
      itemBuilder: (context, index) {
        final materia = provider.materias[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navegarADetalleMateria(materia.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(materia.color.replaceAll('#', '0xFF')),
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              materia.nombre,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              materia.descripcion,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEstadisticasRapidas(provider, materia.id),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstadisticasRapidas(
    CuadernoProvider provider,
    String materiaId,
  ) {
    // Calcular estadísticas para esta materia
    double porcentajeAsistencia = provider.calcularPorcentajeAsistencia(
      provider.usuario!.id,
      materiaId,
    );
    double porcentajeEvidencias = provider.calcularPorcentajeEvidencias(
      provider.usuario!.id,
      materiaId,
    );
    bool tieneRiesgo = provider.tieneRiesgoReprobacion(
      provider.usuario!.id,
      materiaId,
    );
    bool puedeExentar = provider.puedeExentar(provider.usuario!.id, materiaId);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildIndicador(
                'Asistencia',
                '${porcentajeAsistencia.toStringAsFixed(1)}%',
                porcentajeAsistencia >= 80 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildIndicador(
                'Evidencias',
                '${porcentajeEvidencias.toStringAsFixed(1)}%',
                porcentajeEvidencias >= 50 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (puedeExentar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Exento',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else if (tieneRiesgo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.warning, size: 16, color: Colors.red),
                SizedBox(width: 4),
                Text(
                  'Riesgo de Reprobación',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildIndicador(String titulo, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarUnirseAClase(CuadernoProvider provider) {
    final codigoController = TextEditingController();
    final parentContext = context; // Contexto del Scaffold
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Unirse a Clase',
          style: TextStyle(fontSize: isMobile ? 18 : 20),
        ),
        contentPadding: EdgeInsets.all(isMobile ? 16 : 24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresa el código de la clase proporcionado por tu profesor:',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              TextField(
                controller: codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código de clase',
                  hintText: 'Ej: ABC123',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codigoController.text.trim();
              if (code.isEmpty) return;
              Navigator.of(ctx).pop();
              final ok = await provider.unirseAMateriaPorCodigo(code);
              if (!mounted) return;
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Te has unido correctamente.'
                        : provider.lastError ?? 'No se pudo unir a la materia',
                  ),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }

  void _navegarADetalleMateria(String materiaId) {
    final provider = context.read<CuadernoProvider>();
    final materia = provider.materias.firstWhere((m) => m.id == materiaId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AlumnoEvidenciasScreen(materia: materia),
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
