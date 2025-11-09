import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cuaderno_provider.dart';
import '../models/materia.dart';
import '../widgets/materia_card.dart';
import '../widgets/crear_materia_dialog.dart';
import 'profesor/tomar_asistencia_screen.dart';
import 'profesor/detalle_materia_screen.dart';
import 'profesor/materia_search_delegate.dart';
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
      }
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
          appBar: AppBar(
            title: const Text('Cuaderno Profesor'),
            leading: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                showSearch(context: context, delegate: MateriaSearchDelegate());
              },
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    _cerrarSesion(provider);
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
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      provider.usuario?.nombre.substring(0, 1).toUpperCase() ??
                          'P',
                      style: const TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.bold,
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
              _buildMateriasTab(provider),
              _buildAsistenciasTab(provider),
              _buildEvidenciasTab(provider),
              _buildReportesTab(provider),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            selectedItemColor: const Color(0xFF1976D2),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.class_),
                label: 'Materias',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.how_to_reg),
                label: 'Asistencia',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Evidencias',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assessment),
                label: 'Reportes',
              ),
            ],
          ),
          floatingActionButton: _selectedIndex == 0
              ? FloatingActionButton(
                  onPressed: () => _mostrarCrearMateria(context, provider),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
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
              onAction: () => _mostrarCrearMateria(context, provider),
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
        onAction: () => _mostrarCrearMateria(context, provider),
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
    return const Center(child: Text('Módulo de Evidencias - En construcción'));
  }

  Widget _buildReportesTab(CuadernoProvider provider) {
    return const Center(child: Text('Módulo de Reportes - En construcción'));
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

  void _mostrarCrearMateria(BuildContext context, CuadernoProvider provider) {
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

  void _copiarCodigo(BuildContext context, Materia materia) {
    final code = materia.codigoAcceso ?? '';
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Código copiado')));
  }

  void _confirmarEliminar(
    BuildContext context,
    CuadernoProvider provider,
    Materia materia,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar materia'),
        content: Text(
          '¿Eliminar "${materia.nombre}"? Puedes restaurarla luego (borrado lógico).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await provider.eliminarMateria(materia.id, soft: true);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Materia eliminada'
                        : (provider.lastError ?? 'No se pudo eliminar'),
                  ),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _editarMateria(
    BuildContext context,
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
