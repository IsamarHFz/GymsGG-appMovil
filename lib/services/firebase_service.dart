import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // MÉTODO PRINCIPAL DE LOGIN
  static Future<Map<String, dynamic>> signInUserWithProfile({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      print('🔐 Intentando login con: $emailOrUsername');

      UserCredential userCredential;

      if (emailOrUsername.contains('@')) {
        // Es email
        userCredential = await _auth.signInWithEmailAndPassword(
          email: emailOrUsername,
          password: password,
        );
      } else {
        // Es username - convertir a email
        final email = await _getUserEmailByUsername(emailOrUsername);
        if (email == null) {
          return {'success': false, 'message': 'Usuario no encontrado'};
        }
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (userCredential.user != null) {
        print('✅ Login exitoso para: ${userCredential.user!.email}');

        // Verificar si el perfil está completo
        final hasCompleteProfile = await _checkCompleteProfile(
          userCredential.user!.uid,
        );

        // Guardar sesión
        await _saveUserSession(userCredential.user!.email!);

        return {
          'success': true,
          'message': 'Login exitoso',
          'hasCompleteProfile': hasCompleteProfile,
        };
      } else {
        return {'success': false, 'message': 'Error en la autenticación'};
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException en login: ${e.code}');
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      print('❌ Error inesperado en login: $e');
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // Verificar si el perfil está completo
  static Future<bool> _checkCompleteProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        print('📄 No existe documento de usuario');
        return false;
      }

      final userData = doc.data() as Map<String, dynamic>;

      // Verificar campos esenciales para considerar el perfil completo
      final bool isComplete =
          userData['profileCompleted'] == true ||
          userData['onboardingCompleted'] == true ||
          (userData['fitnessLevel'] != null);

      print('🔍 Perfil completo: $isComplete');
      print('   - profileCompleted: ${userData['profileCompleted']}');
      print('   - fitnessLevel: ${userData['fitnessLevel']}');
      print('   - onboardingCompleted: ${userData['onboardingCompleted']}');

      return isComplete;
    } catch (e) {
      print('❌ Error verificando perfil: $e');
      return false;
    }
  }

  // Obtener email por username
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
      print('Error getting user email by username: $e');
      return null;
    }
  }

  // Guardar sesión del usuario
  static Future<void> _saveUserSession(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setBool('user_logged_in', true);
      print('Sesión guardada para: $email');
    } catch (e) {
      print('Error guardando sesión: $e');
    }
  }

  // Limpiar sesión del usuario
  static Future<void> _clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.setBool('user_logged_in', false);
      print('Sesión limpiada');
    } catch (e) {
      print('Error limpiando sesión: $e');
    }
  }

  // MÉTODO PARA ACTUALIZAR PERFIL (para el onboarding)
  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final updateData = Map<String, dynamic>.from(data);
        updateData['updatedAt'] = FieldValue.serverTimestamp();

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(updateData, SetOptions(merge: true));

        print('✅ Perfil actualizado: ${data.keys.join(', ')}');
      } else {
        throw Exception('No hay usuario autenticado');
      }
    } catch (e) {
      print('❌ Error actualizando perfil: $e');
      throw Exception('Error updating profile: ${e.toString()}');
    }
  }

  // MÉTODO PARA OBTENER PERFIL COMPLETO
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No current user found');
        return null;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        final userData = doc.data() as Map<String, dynamic>;

        // Agregar datos básicos de Firebase Auth si no están en Firestore
        if (!userData.containsKey('email') && user.email != null) {
          userData['email'] = user.email!;
        }
        if (!userData.containsKey('name') && user.displayName != null) {
          userData['name'] = user.displayName!;
        }

        return userData;
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo perfil: $e');
      return null;
    }
  }

  // MÉTODO PARA VERIFICAR SI EL PERFIL ESTÁ COMPLETO (público)
  static Future<bool> hasCompleteProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await _checkCompleteProfile(user.uid);
      }
      return false;
    } catch (e) {
      print('❌ Error verificando perfil completo: $e');
      return false;
    }
  }

  // Cerrar sesión
  static Future<Map<String, dynamic>> signOut() async {
    try {
      await _auth.signOut();
      await _clearUserSession();
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

  // Método para actualizar el perfil del usuario actual
  static Future<bool> updateCurrentUserProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final User? currentUser = getCurrentUser();
      if (currentUser == null) return false;

      return await updateUserData(currentUser.uid, data);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating current user profile: $e');
      }
      return false;
    }
  }

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
}
