// models/routine_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  String id;
  String name;
  String target;
  String sets;
  String rest;
  String difficulty;
  String iconName; // Guardamos el nombre del ícono como string
  int order; // Para el orden de los ejercicios

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

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      target: map['target'] ?? '',
      sets: map['sets'] ?? '',
      rest: map['rest'] ?? '',
      difficulty: map['difficulty'] ?? '',
      iconName: map['iconName'] ?? 'fitness_center',
      order: map['order'] ?? 0,
    );
  }

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
  String userId; // Para asociar rutinas con usuarios

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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      level: map['level'] ?? '',
      difficulty: map['difficulty'] ?? '',
      duration: map['duration'] ?? '',
      frequency: map['frequency'] ?? '',
      equipment: map['equipment'] ?? '',
      benefits: List<String>.from(map['benefits'] ?? []),
      exercises:
          (map['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: map['userId'] ?? '',
    );
  }

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
      benefits: benefits ?? this.benefits,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
}
