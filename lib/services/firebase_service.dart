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

  // Iniciar sesión con email o username
  static Future<Map<String, dynamic>> signInUser({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      String email = emailOrUsername;

      // Si el usuario ingresó un username en lugar de email,
      // necesitamos convertirlo a email
      if (!emailOrUsername.contains('@')) {
        // Buscar el email asociado al username en Firestore
        final userEmail = await _getUserEmailByUsername(emailOrUsername);
        if (userEmail == null) {
          return {'success': false, 'message': 'Usuario no encontrado'};
        }
        email = userEmail;
      }

      // Intentar hacer login con email y contraseña
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
        print('FirebaseAuthException in signInUser: ${e.code} - ${e.message}');
      }
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error in signInUser: $e');
      }
      return {
        'success': false,
        'message': 'Error inesperado al iniciar sesión',
      };
    }
  }

  // Método auxiliar para obtener email por username
  static Future<String?> _getUserEmailByUsername(String username) async {
    try {
      final QuerySnapshot userQuery =
          await _firestore
              .collection('users')
              .where('username', isEqualTo: username.toLowerCase())
              .limit(1)
              .get();

      if (userQuery.docs.isNotEmpty) {
        return userQuery.docs.first.get('email') as String;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user email by username: $e');
      }
      return null;
    }
  }

  // Cerrar sesión
  static Future<Map<String, dynamic>> signOut() async {
    try {
      await _auth.signOut();
      return {'success': true, 'message': 'Sesión cerrada exitosamente'};
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      return {'success': false, 'message': 'Error al cerrar sesión'};
    }
  }

  // Obtener usuario actual
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Verificar si hay un usuario autenticado
  static bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Stream del estado de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Método para obtener mensajes de error más amigables
  static String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No se encontró una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'El formato del email es inválido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      default:
        return 'Error de autenticación: $errorCode';
    }
  }

  // Métodos de validación auxiliares
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidUsername(String username) {
    return username.length >= 3 &&
        RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // OPCIONAL: Mantener el método signIn original para compatibilidad
  // (solo si lo usas en otras partes de tu app)
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    // Simplemente llama al nuevo método
    return await signInUser(emailOrUsername: email, password: password);
  }
}
