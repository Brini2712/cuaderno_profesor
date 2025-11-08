import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';
import '../models/materia.dart';
import '../models/asistencia.dart';
import '../models/evidencia.dart';
import '../models/calificacion.dart';
import '../services/auth_service.dart';
import 'package:uuid/uuid.dart';
import '../utils/analytics.dart';

class CuadernoProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Usuario? _usuario;
  List<Materia> _materias = [];
  List<Usuario> _alumnos = [];
  List<RegistroAsistencia> _asistencias = [];
  List<Evidencia> _evidencias = [];
  List<Calificacion> _calificaciones = [];
  bool _isLoading = false;
  String? _lastError;

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
    required TipoUsuario tipo,
  }) async {
    _setLoading(true);
    try {
      final usuario = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        nombre: nombre,
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
      print('Error cargando datos: $e');
      _lastError = 'Error cargando datos';
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
    _reiniciarSubsColecciones();
  }

  Future<void> agregarMateria(Materia materia) async {
    if (_usuario == null) return;

    try {
      String id = _uuid.v4();
      Materia nuevaMateria = materia.copyWith(id: id, profesorId: _usuario!.id);

      await _firestore.collection('materias').doc(id).set(nuevaMateria.toMap());
      _materias.add(nuevaMateria);
      notifyListeners();
    } catch (e) {
      print('Error agregando materia: $e');
    }
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
      print('Error agregando alumno a materia: $e');
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

    List<String> materiasIds = _materias.map((m) => m.id).toList();

    QuerySnapshot snapshot = await _firestore
        .collection('asistencias')
        .where('materiaId', whereIn: materiasIds)
        .get();

    _asistencias = snapshot.docs
        .map(
          (doc) =>
              RegistroAsistencia.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> registrarAsistencia(RegistroAsistencia asistencia) async {
    try {
      String id = _uuid.v4();
      RegistroAsistencia nuevaAsistencia = asistencia.copyWith(id: id);

      await _firestore
          .collection('asistencias')
          .doc(id)
          .set(nuevaAsistencia.toMap());
      _asistencias.add(nuevaAsistencia);
      notifyListeners();
    } catch (e) {
      print('Error registrando asistencia: $e');
    }
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
  }

  Future<void> agregarEvidencia(Evidencia evidencia) async {
    try {
      String id = _uuid.v4();
      Evidencia nuevaEvidencia = evidencia.copyWith(id: id);

      await _firestore
          .collection('evidencias')
          .doc(id)
          .set(nuevaEvidencia.toMap());
      _evidencias.add(nuevaEvidencia);
      notifyListeners();
    } catch (e) {
      print('Error agregando evidencia: $e');
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
    List<Evidencia> evidenciasAlumno = _evidencias
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
    return (evidenciasAlumno.length / total) * 100;
  }

  bool tieneRiesgoReprobacion(String alumnoId, String materiaId) {
    double porcentajeAsistencia = calcularPorcentajeAsistencia(
      alumnoId,
      materiaId,
    );
    double porcentajeEvidencias = calcularPorcentajeEvidencias(
      alumnoId,
      materiaId,
    );
    return AnalyticsUtils.riesgoReprobacion(
      porcentajeAsistencia: porcentajeAsistencia,
      porcentajeEvidencias: porcentajeEvidencias,
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

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
