// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static User? _currentUser;
  static bool _isInitialized = false;

  // Inicializar el servicio de autenticación
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Escuchar cambios en el estado de autenticación
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      _saveUserSession(user);
    });

    // Restaurar sesión guardada si existe
    await _restoreUserSession();
    _isInitialized = true;
  }

  // Obtener usuario actual
  static User? get currentUser => _currentUser ?? _auth.currentUser;

  // Verificar si hay usuario logueado
  static bool get isLoggedIn => currentUser != null;

  // Obtener ID del usuario actual
  static String get currentUserId => currentUser?.uid ?? '';

  // Iniciar sesión con email y contraseña
  static Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = credential.user;
      await _saveUserSession(_currentUser);
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Error al iniciar sesión: ${e.message}');
      throw e;
    }
  }

  // Registrar nuevo usuario
  static Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = credential.user;
      await _saveUserSession(_currentUser);
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Error al registrarse: ${e.message}');
      throw e;
    }
  }

  // Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      await _clearUserSession();
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // Guardar sesión del usuario en SharedPreferences
  static Future<void> _saveUserSession(User? user) async {
    final prefs = await SharedPreferences.getInstance();

    if (user != null) {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'isEmailVerified': user.emailVerified,
      };
      await prefs.setString('user_session', json.encode(userData));
      await prefs.setBool('is_logged_in', true);
      print('Sesión guardada para: ${user.email}');
    } else {
      await _clearUserSession();
    }
  }

  // Restaurar sesión del usuario desde SharedPreferences
  static Future<void> _restoreUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (isLoggedIn) {
      final userSessionString = prefs.getString('user_session');
      if (userSessionString != null) {
        try {
          final userData =
              json.decode(userSessionString) as Map<String, dynamic>;
          print('Sesión restaurada para: ${userData['email']}');
          // Firebase Auth mantiene automáticamente la sesión
          _currentUser = _auth.currentUser;
        } catch (e) {
          print('Error al restaurar sesión: $e');
          await _clearUserSession();
        }
      }
    }
  }

  // Limpiar sesión guardada
  static Future<void> _clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    await prefs.setBool('is_logged_in', false);
    print('Sesión limpiada');
  }

  // Verificar si el email está verificado
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Enviar email de verificación
  static Future<void> sendEmailVerification() async {
    if (currentUser != null && !currentUser!.emailVerified) {
      await currentUser!.sendEmailVerification();
    }
  }

  // Restablecer contraseña
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
