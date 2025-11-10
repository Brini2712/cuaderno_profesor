import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';
import '../models/materia.dart';
import '../models/asistencia.dart';
import '../models/evidencia.dart';
import '../models/calificacion.dart';
import '../models/reporte_estadisticas.dart';
import '../services/auth_service.dart';
import 'package:uuid/uuid.dart';
import '../utils/analytics.dart';

class CuadernoProvider extends ChangeNotifier {
  // Servicios y estado base
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final Uuid _uuid = const Uuid();

  Usuario? _usuario;
  List<Materia> _materias = [];
  List<Usuario> _alumnos = [];
  List<RegistroAsistencia> _asistencias = [];
  List<Evidencia> _evidencias = [];
  List<Calificacion> _calificaciones = [];
  bool _isLoading = false;
  String? _lastError;
  bool _cargandoUsuarioInicial = false;
  StreamSubscription? _authSub;
  // Subscripciones en tiempo real
  StreamSubscription? _materiasSub;
  StreamSubscription? _asistenciasSub;
  StreamSubscription? _evidenciasSub;
  StreamSubscription? _calificacionesSub;

  // Getters
  Usuario? get usuario => _usuario;
  List<Materia> get materias => _materias;
  List<Usuario> get alumnos => _alumnos;
  List<RegistroAsistencia> get asistencias => _asistencias;
  List<Evidencia> get evidencias => _evidencias;
  List<Calificacion> get calificaciones => _calificaciones;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get cargandoUsuarioInicial => _cargandoUsuarioInicial;

  CuadernoProvider() {
    _iniciarListenerAuth();
  }

  void _iniciarListenerAuth() {
    _authSub?.cancel();
    _authSub = _authService.authStateChanges.listen((user) async {
      if (user == null) {
        _usuario = null;
        _materias.clear();
        _alumnos.clear();
        _asistencias.clear();
        _evidencias.clear();
        _calificaciones.clear();
        _cancelSubscriptions();
        notifyListeners();
      } else {
        // Cargar perfil Firestore
        _cargandoUsuarioInicial = true;
        notifyListeners();
        try {
          final doc = await _firestore
              .collection('usuarios')
              .doc(user.uid)
              .get();
          if (doc.exists) {
            _usuario = Usuario.fromMap(doc.data() as Map<String, dynamic>);
          } else {
            // Fallback mínimo si faltara documento
            _usuario = Usuario(
              id: user.uid,
              nombre: user.displayName ?? user.email ?? 'Usuario',
              email: user.email ?? '',
              tipo: TipoUsuario.profesor,
              fechaCreacion: DateTime.now(),
            );
          }
          unawaited(cargarDatos());
        } catch (e) {
          _lastError = 'No se pudo cargar perfil inicial';
        } finally {
          _cargandoUsuarioInicial = false;
          notifyListeners();
        }
      }
    });
  }

  // Autenticación
  Future<bool> iniciarSesion(String email, String password) async {
    _setLoading(true);
    try {
      final usuario = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      if (usuario != null) {
        _usuario = usuario;
        // Cargar datos en segundo plano para no bloquear la UI
        unawaited(cargarDatos());
        return true;
      }
      _lastError = _authService.lastError;
      return false;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    required TipoUsuario tipo,
  }) async {
    _setLoading(true);
    try {
      final usuario = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
        tipo: tipo,
      );
      if (usuario != null) {
        _usuario = usuario;
        // Cargar datos en segundo plano
        unawaited(cargarDatos());
        return true;
      }
      _lastError = _authService.lastError;
      return false;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cerrarSesion() async {
    await _authService.signOut();
    _usuario = null;
    _materias.clear();
    _alumnos.clear();
    _asistencias.clear();
    _evidencias.clear();
    _calificaciones.clear();
    _cancelSubscriptions();
    notifyListeners();
  }

  // Cargar datos del usuario
  Future<void> cargarDatos() async {
    if (_usuario == null) return;

    try {
      // Configurar listeners en tiempo real primero
      _configurarListeners();

      if (_usuario!.tipo == TipoUsuario.profesor) {
        // Primero materias (dependencia para el resto)
        await cargarMaterias();
        // Paralelizar cargas dependientes de materias
        await Future.wait([
          cargarAlumnos(),
          cargarAsistencias(),
          cargarEvidencias(),
          cargarCalificaciones(),
        ]);
      } else {
        await cargarMateriasAlumno();
        await Future.wait([
          cargarAsistencias(),
          cargarEvidencias(),
          cargarCalificaciones(),
        ]);
      }
      notifyListeners();
    } catch (e) {
      _lastError = 'Error cargando datos: $e';
    }
  }

  // Gestión de materias
  Future<void> cargarMaterias() async {
    if (_usuario == null) return;

    QuerySnapshot snapshot = await _firestore
        .collection('materias')
        .where('profesorId', isEqualTo: _usuario!.id)
        .get();

    _materias = snapshot.docs
        .map((doc) => Materia.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    _ordenarColecciones();
    _reiniciarSubsColecciones();
  }

  Future<void> cargarMateriasAlumno() async {
    if (_usuario == null) return;

    QuerySnapshot snapshot = await _firestore
        .collection('materias')
        .where('alumnosIds', arrayContains: _usuario!.id)
        .get();

    _materias = snapshot.docs
        .map((doc) => Materia.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    _ordenarColecciones();
    _reiniciarSubsColecciones();
  }

  Future<void> agregarMateria(Materia materia) async {
    if (_usuario == null) return;

    try {
      String id = _uuid.v4();
      Materia nuevaMateria = materia.copyWith(id: id, profesorId: _usuario!.id);

      await _firestore.collection('materias').doc(id).set(nuevaMateria.toMap());
      _materias.add(nuevaMateria);
      _ordenarColecciones();
      notifyListeners();
    } catch (e) {
      _lastError = 'Error agregando materia: $e';
    }
  }

  // Acciones Materias
  Future<bool> actualizarMateria(Materia m) async {
    try {
      await _firestore.collection('materias').doc(m.id).update(m.toMap());
      final idx = _materias.indexWhere((x) => x.id == m.id);
      if (idx != -1) {
        _materias[idx] = m;
        _ordenarColecciones();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _lastError = 'No se pudo actualizar la materia';
      return false;
    }
  }

  Future<bool> eliminarMateria(
    String materiaId, {
    bool soft = true,
    bool cascade = false,
  }) async {
    try {
      final docRef = _firestore.collection('materias').doc(materiaId);
      if (soft) {
        // Borrado lógico: marca como inactiva
        await docRef.update({'activo': false});
      } else {
        // Borrado definitivo: elimina documento y opcionalmente registros asociados
        if (cascade) {
          // Eliminar evidencias relacionadas
          final evidenciasSnap = await _firestore
              .collection('evidencias')
              .where('materiaId', isEqualTo: materiaId)
              .get();
          for (final d in evidenciasSnap.docs) {
            await d.reference.delete();
          }
          // Eliminar asistencias relacionadas
          final asistenciasSnap = await _firestore
              .collection('asistencias')
              .where('materiaId', isEqualTo: materiaId)
              .get();
          for (final d in asistenciasSnap.docs) {
            await d.reference.delete();
          }
          // Eliminar calificaciones relacionadas
          final califsSnap = await _firestore
              .collection('calificaciones')
              .where('materiaId', isEqualTo: materiaId)
              .get();
          for (final d in califsSnap.docs) {
            await d.reference.delete();
          }
        }
        await docRef.delete();
      }

      _materias.removeWhere((m) => m.id == materiaId);
      _ordenarColecciones();
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'No se pudo eliminar la materia: $e';
      return false;
    }
  }

  String? regenerarCodigoMateria(String materiaId) {
    try {
      final nuevo = _generarCodigo(6);
      _firestore.collection('materias').doc(materiaId).update({
        'codigoAcceso': nuevo,
      });
      final idx = _materias.indexWhere((m) => m.id == materiaId);
      if (idx != -1) {
        _materias[idx] = _materias[idx].copyWith(codigoAcceso: nuevo);
        _ordenarColecciones();
        notifyListeners();
      }
      return nuevo;
    } catch (_) {
      _lastError = 'No se pudo regenerar el código';
      return null;
    }
  }

  String _generarCodigo(int len) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final now = DateTime.now().millisecondsSinceEpoch;
    final buf = StringBuffer();
    for (int i = 0; i < len; i++) {
      buf.write(chars[(now + i) % chars.length]);
    }
    return buf.toString();
  }

  // Gestión de alumnos
  Future<void> cargarAlumnos() async {
    Set<String> alumnosIds = {};
    for (var materia in _materias) {
      alumnosIds.addAll(materia.alumnosIds);
    }

    if (alumnosIds.isNotEmpty) {
      QuerySnapshot snapshot = await _firestore
          .collection('usuarios')
          .where('id', whereIn: alumnosIds.toList())
          .get();

      _alumnos = snapshot.docs
          .map((doc) => Usuario.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      _ordenarColecciones();
    }
  }

  // Remover alumno de una materia con borrado en cascada de sus registros asociados
  Future<bool> removerAlumnoDeMateria(
    String materiaId,
    String alumnoId, {
    bool cascade = true,
  }) async {
    _lastError = null;
    try {
      final materiaRef = _firestore.collection('materias').doc(materiaId);
      await materiaRef.update({
        'alumnosIds': FieldValue.arrayRemove([alumnoId]),
      });

      if (cascade) {
        // Evidencias del alumno en esa materia
        final evidenciasSnap = await _firestore
            .collection('evidencias')
            .where('materiaId', isEqualTo: materiaId)
            .where('alumnoId', isEqualTo: alumnoId)
            .get();
        for (final d in evidenciasSnap.docs) {
          await d.reference.delete();
        }
        // Asistencias del alumno
        final asistenciasSnap = await _firestore
            .collection('asistencias')
            .where('materiaId', isEqualTo: materiaId)
            .where('alumnoId', isEqualTo: alumnoId)
            .get();
        for (final d in asistenciasSnap.docs) {
          await d.reference.delete();
        }
        // Calificaciones del alumno
        final califsSnap = await _firestore
            .collection('calificaciones')
            .where('materiaId', isEqualTo: materiaId)
            .where('alumnoId', isEqualTo: alumnoId)
            .get();
        for (final d in califsSnap.docs) {
          await d.reference.delete();
        }
      }

      // Actualizar cache local
      final idx = _materias.indexWhere((m) => m.id == materiaId);
      if (idx != -1) {
        final materia = _materias[idx];
        final nuevosAlumnos = List<String>.from(materia.alumnosIds)
          ..remove(alumnoId);
        _materias[idx] = materia.copyWith(alumnosIds: nuevosAlumnos);
      }
      _alumnos.removeWhere((a) => a.id == alumnoId);
      _ordenarColecciones();
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error removiendo alumno: $e';
      return false;
    }
  }

  Future<void> agregarAlumnoAMateria(
    String materiaId,
    String codigoAcceso,
  ) async {
    if (_usuario == null) return;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('materias')
          .where('id', isEqualTo: materiaId)
          .where('codigoAcceso', isEqualTo: codigoAcceso)
          .get();

      if (snapshot.docs.isNotEmpty) {
        DocumentReference materiaRef = snapshot.docs.first.reference;
        await materiaRef.update({
          'alumnosIds': FieldValue.arrayUnion([_usuario!.id]),
        });

        await cargarMateriasAlumno();
        notifyListeners();
      }
    } catch (e) {
      _lastError = 'Error agregando alumno a materia: $e';
    }
  }

  // Unirse a materia únicamente con el código
  Future<bool> unirseAMateriaPorCodigo(String codigo) async {
    if (_usuario == null) return false;
    _lastError = null;
    try {
      final snap = await _firestore
          .collection('materias')
          .where('codigoAcceso', isEqualTo: codigo.toUpperCase())
          .get();
      if (snap.docs.isEmpty) {
        _lastError = 'Código no encontrado';
        return false;
      }
      final doc = snap.docs.first;
      final data = doc.data();
      final alumnosIds = List<String>.from(data['alumnosIds'] ?? []);
      if (alumnosIds.contains(_usuario!.id)) {
        _lastError = 'Ya estás inscrito en esta materia';
        return false;
      }
      await doc.reference.update({
        'alumnosIds': FieldValue.arrayUnion([_usuario!.id]),
      });

      final materia = Materia.fromMap(data);

      // Notificar al alumno que se unió exitosamente
      await _crearNotificacion(
        usuarioId: _usuario!.id,
        titulo: '¡Bienvenido a ${materia.nombre}!',
        mensaje: 'Te has unido exitosamente a la materia',
        tipo: 'general',
        materiaId: materia.id,
      );

      // Notificar al profesor sobre el nuevo alumno
      if (materia.profesorId.isNotEmpty) {
        await _crearNotificacion(
          usuarioId: materia.profesorId,
          titulo: 'Nuevo alumno en ${materia.nombre}',
          mensaje: '${_usuario!.nombreCompleto} se ha unido a la clase',
          tipo: 'general',
          materiaId: materia.id,
        );
      }

      // Recargar materias del alumno
      await cargarMateriasAlumno();
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error al unirse a la materia';
      return false;
    }
  }

  // Gestión de asistencias
  Future<void> cargarAsistencias() async {
    if (_materias.isEmpty) return;
    final materiasIds = _materias.map((m) => m.id).toList();
    // Asumimos <=10 materias para whereIn (MVP)
    final snapshot = await _firestore
        .collection('asistencias')
        .where('materiaId', whereIn: materiasIds)
        .get();
    _asistencias = snapshot.docs
        .map((d) => RegistroAsistencia.fromMap(d.data()))
        .toList();
    _ordenarColecciones();
  }

  // Vaciar grupo de una materia (quitar todos los alumnos) con borrado en cascada de registros
  Future<bool> vaciarGrupoMateria(
    String materiaId, {
    bool cascade = true,
  }) async {
    _lastError = null;
    try {
      // Limpiar array de alumnos en materia
      await _firestore.collection('materias').doc(materiaId).update({
        'alumnosIds': <String>[],
      });

      if (cascade) {
        // Borrar todas las evidencias/asistencias/calificaciones de la materia
        final evidenciasSnap = await _firestore
            .collection('evidencias')
            .where('materiaId', isEqualTo: materiaId)
            .get();
        for (final d in evidenciasSnap.docs) {
          await d.reference.delete();
        }
        final asistenciasSnap = await _firestore
            .collection('asistencias')
            .where('materiaId', isEqualTo: materiaId)
            .get();
        for (final d in asistenciasSnap.docs) {
          await d.reference.delete();
        }
        final califsSnap = await _firestore
            .collection('calificaciones')
            .where('materiaId', isEqualTo: materiaId)
            .get();
        for (final d in califsSnap.docs) {
          await d.reference.delete();
        }
      }

      // Actualizar caché local
      final idx = _materias.indexWhere((m) => m.id == materiaId);
      if (idx != -1) {
        _materias[idx] = _materias[idx].copyWith(alumnosIds: []);
      }
      // No removemos usuarios globales del cache, solo de esta materia
      _ordenarColecciones();
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error vaciando grupo: $e';
      return false;
    }
  }

  Future<void> registrarAsistencia(RegistroAsistencia asistencia) async {
    try {
      final id = asistencia.id.isEmpty ? _uuid.v4() : asistencia.id;
      final nuevo = asistencia.copyWith(id: id);
      await _firestore.collection('asistencias').doc(id).set(nuevo.toMap());
      _asistencias.add(nuevo);
      notifyListeners();
    } catch (e) {
      _lastError = 'Error registrando asistencia';
    }
  }

  // Guardar varias asistencias de un día (reemplaza las previas de esa fecha)
  Future<void> guardarAsistenciasDia({
    required String materiaId,
    required DateTime fecha,
    required List<RegistroAsistencia> registros,
  }) async {
    // Upsert por día con fallback cuando falta índice compuesto (materiaId+fecha rango)
    try {
      final start = DateTime(fecha.year, fecha.month, fecha.day);
      final endMs =
          start.add(const Duration(days: 1)).millisecondsSinceEpoch - 1;
      final startMs = start.millisecondsSinceEpoch;
      final alumnosSet = registros.map((r) => r.alumnoId).toSet();

      QuerySnapshot<Map<String, dynamic>> prevSnap;
      try {
        prevSnap = await _firestore
            .collection('asistencias')
            .where('materiaId', isEqualTo: materiaId)
            .where('fecha', isGreaterThanOrEqualTo: startMs)
            .where('fecha', isLessThanOrEqualTo: endMs)
            .get();
      } on FirebaseException {
        // Fallback: cargar por materia y filtrar por rango en cliente
        prevSnap = await _firestore
            .collection('asistencias')
            .where('materiaId', isEqualTo: materiaId)
            .get();
      }

      final prevDocs = prevSnap.docs.where((d) {
        final data = d.data();
        final raw = data['fecha'];
        int ms;
        if (raw is int) {
          ms = raw;
        } else if (raw is Timestamp) {
          ms = raw.millisecondsSinceEpoch;
        } else if (raw is String) {
          ms = int.tryParse(raw) ?? 0;
        } else {
          ms = 0;
        }
        return ms >= startMs && ms <= endMs;
      }).toList();

      final batch = _firestore.batch();
      for (final doc in prevDocs) {
        final data = doc.data();
        final alumnoId = data['alumnoId'] as String?;
        if (alumnoId != null && alumnosSet.contains(alumnoId)) {
          batch.delete(doc.reference);
        }
      }

      final nuevosLoc = <RegistroAsistencia>[];
      final materia = _materias.firstWhere(
        (m) => m.id == materiaId,
        orElse: () => Materia(
          id: materiaId,
          nombre: 'Materia',
          descripcion: '',
          color: '#2196F3',
          profesorId: '',
          fechaCreacion: DateTime.now(),
        ),
      );

      for (final reg in registros) {
        final id = _uuid.v4();
        final nuevo = reg.copyWith(id: id);
        batch.set(_firestore.collection('asistencias').doc(id), nuevo.toMap());
        nuevosLoc.add(nuevo);

        // Notificar al alumno sobre su asistencia
        String estadoTexto;
        switch (reg.tipo) {
          case TipoAsistencia.asistencia:
            estadoTexto = 'Asistencia';
            break;
          case TipoAsistencia.justificacion:
            estadoTexto = 'Falta justificada';
            break;
          case TipoAsistencia.retardo:
            estadoTexto = 'Retardo';
            break;
          case TipoAsistencia.falta:
            estadoTexto = 'Falta';
            break;
        }

        _agregarNotificacionABatch(
          batch,
          usuarioId: reg.alumnoId,
          titulo: '$estadoTexto registrada',
          mensaje: 'Se registró tu asistencia en ${materia.nombre}',
          tipo: 'asistencia',
          materiaId: materiaId,
        );
      }

      await batch.commit();

      _asistencias.removeWhere(
        (a) =>
            a.materiaId == materiaId &&
            a.fecha.year == start.year &&
            a.fecha.month == start.month &&
            a.fecha.day == start.day &&
            alumnosSet.contains(a.alumnoId),
      );
      _asistencias.addAll(nuevosLoc);
      notifyListeners();
      _lastError = null;
    } on FirebaseException catch (e) {
      _lastError = e.message ?? 'Error guardando asistencias (Firebase)';
    } catch (e) {
      _lastError = 'Error guardando asistencias';
    }
  }

  // ============= NOTIFICACIONES =============
  /// Método helper para crear notificaciones
  Future<void> _crearNotificacion({
    required String usuarioId,
    required String titulo,
    required String mensaje,
    required String tipo,
    String? materiaId,
    String? evidenciaId,
  }) async {
    try {
      debugPrint('📝 Creando notificación:');
      debugPrint('   Para usuario: $usuarioId');
      debugPrint('   Título: $titulo');
      final notifId = _uuid.v4();
      await _firestore.collection('notificaciones').doc(notifId).set({
        'usuarioId': usuarioId,
        'titulo': titulo,
        'mensaje': mensaje,
        'tipo': tipo,
        'fecha': FieldValue.serverTimestamp(),
        'leida': false,
        if (materiaId != null) 'materiaId': materiaId,
        if (evidenciaId != null) 'evidenciaId': evidenciaId,
      });
      debugPrint('✅ Notificación guardada en Firestore con ID: $notifId');
    } catch (e) {
      debugPrint('❌ Error creando notificación: $e');
    }
  }

  /// Crear notificaciones en batch
  void _agregarNotificacionABatch(
    WriteBatch batch, {
    required String usuarioId,
    required String titulo,
    required String mensaje,
    required String tipo,
    String? materiaId,
    String? evidenciaId,
  }) {
    final notifId = _uuid.v4();
    batch.set(_firestore.collection('notificaciones').doc(notifId), {
      'usuarioId': usuarioId,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'fecha': FieldValue.serverTimestamp(),
      'leida': false,
      if (materiaId != null) 'materiaId': materiaId,
      if (evidenciaId != null) 'evidenciaId': evidenciaId,
    });
  }

  // Gestión de evidencias
  Future<void> cargarEvidencias() async {
    if (_materias.isEmpty) return;

    List<String> materiasIds = _materias.map((m) => m.id).toList();

    QuerySnapshot snapshot = await _firestore
        .collection('evidencias')
        .where('materiaId', whereIn: materiasIds)
        .get();

    _evidencias = snapshot.docs
        .map((doc) => Evidencia.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    _ordenarColecciones();
  }

  Future<void> agregarEvidencia(
    Evidencia evidencia, {
    Function(
      String usuarioId,
      String titulo,
      String mensaje,
      String materiaId,
      String evidenciaId,
    )?
    onNotificar,
  }) async {
    try {
      // Obtener la materia para acceder a sus alumnos
      final materia = _materias.firstWhere((m) => m.id == evidencia.materiaId);

      // Crear una evidencia para cada alumno de la materia
      final batch = _firestore.batch();
      final nuevasEvidencias = <Evidencia>[];

      for (final alumnoId in materia.alumnosIds) {
        String id = _uuid.v4();
        Evidencia nuevaEvidencia = evidencia.copyWith(
          id: id,
          alumnoId: alumnoId,
        );

        batch.set(
          _firestore.collection('evidencias').doc(id),
          nuevaEvidencia.toMap(),
        );
        nuevasEvidencias.add(nuevaEvidencia);

        // Crear notificación para el alumno
        _agregarNotificacionABatch(
          batch,
          usuarioId: alumnoId,
          titulo: 'Nueva evidencia: ${evidencia.titulo}',
          mensaje: 'Se asignó una nueva evidencia en ${materia.nombre}',
          tipo: 'evidencia',
          materiaId: materia.id,
          evidenciaId: id,
        );
      }

      await batch.commit();

      _evidencias.addAll(nuevasEvidencias);
      _ordenarColecciones();
      notifyListeners();
    } catch (e) {
      _lastError = 'Error agregando evidencia: $e';
      debugPrint('Error en agregarEvidencia: $e');
    }
  }

  Future<bool> actualizarEvidencia(
    Evidencia evidencia, {
    bool notificarCalificacion = false,
  }) async {
    try {
      // Primero obtenemos el estado anterior desde Firestore para asegurar consistencia
      final docSnapshot = await _firestore
          .collection('evidencias')
          .doc(evidencia.id)
          .get();

      final evidenciaAnterior = docSnapshot.exists
          ? Evidencia.fromMap(docSnapshot.data() as Map<String, dynamic>)
          : null;

      // Ahora actualizamos en Firestore
      await _firestore
          .collection('evidencias')
          .doc(evidencia.id)
          .update(evidencia.toMap());

      final idx = _evidencias.indexWhere((e) => e.id == evidencia.id);
      if (idx != -1) {
        _evidencias[idx] = evidencia;
        _ordenarColecciones();
        notifyListeners();

        final materia = _materias.firstWhere(
          (m) => m.id == evidencia.materiaId,
          orElse: () => Materia(
            id: '',
            nombre: 'Materia',
            descripcion: '',
            color: '#2196F3',
            profesorId: '',
            fechaCreacion: DateTime.now(),
          ),
        );

        // Notificar al profesor cuando alumno entrega
        debugPrint('🔍 VERIFICANDO ENTREGA:');
        debugPrint('   Usuario tipo: ${_usuario?.tipo}');
        debugPrint('   Estado nuevo: ${evidencia.estado}');
        debugPrint('   Estado anterior: ${evidenciaAnterior?.estado}');
        debugPrint(
          '   EvidenciaAnterior es null: ${evidenciaAnterior == null}',
        );

        if (evidenciaAnterior != null &&
            _usuario?.tipo == TipoUsuario.alumno &&
            evidencia.estado == EstadoEvidencia.entregado &&
            evidenciaAnterior.estado != EstadoEvidencia.entregado) {
          debugPrint(
            '🔔 ✅ CONDICIÓN CUMPLIDA - Intentando crear notificación de entrega',
          );
          debugPrint('   Profesor ID: ${materia.profesorId}');
          debugPrint('   Materia: ${materia.nombre}');
          debugPrint('   Evidencia: ${evidencia.titulo}');
          debugPrint('   Alumno: ${_usuario!.nombreCompleto}');
          if (materia.profesorId.isNotEmpty) {
            await _crearNotificacion(
              usuarioId: materia.profesorId,
              titulo: 'Nueva entrega recibida',
              mensaje:
                  '${_usuario!.nombreCompleto} entregó "${evidencia.titulo}" en ${materia.nombre}',
              tipo: 'evidencia',
              materiaId: evidencia.materiaId,
              evidenciaId: evidencia.id,
            );
            debugPrint('✅ Notificación de entrega creada exitosamente');
          } else {
            debugPrint('❌ profesorId está vacío!');
          }
        } else {
          debugPrint('❌ CONDICIÓN NO CUMPLIDA para notificar entrega');
        }

        // Si es una actualización de calificación y el usuario es profesor
        debugPrint('🔍 VERIFICANDO CALIFICACIÓN:');
        debugPrint('   notificarCalificacion: $notificarCalificacion');
        debugPrint('   Usuario tipo: ${_usuario?.tipo}');
        debugPrint('   Calificación nueva: ${evidencia.calificacionNumerica}');
        debugPrint(
          '   Calificación anterior: ${evidenciaAnterior?.calificacionNumerica}',
        );

        if (evidenciaAnterior != null &&
            notificarCalificacion &&
            _usuario?.tipo == TipoUsuario.profesor &&
            evidencia.calificacionNumerica != null &&
            evidenciaAnterior.calificacionNumerica !=
                evidencia.calificacionNumerica) {
          debugPrint(
            '📊 ✅ CONDICIÓN CUMPLIDA - Creando notificación de calificación',
          );
          debugPrint('   Alumno ID: ${evidencia.alumnoId}');
          debugPrint(
            '   Calificación: ${evidencia.calificacionNumerica}/${evidencia.puntosTotales}',
          );
          // Crear notificación de calificación para el alumno
          await _crearNotificacion(
            usuarioId: evidencia.alumnoId,
            titulo: 'Evidencia calificada',
            mensaje:
                '${evidencia.titulo} en ${materia.nombre} - Calificación: ${evidencia.calificacionNumerica}/${evidencia.puntosTotales}',
            tipo: 'calificacion',
            materiaId: evidencia.materiaId,
            evidenciaId: evidencia.id,
          );
          debugPrint('✅ Notificación de calificación enviada');
        } else {
          debugPrint('❌ CONDICIÓN NO CUMPLIDA para notificar calificación');
        }
      }
      return true;
    } catch (e) {
      _lastError = 'Error actualizando evidencia';
      return false;
    }
  }

  Future<bool> eliminarEvidencia(String evidenciaId) async {
    try {
      // Obtener la evidencia antes de eliminarla para notificar
      final evidencia = _evidencias.firstWhere(
        (e) => e.id == evidenciaId,
        orElse: () => Evidencia(
          id: '',
          titulo: '',
          descripcion: '',
          materiaId: '',
          alumnoId: '',
          tipo: TipoEvidencia.portafolio,
          fechaEntrega: DateTime.now(),
          fechaRegistro: DateTime.now(),
          profesorId: '',
          estado: EstadoEvidencia.asignado,
        ),
      );

      if (evidencia.id.isNotEmpty) {
        final materia = _materias.firstWhere(
          (m) => m.id == evidencia.materiaId,
          orElse: () => Materia(
            id: '',
            nombre: 'Materia',
            descripcion: '',
            color: '#2196F3',
            profesorId: '',
            fechaCreacion: DateTime.now(),
          ),
        );

        // Notificar al alumno
        await _crearNotificacion(
          usuarioId: evidencia.alumnoId,
          titulo: 'Evidencia eliminada',
          mensaje:
              'La evidencia "${evidencia.titulo}" fue eliminada de ${materia.nombre}',
          tipo: 'evidencia',
          materiaId: evidencia.materiaId,
        );
      }

      await _firestore.collection('evidencias').doc(evidenciaId).delete();
      _evidencias.removeWhere((e) => e.id == evidenciaId);
      _ordenarColecciones();
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error eliminando evidencia';
      return false;
    }
  }

  // Cambiar estado de evidencia (alumno marca como entregado)
  Future<bool> cambiarEstadoEvidencia(
    String evidenciaId,
    EstadoEvidencia nuevoEstado,
  ) async {
    try {
      await _firestore.collection('evidencias').doc(evidenciaId).update({
        'estado': nuevoEstado.toString().split('.').last,
      });
      final idx = _evidencias.indexWhere((e) => e.id == evidenciaId);
      if (idx != -1) {
        final evidencia = _evidencias[idx];
        _evidencias[idx] = _evidencias[idx].copyWith(estado: nuevoEstado);
        _ordenarColecciones();
        notifyListeners();

        // Notificar al profesor cuando alumno entrega
        if (nuevoEstado == EstadoEvidencia.entregado &&
            _usuario?.tipo == TipoUsuario.alumno) {
          final materia = _materias.firstWhere(
            (m) => m.id == evidencia.materiaId,
            orElse: () => Materia(
              id: '',
              nombre: 'Materia',
              descripcion: '',
              color: '#2196F3',
              profesorId: '',
              fechaCreacion: DateTime.now(),
            ),
          );

          if (materia.profesorId.isNotEmpty) {
            await _crearNotificacion(
              usuarioId: materia.profesorId,
              titulo: 'Nueva entrega recibida',
              mensaje:
                  '${_usuario!.nombreCompleto} entregó "${evidencia.titulo}" en ${materia.nombre}',
              tipo: 'evidencia',
              materiaId: evidencia.materiaId,
              evidenciaId: evidencia.id,
            );
          }
        }
      }
      return true;
    } catch (e) {
      _lastError = 'Error cambiando estado';
      return false;
    }
  }

  // Gestión de calificaciones
  Future<void> cargarCalificaciones() async {
    if (_materias.isEmpty) return;

    List<String> materiasIds = _materias.map((m) => m.id).toList();

    QuerySnapshot snapshot = await _firestore
        .collection('calificaciones')
        .where('materiaId', whereIn: materiasIds)
        .get();

    _calificaciones = snapshot.docs
        .map((doc) => Calificacion.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Análisis y estadísticas
  double calcularPorcentajeAsistencia(String alumnoId, String materiaId) {
    List<RegistroAsistencia> asistenciasAlumno = _asistencias
        .where((a) => a.alumnoId == alumnoId && a.materiaId == materiaId)
        .toList();

    if (asistenciasAlumno.isEmpty) return 0.0;
    return AnalyticsUtils.porcentajeAsistencia(asistenciasAlumno);
  }

  double calcularPorcentajeEvidencias(String alumnoId, String materiaId) {
    final evidenciasAlumno = _evidencias
        .where((e) => e.alumnoId == alumnoId && e.materiaId == materiaId)
        .toList();
    if (evidenciasAlumno.isEmpty) return 0.0;
    final materia = _materias.firstWhere(
      (m) => m.id == materiaId,
      orElse: () => Materia(
        id: 'tmp',
        nombre: 'tmp',
        descripcion: '',
        color: '#2196F3',
        profesorId: _usuario?.id ?? '',
        fechaCreacion: DateTime.now(),
      ),
    );
    final total = materia.totalEvidenciasEsperadas == 0
        ? 1
        : materia.totalEvidenciasEsperadas;
    final entregadas = evidenciasAlumno
        .where((e) => e.estado != EstadoEvidencia.asignado)
        .length;
    return AnalyticsUtils.porcentajeEvidencias(
      entregadas: entregadas,
      esperadas: total,
    );
  }

  bool puedeExentar(String alumnoId, String materiaId) {
    double porcentajeAsistencia = calcularPorcentajeAsistencia(
      alumnoId,
      materiaId,
    );
    double porcentajeEvidencias = calcularPorcentajeEvidencias(
      alumnoId,
      materiaId,
    );
    return AnalyticsUtils.puedeExentar(
      porcentajeAsistencia: porcentajeAsistencia,
      porcentajeEvidencias: porcentajeEvidencias,
    );
  }

  bool tieneRiesgoReprobacion(String alumnoId, String materiaId) {
    final porcentajeAsistencia = calcularPorcentajeAsistencia(
      alumnoId,
      materiaId,
    );
    final porcentajeEvidencias = calcularPorcentajeEvidencias(
      alumnoId,
      materiaId,
    );
    return AnalyticsUtils.riesgoReprobacion(
      porcentajeAsistencia: porcentajeAsistencia,
      porcentajeEvidencias: porcentajeEvidencias,
    );
  }

  // ============= REPORTES WEB =============
  /// Genera un reporte de estadísticas para una materia en un rango de fechas
  ReporteEstadisticas generarReporte({
    required String materiaId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) {
    final materia = _materias.firstWhere(
      (m) => m.id == materiaId,
      orElse: () => Materia(
        id: 'tmp',
        nombre: 'tmp',
        descripcion: '',
        color: '#2196F3',
        profesorId: _usuario?.id ?? '',
        fechaCreacion: DateTime.now(),
      ),
    );

    final estadisticas = <EstadisticaAlumno>[];

    for (final alumno in _alumnos.where(
      (a) => materia.alumnosIds.contains(a.id),
    )) {
      final asistenciasRango = _asistencias
          .where(
            (a) =>
                a.alumnoId == alumno.id &&
                a.materiaId == materiaId &&
                a.fecha.isAfter(
                  fechaInicio.subtract(const Duration(days: 1)),
                ) &&
                a.fecha.isBefore(fechaFin.add(const Duration(days: 1))),
          )
          .toList();

      final evidenciasRango = _evidencias
          .where(
            (e) =>
                e.alumnoId == alumno.id &&
                e.materiaId == materiaId &&
                e.fechaEntrega.isAfter(
                  fechaInicio.subtract(const Duration(days: 1)),
                ) &&
                e.fechaEntrega.isBefore(fechaFin.add(const Duration(days: 1))),
          )
          .toList();

      final porcentajeAsist = asistenciasRango.isEmpty
          ? 0.0
          : AnalyticsUtils.porcentajeAsistencia(asistenciasRango);

      final entregadas = evidenciasRango
          .where((e) => e.estado != EstadoEvidencia.asignado)
          .length;
      final total = evidenciasRango.isEmpty ? 1 : evidenciasRango.length;
      final porcentajeEvid = AnalyticsUtils.porcentajeEvidencias(
        entregadas: entregadas,
        esperadas: total,
      );

      final califs = _calificaciones
          .where((c) => c.alumnoId == alumno.id && c.materiaId == materiaId)
          .toList();
      int evaluacionesReprobadas = 0;
      if (califs.isNotEmpty) {
        final calif = califs.first;
        if (calif.examen != null && calif.examen! < 6) evaluacionesReprobadas++;
        if (calif.portafolioEvidencias != null &&
            calif.portafolioEvidencias! < 6) {
          evaluacionesReprobadas++;
        }
        if (calif.actividadComplementaria != null &&
            calif.actividadComplementaria! < 6) {
          evaluacionesReprobadas++;
        }
      }

      final tieneRiesgo = AnalyticsUtils.riesgoReprobacion(
        porcentajeAsistencia: porcentajeAsist,
        porcentajeEvidencias: porcentajeEvid,
      );

      final puedeExent = AnalyticsUtils.puedeExentar(
        porcentajeAsistencia: porcentajeAsist,
        porcentajeEvidencias: porcentajeEvid,
      );

      final requiereOrd = evaluacionesReprobadas >= 2;

      estadisticas.add(
        EstadisticaAlumno(
          alumnoId: alumno.id,
          alumnoNombre: alumno.nombreCompleto,
          porcentajeAsistencia: porcentajeAsist,
          porcentajeEvidencias: porcentajeEvid,
          evaluacionesReprobadas: evaluacionesReprobadas,
          tieneRiesgo: tieneRiesgo,
          puedeExentar: puedeExent,
          requiereOrdinaria: requiereOrd,
        ),
      );
    }

    return ReporteEstadisticas(
      materiaId: materiaId,
      materiaNombre: materia.nombre,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estadisticasAlumnos: estadisticas,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Reset password wrapper
  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _lastError = 'No se pudo enviar el correo de restablecimiento';
      return false;
    }
  }

  void _configurarListeners() {
    _cancelSubscriptions();
    if (_usuario == null) return;
    if (_usuario!.tipo == TipoUsuario.profesor) {
      _materiasSub = _firestore
          .collection('materias')
          .where('profesorId', isEqualTo: _usuario!.id)
          .snapshots()
          .listen((snapshot) {
            _materias = snapshot.docs
                .map((d) => Materia.fromMap(d.data()))
                .toList();
            _ordenarColecciones();
            _reiniciarSubsColecciones();
            notifyListeners();
          });
    } else {
      _materiasSub = _firestore
          .collection('materias')
          .where('alumnosIds', arrayContains: _usuario!.id)
          .snapshots()
          .listen((snapshot) {
            _materias = snapshot.docs
                .map((d) => Materia.fromMap(d.data()))
                .toList();
            _ordenarColecciones();
            _reiniciarSubsColecciones();
            notifyListeners();
          });
    }
  }

  void _reiniciarSubsColecciones() {
    _asistenciasSub?.cancel();
    _evidenciasSub?.cancel();
    _calificacionesSub?.cancel();
    if (_materias.isEmpty) return;
    final materiasIds = _materias.map((m) => m.id).toList();
    // Si supera límite de whereIn (10) se podría fragmentar; se asume <=10 para MVP
    if (materiasIds.length <= 10) {
      _asistenciasSub = _firestore
          .collection('asistencias')
          .where('materiaId', whereIn: materiasIds)
          .snapshots()
          .listen((snapshot) {
            _asistencias = snapshot.docs
                .map((d) => RegistroAsistencia.fromMap(d.data()))
                .toList();
            _ordenarColecciones();
            notifyListeners();
          });
      _evidenciasSub = _firestore
          .collection('evidencias')
          .where('materiaId', whereIn: materiasIds)
          .snapshots()
          .listen((snapshot) {
            _evidencias = snapshot.docs
                .map((d) => Evidencia.fromMap(d.data()))
                .toList();
            _ordenarColecciones();
            notifyListeners();
          });
      _calificacionesSub = _firestore
          .collection('calificaciones')
          .where('materiaId', whereIn: materiasIds)
          .snapshots()
          .listen((snapshot) {
            _calificaciones = snapshot.docs
                .map((d) => Calificacion.fromMap(d.data()))
                .toList();
            _ordenarColecciones();
            notifyListeners();
          });
    }
  }

  void _cancelSubscriptions() {
    _materiasSub?.cancel();
    _asistenciasSub?.cancel();
    _evidenciasSub?.cancel();
    _calificacionesSub?.cancel();
  }

  // Actualizar perfil de usuario
  Future<void> actualizarPerfil({String? nombre, String? fotoUrl}) async {
    if (_usuario == null) return;

    try {
      final Map<String, dynamic> updates = {};
      if (nombre != null && nombre.isNotEmpty) {
        updates['nombre'] = nombre;
      }
      if (fotoUrl != null) {
        updates['fotoUrl'] = fotoUrl;
      }

      if (updates.isEmpty) return;

      await _firestore.collection('usuarios').doc(_usuario!.id).update(updates);

      // Actualizar el objeto local
      _usuario = _usuario!.copyWith(
        nombre: nombre ?? _usuario!.nombre,
        fotoUrl: fotoUrl ?? _usuario!.fotoUrl,
      );
      notifyListeners();
    } catch (e) {
      _lastError = 'Error actualizando perfil: $e';
      rethrow;
    }
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  // ================= ORDENAMIENTO =================
  String _normalize(String input) {
    final lower = input.toLowerCase();
    return lower
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n');
  }

  /// Comparación alfanumérica: ordena números correctamente
  /// Ejemplo: "Practica 2" < "Practica 10"
  int _compareAlphanumeric(String a, String b) {
    final regex = RegExp(r'(\d+|\D+)');
    final partsA = regex.allMatches(a).map((m) => m.group(0)!).toList();
    final partsB = regex.allMatches(b).map((m) => m.group(0)!).toList();

    for (int i = 0; i < partsA.length && i < partsB.length; i++) {
      final partA = partsA[i];
      final partB = partsB[i];

      final numA = int.tryParse(partA);
      final numB = int.tryParse(partB);

      if (numA != null && numB != null) {
        // Ambos son números: comparar numéricamente
        final cmp = numA.compareTo(numB);
        if (cmp != 0) return cmp;
      } else {
        // Al menos uno es texto: comparar alfabéticamente
        final cmp = _normalize(partA).compareTo(_normalize(partB));
        if (cmp != 0) return cmp;
      }
    }

    return partsA.length.compareTo(partsB.length);
  }

  void _ordenarColecciones() {
    _materias.sort(
      (a, b) => _normalize(a.nombre).compareTo(_normalize(b.nombre)),
    );
    _alumnos.sort((a, b) {
      int cmpApPat = _normalize(
        a.apellidoPaterno ?? '',
      ).compareTo(_normalize(b.apellidoPaterno ?? ''));
      if (cmpApPat != 0) return cmpApPat;
      int cmpApMat = _normalize(
        a.apellidoMaterno ?? '',
      ).compareTo(_normalize(b.apellidoMaterno ?? ''));
      if (cmpApMat != 0) return cmpApMat;
      return _normalize(a.nombre).compareTo(_normalize(b.nombre));
    });
    _evidencias.sort((a, b) {
      // Ordenamiento alfanumérico por título
      final byTitulo = _compareAlphanumeric(a.titulo, b.titulo);
      if (byTitulo != 0) return byTitulo;
      return a.fechaEntrega.compareTo(b.fechaEntrega);
    });
  }
}
