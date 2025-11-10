import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    // En web, asegura persistencia local para mantener sesión tras refresh
    if (kIsWeb) {
      _auth.setPersistence(Persistence.LOCAL);
    }
  }

  String? lastError;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registrar usuario
  Future<Usuario?> registerWithEmailPassword({
    required String email,
    required String password,
    required String nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
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
          apellidoPaterno: apellidoPaterno,
          apellidoMaterno: apellidoMaterno,
          email: email,
          tipo: tipo,
          fechaCreacion: DateTime.now(),
        );

        await _firestore
            .collection('usuarios')
            .doc(user.uid)
            .set(nuevoUsuario.toMap());
        return nuevoUsuario;
      }
      return null;
    } catch (e) {
      if (e is FirebaseAuthException) {
        lastError = _traducirAuthError(e);
      } else {
        lastError = 'Error desconocido en registro';
      }
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
        // Intentar obtener el perfil; si Firestore está offline, continuar con Auth
        try {
          DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
              .collection('usuarios')
              .doc(user.uid)
              .get(const GetOptions(source: Source.serverAndCache));
          if (doc.exists && doc.data() != null) {
            return Usuario.fromMap(doc.data()!);
          }
        } catch (e) {
          // Registrar pero no bloquear el inicio de sesión
          // En modo offline, devolvemos un Usuario mínimo basado en Auth
          return Usuario(
            id: user.uid,
            nombre: user.displayName ?? user.email ?? 'Usuario',
            email: user.email ?? '',
            tipo: TipoUsuario
                .profesor, // Asumir profesor por defecto; se corrige luego
            fechaCreacion: DateTime.now(),
          );
        }
      }
      return null;
    } catch (e) {
      if (e is FirebaseAuthException) {
        lastError = _traducirAuthError(e);
      } else {
        lastError = 'Error desconocido en inicio de sesión';
      }
      return null;
    }
  }

  // Obtener datos del usuario actual
  Future<Usuario?> getCurrentUserData() async {
    User? user = currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();
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
      lastError = 'No se pudo cerrar sesión';
    }
  }

  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (e is FirebaseAuthException) {
        lastError = _traducirAuthError(e);
      } else {
        lastError = 'No se pudo enviar el correo de restablecimiento';
      }
    }
  }

  String _traducirAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo tiene un formato inválido.';
      case 'user-disabled':
        return 'El usuario está deshabilitado.';
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Ese correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Problema de red. Verifica tu conexión.';
      default:
        return 'Error de autenticación (${e.code}).';
    }
  }
}
