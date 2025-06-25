import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Crear usuario con email y contraseña
  static Future<Map<String, dynamic>> createUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Verificar si el username ya existe
      final usernameExists = await _checkUsernameExists(username);
      if (usernameExists) {
        return {
          'success': false,
          'message': 'El nombre de usuario ya está en uso',
        };
      }

      // Crear usuario en Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        try {
          // Actualizar el displayName del usuario
          await user.updateDisplayName(username);

          // Crear documento del usuario en Firestore
          await _createUserDocument(user.uid, {
            'username': username,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });

          return {
            'success': true,
            'message': 'Usuario creado exitosamente',
            'userId': user.uid,
            'user': user,
          };
        } catch (firestoreError) {
          // Si falla la creación del documento, eliminar el usuario de Auth
          await user.delete();
          if (kDebugMode) {
            print('Error creating user document: $firestoreError');
          }
          return {
            'success': false,
            'message': 'Error al guardar datos del usuario',
          };
        }
      }

      return {'success': false, 'message': 'Error al crear el usuario'};
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code} - ${e.message}');
      }
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error in createUser: $e');
      }
      return {'success': false, 'message': 'Error inesperado al crear usuario'};
    }
  }

  // Verificar si el username ya existe
  static Future<bool> _checkUsernameExists(String username) async {
    try {
      final QuerySnapshot result =
          await _firestore
              .collection('users')
              .where('username', isEqualTo: username.toLowerCase())
              .limit(1)
              .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking username: $e');
      }
      // En caso de error, asumimos que no existe para no bloquear el registro
      return false;
    }
  }

  // Crear documento del usuario en Firestore
  static Future<void> _createUserDocument(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).set(userData);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user document: $e');
      }
      rethrow;
    }
  }

  // Obtener datos del usuario
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user data: $e');
      }
      return null;
    }
  }

  // Actualizar datos del usuario
  static Future<bool> updateUserData(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Crear una copia del mapa para no modificar el original
      final updateData = Map<String, dynamic>.from(data);
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(userId).update(updateData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user data: $e');
      }
      return false;
    }
  }

  // Iniciar sesión
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        // Verificar si el usuario existe en Firestore
        final userData = await getUserData(user.uid);

        return {
          'success': true,
          'message': 'Inicio de sesión exitoso',
          'userId': user.uid,
          'user': user,
          'userData': userData,
        };
      }

      return {'success': false, 'message': 'Error al iniciar sesión'};
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException in signIn: ${e.code} - ${e.message}');
      }
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error in signIn: $e');
      }
      return {
        'success': false,
        'message': 'Error inesperado al iniciar sesión',
      };
    }
  }

  // Cerrar sesión
  static Future<bool> signOut() async {
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      return false;
    }
  }

  // Obtener usuario actual
  static User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current user: $e');
      }
      return null;
    }
  }

  // Verificar si el usuario está autenticado
  static bool isUserAuthenticated() {
    try {
      return _auth.currentUser != null;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking authentication: $e');
      }
      return false;
    }
  }

  // Recargar usuario actual
  static Future<void> reloadCurrentUser() async {
    try {
      final user = getCurrentUser();
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reloading user: $e');
      }
    }
  }

  // Verificar si el email está verificado
  static bool isEmailVerified() {
    try {
      final user = getCurrentUser();
      return user?.emailVerified ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking email verification: $e');
      }
      return false;
    }
  }

  // Enviar email de verificación
  static Future<bool> sendEmailVerification() async {
    try {
      final user = getCurrentUser();
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending email verification: $e');
      }
      return false;
    }
  }

  // Restablecer contraseña
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Email de recuperación enviado'};
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException in resetPassword: ${e.code}');
      }
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error in resetPassword: $e');
      }
      return {
        'success': false,
        'message': 'Error al enviar email de recuperación',
      };
    }
  }

  // Stream de cambios de autenticación
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // Mensajes de error personalizados
  static String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Este email ya está registrado';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres)';
      case 'invalid-email':
        return 'El formato del email es inválido';
      case 'user-not-found':
        return 'No se encontró una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este email';
      case 'requires-recent-login':
        return 'Esta operación requiere autenticación reciente';
      case 'credential-already-in-use':
        return 'Estas credenciales ya están en uso';
      case 'invalid-verification-code':
        return 'Código de verificación inválido';
      case 'invalid-verification-id':
        return 'ID de verificación inválido';
      default:
        if (kDebugMode) {
          print('Unhandled auth error code: $errorCode');
        }
        return 'Error de autenticación. Intenta nuevamente';
    }
  }

  // Validaciones mejoradas
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    ).hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidUsername(String username) {
    if (username.isEmpty || username.length < 3 || username.length > 20) {
      return false;
    }
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
  }

  // Validación de nombre completo
  static bool isValidFullName(String name) {
    if (name.isEmpty || name.length < 2) return false;
    return RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(name);
  }

  // Limpiar recursos
  static void dispose() {
    // Método para limpiar recursos si es necesario
  }
}
