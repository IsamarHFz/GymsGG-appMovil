// models/routine_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  String id;
  String name;
  String target;
  String sets;
  String rest;
  String difficulty;
  String iconName;
  int order;

  Exercise({
    required this.id,
    required this.name,
    required this.target,
    required this.sets,
    required this.rest,
    required this.difficulty,
    required this.iconName,
    required this.order,
  });

  // Convierte el ejercicio a un Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target': target,
      'sets': sets,
      'rest': rest,
      'difficulty': difficulty,
      'iconName': iconName,
      'order': order,
    };
  }

  // Crea un Exercise desde un Map de Firestore
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id:
          map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name']?.toString() ?? 'Nuevo ejercicio',
      target: map['target']?.toString() ?? 'Grupo muscular',
      sets: map['sets']?.toString() ?? '3 series x 10 reps',
      rest: map['rest']?.toString() ?? '60 seg',
      difficulty: map['difficulty']?.toString() ?? 'Medio',
      iconName: map['iconName']?.toString() ?? 'fitness_center',
      order: map['order']?.toInt() ?? 0,
    );
  }

  // Método para actualizar propiedades individuales
  Exercise copyWith({
    String? id,
    String? name,
    String? target,
    String? sets,
    String? rest,
    String? difficulty,
    String? iconName,
    int? order,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      target: target ?? this.target,
      sets: sets ?? this.sets,
      rest: rest ?? this.rest,
      difficulty: difficulty ?? this.difficulty,
      iconName: iconName ?? this.iconName,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Exercise{id: $id, name: $name, target: $target, sets: $sets, rest: $rest, difficulty: $difficulty, iconName: $iconName, order: $order}';
  }
}

class Routine {
  String id;
  String name;
  String level;
  String difficulty;
  String duration;
  String frequency;
  String equipment;
  List<String> benefits;
  List<Exercise> exercises;
  DateTime createdAt;
  DateTime updatedAt;
  String userId;

  Routine({
    required this.id,
    required this.name,
    required this.level,
    required this.difficulty,
    required this.duration,
    required this.frequency,
    required this.equipment,
    required this.benefits,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  // Convierte la rutina a un Map para almacenamiento local
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'difficulty': difficulty,
      'duration': duration,
      'frequency': frequency,
      'equipment': equipment,
      'benefits': benefits,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'userId': userId,
    };
  }

  // Crea una Routine desde un Map local
  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id:
          map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name']?.toString() ?? 'Nueva rutina',
      level: map['level']?.toString() ?? 'Principiante',
      difficulty: map['difficulty']?.toString() ?? 'Media',
      duration: map['duration']?.toString() ?? '30-45 minutos',
      frequency: map['frequency']?.toString() ?? '3 veces por semana',
      equipment: map['equipment']?.toString() ?? 'Mancuernas',
      benefits: List<String>.from(
        map['benefits'] ??
            [
              'Fortalecimiento muscular',
              'Mejora de la resistencia',
              'Tonificación corporal',
            ],
      ),
      exercises:
          (map['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : DateTime.now(),
      userId: map['userId']?.toString() ?? '',
    );
  }

  // Convierte la rutina a formato Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'level': level,
      'difficulty': difficulty,
      'duration': duration,
      'frequency': frequency,
      'equipment': equipment,
      'benefits': benefits,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }

  // Crea una Routine desde un DocumentSnapshot de Firestore
  factory Routine.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('Document does not exist');
    }

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return Routine(
      id: doc.id,
      name: data['name']?.toString() ?? 'Nueva rutina',
      level: data['level']?.toString() ?? 'Principiante',
      difficulty: data['difficulty']?.toString() ?? 'Media',
      duration: data['duration']?.toString() ?? '30-45 minutos',
      frequency: data['frequency']?.toString() ?? '3 veces por semana',
      equipment: data['equipment']?.toString() ?? 'Mancuernas',
      benefits:
          data['benefits'] != null
              ? List<String>.from(data['benefits'])
              : [
                'Fortalecimiento muscular',
                'Mejora de la resistencia',
                'Tonificación corporal',
              ],
      exercises:
          data['exercises'] != null
              ? (data['exercises'] as List<dynamic>)
                  .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
                  .toList()
              : [],
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
      userId: data['userId']?.toString() ?? '',
    );
  }

  // Método para actualizar propiedades individuales
  Routine copyWith({
    String? id,
    String? name,
    String? level,
    String? difficulty,
    String? duration,
    String? frequency,
    String? equipment,
    List<String>? benefits,
    List<Exercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      frequency: frequency ?? this.frequency,
      equipment: equipment ?? this.equipment,
      benefits: benefits ?? List<String>.from(this.benefits),
      exercises: exercises ?? List<Exercise>.from(this.exercises),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  // Método para validar que la rutina tiene datos válidos
  bool isValid() {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        level.isNotEmpty &&
        difficulty.isNotEmpty;
  }

  // Método para obtener el número total de ejercicios
  int get totalExercises => exercises.length;

  // Método para obtener ejercicios ordenados
  List<Exercise> get orderedExercises {
    final sortedExercises = List<Exercise>.from(exercises);
    sortedExercises.sort((a, b) => a.order.compareTo(b.order));
    return sortedExercises;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Routine && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Routine{id: $id, name: $name, level: $level, difficulty: $difficulty, totalExercises: $totalExercises}';
  }
}
