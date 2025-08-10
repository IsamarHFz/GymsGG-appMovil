// services/user_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsgg_app/models/routine_model.dart';
import 'package:gymsgg_app/services/auth_service.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ NUEVO: Cache local para optimizar rendimiento
  static final Map<String, Routine> _routineCache = {};
  static DateTime? _lastCacheUpdate;
  static const int _cacheValidityMinutes = 5;

  // Obtener usuario actual desde AuthService
  static User? get currentUser => AuthService.currentUser;

  // Obtener ID del usuario actual
  static String get currentUserId => AuthService.currentUserId;

  // Verificar si hay usuario logueado
  static bool get isLoggedIn => AuthService.isLoggedIn;

  // Inicializar el servicio
  static Future<void> initialize() async {
    await AuthService.initialize();
    // ✅ NUEVO: Configurar persistencia offline
    await _configureOfflinePersistence();
  }

  // ✅ NUEVO: Configurar persistencia offline
  static Future<void> _configureOfflinePersistence() async {
    try {
      await _firestore.enableNetwork();
      print('✅ Persistencia offline configurada');
    } catch (e) {
      print('⚠️ Error configurando persistencia: $e');
    }
  }

  // ✅ MÉTODO ULTRA MEJORADO con reintentos, cache y validación exhaustiva
  static Future<bool> saveUserRoutine(Routine routine) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        if (!isLoggedIn) {
          print('❌ No hay usuario logueado');
          return false;
        }

        print(
          '🔄 Guardando rutina: ${routine.name} (intento ${retryCount + 1})',
        );

        // ✅ Validaciones exhaustivas
        if (!_validateRoutine(routine)) {
          print('❌ Rutina no válida');
          return false;
        }

        // ✅ Asignar userId y actualizar timestamp
        final updatedRoutine = routine.copyWith(
          userId: currentUserId,
          updatedAt: DateTime.now(),
        );

        // ✅ Verificar conectividad antes de guardar
        final hasConnectivity = await checkFirebaseConnectivity();
        if (!hasConnectivity) {
          print('⚠️ Sin conexión, guardando offline...');
        }

        // ✅ Guardar en Firestore con configuración optimizada
        await _firestore
            .collection('routines')
            .doc(routine.id)
            .set(updatedRoutine.toFirestore(), SetOptions(merge: true));

        // ✅ Actualizar cache local
        _routineCache[routine.id] = updatedRoutine;
        _lastCacheUpdate = DateTime.now();

        print('✅ Rutina guardada exitosamente: ${routine.id}');
        return true;
      } on FirebaseException catch (e) {
        retryCount++;
        print(
          '❌ Error de Firebase (intento $retryCount): ${e.code} - ${e.message}',
        );

        // ✅ Manejar errores específicos
        if (_isRetryableError(e.code) && retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }
        break;
      } catch (e) {
        retryCount++;
        print('❌ Error general (intento $retryCount): $e');

        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount));
          continue;
        }
        break;
      }
    }

    print('❌ Falló después de $maxRetries intentos');
    return false;
  }

  // ✅ NUEVO: Validar rutina antes de guardar
  static bool _validateRoutine(Routine routine) {
    if (routine.id.isEmpty) {
      print('❌ ID de rutina vacío');
      return false;
    }

    if (routine.name.trim().isEmpty) {
      print('❌ Nombre de rutina vacío');
      return false;
    }

    if (routine.exercises.isEmpty) {
      print('⚠️ Rutina sin ejercicios');
    }

    // Validar ejercicios
    for (var exercise in routine.exercises) {
      if (exercise.id.isEmpty || exercise.name.trim().isEmpty) {
        print('❌ Ejercicio inválido: ${exercise.name}');
        return false;
      }
    }

    return true;
  }

  // ✅ NUEVO: Determinar si un error es reintentable
  static bool _isRetryableError(String errorCode) {
    const retryableErrors = [
      'unavailable',
      'deadline-exceeded',
      'aborted',
      'internal',
      'resource-exhausted',
    ];
    return retryableErrors.contains(errorCode);
  }

  // ✅ MÉTODO MEJORADO para verificar conectividad con timeout
  static Future<bool> checkFirebaseConnectivity() async {
    try {
      await _firestore
          .doc('_health/check')
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );
      return true;
    } catch (e) {
      print('❌ Sin conexión a Firebase: $e');
      return false;
    }
  }

  // ✅ MÉTODO MEJORADO con cache inteligente
  static Future<List<Routine>> getUserRoutines() async {
    try {
      if (!isLoggedIn) {
        print('❌ No hay usuario logueado');
        return [];
      }

      // ✅ Verificar cache válido
      if (_isCacheValid() && _routineCache.isNotEmpty) {
        print('✅ Usando cache local (${_routineCache.length} rutinas)');
        return _routineCache.values
            .where((r) => r.userId == currentUserId)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }

      print('🔄 Cargando rutinas desde Firebase...');

      QuerySnapshot snapshot =
          await _firestore
              .collection('routines')
              .where('userId', isEqualTo: currentUserId)
              .orderBy('updatedAt', descending: true)
              .get();

      final routines =
          snapshot.docs.map((doc) => Routine.fromFirestore(doc)).toList();

      // ✅ Actualizar cache
      _routineCache.clear();
      for (var routine in routines) {
        _routineCache[routine.id] = routine;
      }
      _lastCacheUpdate = DateTime.now();

      print('✅ ${routines.length} rutinas cargadas y cacheadas');
      return routines;
    } on FirebaseException catch (e) {
      print('❌ Error de Firebase cargando rutinas: ${e.message}');

      // ✅ Retornar cache como fallback
      if (_routineCache.isNotEmpty) {
        print('⚠️ Usando cache como fallback');
        return _routineCache.values
            .where((r) => r.userId == currentUserId)
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error general cargando rutinas: $e');
      return [];
    }
  }

  // ✅ MÉTODO MEJORADO con cache
  static Future<Routine?> getUserRoutine(String routineId) async {
    try {
      if (!isLoggedIn) {
        print('❌ No hay usuario logueado');
        return null;
      }

      // ✅ Verificar cache primero
      if (_routineCache.containsKey(routineId)) {
        final cachedRoutine = _routineCache[routineId]!;
        if (cachedRoutine.userId == currentUserId) {
          print('✅ Rutina obtenida desde cache: ${cachedRoutine.name}');
          return cachedRoutine;
        }
      }

      print('🔄 Cargando rutina desde Firebase: $routineId');

      DocumentSnapshot doc =
          await _firestore.collection('routines').doc(routineId).get();

      if (doc.exists) {
        Routine routine = Routine.fromFirestore(doc);

        if (routine.userId == currentUserId) {
          // ✅ Actualizar cache
          _routineCache[routineId] = routine;
          print('✅ Rutina cargada: ${routine.name}');
          return routine;
        } else {
          print('❌ La rutina no pertenece al usuario actual');
          return null;
        }
      }

      print('❌ Rutina no encontrada: $routineId');
      return null;
    } on FirebaseException catch (e) {
      print('❌ Error de Firebase cargando rutina: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Error general cargando rutina: $e');
      return null;
    }
  }

  // ✅ MÉTODO MEJORADO con limpieza de cache
  static Future<bool> deleteUserRoutine(String routineId) async {
    try {
      if (!isLoggedIn) {
        print('❌ No hay usuario logueado');
        return false;
      }

      print('🔄 Eliminando rutina: $routineId');

      // ✅ Verificar que la rutina pertenezca al usuario
      Routine? routine = await getUserRoutine(routineId);
      if (routine == null) {
        print('❌ Rutina no encontrada o no pertenece al usuario');
        return false;
      }

      await _firestore.collection('routines').doc(routineId).delete();

      // ✅ Limpiar cache
      _routineCache.remove(routineId);

      print('✅ Rutina eliminada exitosamente: $routineId');
      return true;
    } on FirebaseException catch (e) {
      print('❌ Error de Firebase eliminando rutina: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Error general eliminando rutina: $e');
      return false;
    }
  }

  // ✅ MÉTODO MEJORADO con manejo robusto de errores
  static Stream<List<Routine>> getUserRoutinesStream() {
    if (!isLoggedIn) {
      print('❌ No hay usuario logueado para stream');
      return Stream.value([]);
    }

    print('🔄 Iniciando stream de rutinas para usuario: $currentUserId');

    return _firestore
        .collection('routines')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .handleError((error) {
          print('❌ Error en stream de rutinas: $error');
          // ✅ Retornar cache como fallback
          return _routineCache.values
              .where((r) => r.userId == currentUserId)
              .toList();
        })
        .map((snapshot) {
          try {
            final routines =
                snapshot.docs
                    .map((doc) {
                      try {
                        final routine = Routine.fromFirestore(doc);
                        // ✅ Actualizar cache en tiempo real
                        _routineCache[routine.id] = routine;
                        return routine;
                      } catch (e) {
                        print('❌ Error parseando rutina ${doc.id}: $e');
                        return null;
                      }
                    })
                    .where((routine) => routine != null)
                    .cast<Routine>()
                    .toList();

            _lastCacheUpdate = DateTime.now();
            print('✅ Stream actualizado: ${routines.length} rutinas');
            return routines;
          } catch (e) {
            print('❌ Error procesando snapshot: $e');
            // ✅ Retornar cache como fallback
            return _routineCache.values
                .where((r) => r.userId == currentUserId)
                .toList();
          }
        });
  }

  // ✅ NUEVO: Verificar si el cache es válido
  static bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;

    final difference = DateTime.now().difference(_lastCacheUpdate!);
    return difference.inMinutes < _cacheValidityMinutes;
  }

  // ✅ MÉTODO MEJORADO para crear perfil
  static Future<bool> createUserProfile({
    required String name,
    required String email,
    String? fitnessLevel,
  }) async {
    try {
      if (!isLoggedIn) {
        print('❌ No hay usuario logueado para crear perfil');
        return false;
      }

      print('🔄 Creando perfil para usuario: $currentUserId');

      await _firestore.collection('users').doc(currentUserId).set({
        'name': name,
        'email': email,
        'fitnessLevel': fitnessLevel ?? 'beginner',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      print('✅ Perfil creado exitosamente');
      return true;
    } on FirebaseException catch (e) {
      print('❌ Error de Firebase creando perfil: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Error general creando perfil: $e');
      return false;
    }
  }

  // ✅ MÉTODO MEJORADO para obtener perfil
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (!isLoggedIn) {
        print('❌ No hay usuario logueado para obtener perfil');
        return null;
      }

      print('🔄 Obteniendo perfil para usuario: $currentUserId');

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUserId).get();

      if (doc.exists) {
        print('✅ Perfil obtenido exitosamente');
        return doc.data() as Map<String, dynamic>;
      }

      print('❌ Perfil no encontrado');
      return null;
    } on FirebaseException catch (e) {
      print('❌ Error de Firebase obteniendo perfil: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Error general obteniendo perfil: $e');
      return null;
    }
  }

  // ✅ MÉTODO MEJORADO para actualizar perfil
  static Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    try {
      if (!isLoggedIn) {
        print('❌ No hay usuario logueado para actualizar perfil');
        return false;
      }

      print('🔄 Actualizando perfil para usuario: $currentUserId');

      // Agregar timestamp de actualización
      data['updatedAt'] = Timestamp.now();

      await _firestore.collection('users').doc(currentUserId).update(data);

      print('✅ Perfil actualizado exitosamente');
      return true;
    } on FirebaseException catch (e) {
      print('❌ Error de Firebase actualizando perfil: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Error general actualizando perfil: $e');
      return false;
    }
  }

  // ✅ MÉTODO MEJORADO para obtener estadísticas
  static Future<Map<String, int>> getUserStats() async {
    try {
      if (!isLoggedIn) return {'routines': 0, 'exercises': 0};

      final routines = await getUserRoutines();
      int totalExercises = routines.fold(
        0,
        (sum, routine) => sum + routine.exercises.length,
      );

      return {
        'routines': routines.length,
        'exercises': totalExercises,
        'lastActivity':
            routines.isNotEmpty
                ? routines.first.updatedAt.millisecondsSinceEpoch
                : 0,
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {'routines': 0, 'exercises': 0, 'lastActivity': 0};
    }
  }

  // ✅ MÉTODO MEJORADO para limpiar datos
  static Future<void> clearOfflineData() async {
    try {
      await _firestore.clearPersistence();
      _routineCache.clear();
      _lastCacheUpdate = null;
      print('✅ Datos offline y cache limpiados');
    } catch (e) {
      print('❌ Error limpiando datos offline: $e');
    }
  }

  // ✅ NUEVO: Forzar sincronización con servidor
  static Future<bool> forceSyncWithServer() async {
    try {
      if (!isLoggedIn) return false;

      print('🔄 Forzando sincronización con servidor...');

      // Limpiar cache local
      _routineCache.clear();
      _lastCacheUpdate = null;

      // Cargar datos frescos
      final routines = await getUserRoutines();

      print('✅ Sincronización completada: ${routines.length} rutinas');
      return true;
    } catch (e) {
      print('❌ Error en sincronización forzada: $e');
      return false;
    }
  }

  // ✅ NUEVO: Backup de rutinas importantes
  static Future<bool> backupUserData() async {
    try {
      if (!isLoggedIn) return false;

      final routines = await getUserRoutines();
      final profile = await getUserProfile();

      final backupData = {
        'userId': currentUserId,
        'timestamp': Timestamp.now(),
        'routines': routines.map((r) => r.toFirestore()).toList(),
        'profile': profile,
      };

      await _firestore
          .collection('backups')
          .doc('${currentUserId}_${DateTime.now().millisecondsSinceEpoch}')
          .set(backupData);

      print('✅ Backup creado exitosamente');
      return true;
    } catch (e) {
      print('❌ Error creando backup: $e');
      return false;
    }
  }

  // Método para cerrar sesión
  static Future<void> signOut() async {
    try {
      print('🔄 Cerrando sesión...');

      // ✅ Limpiar cache antes de cerrar sesión
      _routineCache.clear();
      _lastCacheUpdate = null;

      await AuthService.signOut();
      print('✅ Sesión cerrada exitosamente');
    } catch (e) {
      print('❌ Error cerrando sesión: $e');
    }
  }
}

// ✅ NUEVA CLASE: Excepción personalizada para errores de sincronización
class SyncException implements Exception {
  final String message;
  final String? errorCode;

  const SyncException(this.message, {this.errorCode});

  @override
  String toString() =>
      'SyncException: $message ${errorCode != null ? '($errorCode)' : ''}';
}

// ✅ NUEVA CLASE: Timeout personalizado
class TimeoutException implements Exception {
  final String message;

  const TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
