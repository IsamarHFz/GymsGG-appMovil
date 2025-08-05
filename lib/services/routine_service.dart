import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsgg_app/models/routine_model.dart';

class RoutineService {
  final CollectionReference routinesCollection = FirebaseFirestore.instance
      .collection('routines');

  Future<void> saveRoutine(Routine routine) async {
    print("🛠️ Entrando a saveRoutine con ID: ${routine.id}");
    if (routine.id.isEmpty) {
      print("🆕 Creando nueva rutina");
      await createRoutine(routine);
    } else {
      // Verifica si el documento existe
      final doc = await routinesCollection.doc(routine.id).get();
      if (doc.exists) {
        print("✏️ Actualizando rutina existente");
        await updateRoutine(routine);
      } else {
        print("📄 Documento no existe, creando rutina con ID personalizado");
        await routinesCollection.doc(routine.id).set(routine.toMap());
      }
    }
  }

  Future<void> createRoutine(Routine routine) async {
    try {
      final docRef = await routinesCollection.add(routine.toMap());
      print("✅ Rutina creada con ID: ${docRef.id}");
    } catch (e) {
      print("❌ Error al crear rutina: $e");
    }
  }

  Future<void> updateRoutine(Routine routine) async {
    try {
      await routinesCollection.doc(routine.id).update(routine.toMap());
      print("✅ Rutina actualizada");
    } catch (e) {
      print("❌ Error al actualizar rutina: $e");
    }
  }
}
