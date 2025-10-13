import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registrar usuario
  Future<Usuario?> registerWithEmailPassword({
    required String email,
    required String password,
    required String nombre,
    required TipoUsuario tipo,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user != null) {
        // Crear documento de usuario en Firestore
        Usuario nuevoUsuario = Usuario(
          id: user.uid,
          nombre: nombre,
          email: email,
          tipo: tipo,
          fechaCreacion: DateTime.now(),
        );
        
        await _firestore.collection('usuarios').doc(user.uid).set(nuevoUsuario.toMap());
        return nuevoUsuario;
      }
      return null;
    } catch (e) {
      print('Error en registro: $e');
      return null;
    }
  }

  // Iniciar sesión
  Future<Usuario?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('usuarios').doc(user.uid).get();
        if (doc.exists) {
          return Usuario.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print('Error en login: $e');
      return null;
    }
  }

  // Obtener datos del usuario actual
  Future<Usuario?> getCurrentUserData() async {
    User? user = currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        return Usuario.fromMap(doc.data() as Map<String, dynamic>);
      }
    }
    return null;
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error al restablecer contraseña: $e');
    }
  }
}