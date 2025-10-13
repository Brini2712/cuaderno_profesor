import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';
import '../models/materia.dart';
import '../models/asistencia.dart';
import '../models/evidencia.dart';
import '../models/calificacion.dart';
import '../services/auth_service.dart';
import 'package:uuid/uuid.dart';

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

  // Getters
  Usuario? get usuario => _usuario;
  List<Materia> get materias => _materias;
  List<Usuario> get alumnos => _alumnos;
  List<RegistroAsistencia> get asistencias => _asistencias;
  List<Evidencia> get evidencias => _evidencias;
  List<Calificacion> get calificaciones => _calificaciones;
  bool get isLoading => _isLoading;

  // Autenticación
  Future<bool> iniciarSesion(String email, String password) async {
    _setLoading(true);
    try {
      _usuario = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      if (_usuario != null) {
        await cargarDatos();
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
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
      _usuario = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        nombre: nombre,
        tipo: tipo,
      );
      if (_usuario != null) {
        await cargarDatos();
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
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
    notifyListeners();
  }

  // Cargar datos del usuario
  Future<void> cargarDatos() async {
    if (_usuario == null) return;

    try {
      if (_usuario!.tipo == TipoUsuario.profesor) {
        await cargarMaterias();
        await cargarAlumnos();
        await cargarAsistencias();
        await cargarEvidencias();
        await cargarCalificaciones();
      } else {
        await cargarMateriasAlumno();
      }
      notifyListeners();
    } catch (e) {
      print('Error cargando datos: $e');
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
  }

  Future<void> agregarMateria(Materia materia) async {
    if (_usuario == null) return;
    
    try {
      String id = _uuid.v4();
      Materia nuevaMateria = materia.copyWith(
        id: id,
        profesorId: _usuario!.id,
      );
      
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

  Future<void> agregarAlumnoAMateria(String materiaId, String codigoAcceso) async {
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
          'alumnosIds': FieldValue.arrayUnion([_usuario!.id])
        });
        
        await cargarMateriasAlumno();
        notifyListeners();
      }
    } catch (e) {
      print('Error agregando alumno a materia: $e');
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
        .map((doc) => RegistroAsistencia.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> registrarAsistencia(RegistroAsistencia asistencia) async {
    try {
      String id = _uuid.v4();
      RegistroAsistencia nuevaAsistencia = asistencia.copyWith(id: id);
      
      await _firestore.collection('asistencias').doc(id).set(nuevaAsistencia.toMap());
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
      
      await _firestore.collection('evidencias').doc(id).set(nuevaEvidencia.toMap());
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

    int asistencias = asistenciasAlumno.where((a) => 
        a.tipo == TipoAsistencia.asistencia || 
        a.tipo == TipoAsistencia.justificacion).length;
    
    int retardos = asistenciasAlumno.where((a) => 
        a.tipo == TipoAsistencia.retardo).length;
    
    // 3 retardos = 1 falta
    int faltasEquivalentes = (retardos / 3).floor();
    int asistenciasEfectivas = asistencias - faltasEquivalentes;

    return (asistenciasEfectivas / asistenciasAlumno.length) * 100;
  }

  double calcularPorcentajeEvidencias(String alumnoId, String materiaId) {
    List<Evidencia> evidenciasAlumno = _evidencias
        .where((e) => e.alumnoId == alumnoId && e.materiaId == materiaId)
        .toList();

    if (evidenciasAlumno.isEmpty) return 0.0;

    // Total de evidencias esperadas (esto debería configurarse por materia)
    int totalEvidenciasEsperadas = 10; // Por ejemplo
    
    return (evidenciasAlumno.length / totalEvidenciasEsperadas) * 100;
  }

  bool tieneRiesgoReprobacion(String alumnoId, String materiaId) {
    double porcentajeAsistencia = calcularPorcentajeAsistencia(alumnoId, materiaId);
    double porcentajeEvidencias = calcularPorcentajeEvidencias(alumnoId, materiaId);
    
    return porcentajeAsistencia < 80 || porcentajeEvidencias < 50;
  }

  bool puedeExentar(String alumnoId, String materiaId) {
    double porcentajeAsistencia = calcularPorcentajeAsistencia(alumnoId, materiaId);
    double porcentajeEvidencias = calcularPorcentajeEvidencias(alumnoId, materiaId);
    
    return porcentajeAsistencia >= 95 && porcentajeEvidencias >= 90;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
