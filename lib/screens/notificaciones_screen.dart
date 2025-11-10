import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notificaciones_provider.dart';
import '../providers/cuaderno_provider.dart';
import '../models/notificacion.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  @override
  void initState() {
    super.initState();
    // Configurar idioma español para timeago
    timeago.setLocaleMessages('es', timeago.EsMessages());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cuadernoProvider = context.read<CuadernoProvider>();
      final notifProvider = context.read<NotificacionesProvider>();

      if (cuadernoProvider.usuario != null) {
        notifProvider.cargarNotificaciones(cuadernoProvider.usuario!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cuadernoProvider = context.watch<CuadernoProvider>();
    final notifProvider = context.watch<NotificacionesProvider>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (notifProvider.notificacionesNoLeidas > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 18),
              label: Text(
                'Marcar todas',
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
              onPressed: () {
                if (cuadernoProvider.usuario != null) {
                  notifProvider.marcarTodasComoLeidas(
                    cuadernoProvider.usuario!.id,
                  );
                }
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifProvider.notificaciones.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                if (cuadernoProvider.usuario != null) {
                  await notifProvider.cargarNotificaciones(
                    cuadernoProvider.usuario!.id,
                  );
                }
              },
              child: ListView.builder(
                padding: EdgeInsets.all(isMobile ? 8 : 16),
                itemCount: notifProvider.notificaciones.length,
                itemBuilder: (context, index) {
                  final notif = notifProvider.notificaciones[index];
                  return _buildNotificacionCard(notif, notifProvider, isMobile);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí aparecerán tus notificaciones',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificacionCard(
    Notificacion notif,
    NotificacionesProvider provider,
    bool isMobile,
  ) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: isMobile ? 0 : 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.eliminarNotificacion(notif.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notificación eliminada')));
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: isMobile ? 0 : 4),
        elevation: notif.leida ? 0 : 2,
        color: notif.leida ? Colors.grey[50] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notif.leida
                ? Colors.grey[200]!
                : notif.color.withOpacity(0.3),
            width: notif.leida ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            if (!notif.leida) {
              provider.marcarComoLeida(notif.id);
            }
            // Aquí se puede navegar a la pantalla relacionada
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notif.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notif.icono,
                    color: notif.color,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.titulo,
                              style: TextStyle(
                                fontWeight: notif.leida
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ),
                          if (!notif.leida)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: notif.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.mensaje,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: isMobile ? 13 : 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeago.format(notif.fecha, locale: 'es'),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
