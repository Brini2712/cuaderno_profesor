import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notificacion.dart';

class NotificacionesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Notificacion> _notificaciones = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _notificacionesSub;

  List<Notificacion> get notificaciones => _notificaciones;
  bool get isLoading => _isLoading;

  int get notificacionesNoLeidas =>
      _notificaciones.where((n) => !n.leida).length;

  // Cargar notificaciones del usuario
  Future<void> cargarNotificaciones(String usuarioId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('notificaciones')
          .where('usuarioId', isEqualTo: usuarioId)
          .limit(100)
          .get();

      _notificaciones = snapshot.docs
          .map((doc) => Notificacion.fromFirestore(doc))
          .toList();
      // Ordenar en el cliente por fecha descendente
      _notificaciones.sort((a, b) => b.fecha.compareTo(a.fecha));
      // Limitar a 50 más recientes
      if (_notificaciones.length > 50) {
        _notificaciones = _notificaciones.sublist(0, 50);
      }
    } catch (e) {
      debugPrint('Error al cargar notificaciones: $e');
      _notificaciones = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Escuchar notificaciones en tiempo real
  void escucharNotificaciones(String usuarioId) {
    _notificacionesSub?.cancel();
    _notificacionesSub = _firestore
        .collection('notificaciones')
        .where('usuarioId', isEqualTo: usuarioId)
        .limit(100)
        .snapshots()
        .listen(
          (snapshot) {
            _notificaciones = snapshot.docs
                .map((doc) => Notificacion.fromFirestore(doc))
                .toList();
            // Ordenar en el cliente por fecha descendente
            _notificaciones.sort((a, b) => b.fecha.compareTo(a.fecha));
            // Limitar a 50 más recientes
            if (_notificaciones.length > 50) {
              _notificaciones = _notificaciones.sublist(0, 50);
            }
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error escuchando notificaciones: $error');
          },
        );
  }

  @override
  void dispose() {
    _notificacionesSub?.cancel();
    super.dispose();
  }

  // Marcar notificación como leída
  Future<void> marcarComoLeida(String notificacionId) async {
    try {
      await _firestore.collection('notificaciones').doc(notificacionId).update({
        'leida': true,
      });

      final index = _notificaciones.indexWhere((n) => n.id == notificacionId);
      if (index != -1) {
        _notificaciones[index] = _notificaciones[index].copyWith(leida: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al marcar notificación como leída: $e');
    }
  }

  // Marcar todas como leídas
  Future<void> marcarTodasComoLeidas(String usuarioId) async {
    try {
      final batch = _firestore.batch();
      final noLeidas = _notificaciones.where((n) => !n.leida);

      for (var notif in noLeidas) {
        batch.update(_firestore.collection('notificaciones').doc(notif.id), {
          'leida': true,
        });
      }

      await batch.commit();

      _notificaciones = _notificaciones
          .map((n) => n.copyWith(leida: true))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al marcar todas como leídas: $e');
    }
  }

  // Eliminar notificación
  Future<void> eliminarNotificacion(String notificacionId) async {
    try {
      await _firestore
          .collection('notificaciones')
          .doc(notificacionId)
          .delete();

      _notificaciones.removeWhere((n) => n.id == notificacionId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al eliminar notificación: $e');
    }
  }

  // Crear nueva notificación
  Future<void> crearNotificacion({
    required String usuarioId,
    required String titulo,
    required String mensaje,
    required String tipo,
    String? materiaId,
    String? evidenciaId,
  }) async {
    try {
      await _firestore.collection('notificaciones').add({
        'usuarioId': usuarioId,
        'titulo': titulo,
        'mensaje': mensaje,
        'tipo': tipo,
        'fecha': FieldValue.serverTimestamp(),
        'leida': false,
        if (materiaId != null) 'materiaId': materiaId,
        if (evidenciaId != null) 'evidenciaId': evidenciaId,
      });
    } catch (e) {
      debugPrint('Error al crear notificación: $e');
    }
  }
}
