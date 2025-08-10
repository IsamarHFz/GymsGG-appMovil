import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsgg_app/screens/edit_exercise_screen.dart';
import 'package:gymsgg_app/screens/edit_routine_screen.dart';
import 'package:gymsgg_app/screens/routine_execution_screen.dart';
import 'package:gymsgg_app/models/routine_model.dart';
import 'package:gymsgg_app/services/user_service.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class RoutineDetailsScreen extends StatefulWidget {
  static const String routeName = '/routine-details';

  final String routineId;
  final String routineName;
  final String level;
  final String difficulty;

  const RoutineDetailsScreen({
    super.key,
    String? routineId,
    required this.routineName,
    required this.level,
    required this.difficulty,
    required String fitnessLevel,
  }) : routineId = routineId ?? '';

  @override
  State<RoutineDetailsScreen> createState() => _RoutineDetailsScreenState();
}

class _RoutineDetailsScreenState extends State<RoutineDetailsScreen> {
  late Routine currentRoutine;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _isSaving = false; // ✅ NUEVO: Indicador de guardado

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadRoutine();
  }

  Future<void> _loadRoutine() async {
    try {
      // Verificar si el routineId es válido
      if (widget.routineId.isEmpty) {
        print('RoutineId está vacío, inicializando nueva rutina');
        _initializeNewRoutine();
        return;
      }

      DocumentSnapshot doc =
          await _firestore.collection('routines').doc(widget.routineId).get();

      if (doc.exists) {
        setState(() {
          currentRoutine = Routine.fromFirestore(doc);
          _isLoading = false;
        });
      } else {
        print('Documento no existe para ID: ${widget.routineId}');
        // Si no existe, creamos una nueva con datos básicos
        _initializeNewRoutine();
      }
    } catch (e) {
      print('Error loading routine: $e');
      print('RoutineId recibido: "${widget.routineId}"');
      _initializeNewRoutine();
    }
  }

  void _initializeNewRoutine() {
    final exercisesList = _getExercises();

    // Generar un ID válido si está vacío
    String validRoutineId =
        widget.routineId.isNotEmpty
            ? widget.routineId
            : DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      currentRoutine = Routine(
        id: validRoutineId,
        name:
            widget.routineName.isNotEmpty ? widget.routineName : 'Nueva rutina',
        level: widget.level.isNotEmpty ? widget.level : 'Principiante',
        difficulty: widget.difficulty.isNotEmpty ? widget.difficulty : 'Media',
        duration: _getDuration(),
        frequency: _getFrequency(),
        equipment: _getEquipment(),
        benefits: _getBenefits(),
        exercises:
            exercisesList
                .map(
                  (exerciseMap) => Exercise(
                    id:
                        DateTime.now().millisecondsSinceEpoch.toString() +
                        exerciseMap['name'].hashCode.toString(),
                    name: exerciseMap['name'],
                    target: exerciseMap['target'],
                    sets: exerciseMap['sets'],
                    rest: exerciseMap['rest'],
                    difficulty: exerciseMap['difficulty'],
                    iconName: _getIconName(exerciseMap['icon']),
                    order: exercisesList.indexOf(exerciseMap),
                  ),
                )
                .toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: "", // Se deberá asignar cuando se guarde
      );
      _isLoading = false;
    });

    // ✅ NUEVO: Guardar automáticamente la nueva rutina
    _saveRoutineToFirebase();

    print('Rutina inicializada con ID: $validRoutineId');
  }

  // ✅ MÉTODO MEJORADO con mejor UI feedback
  Future<void> _saveRoutineToFirebase() async {
    if (_isSaving) return; // Evitar guardados múltiples simultáneos

    try {
      setState(() => _isSaving = true);

      // Actualizar timestamp
      currentRoutine = currentRoutine.copyWith(updatedAt: DateTime.now());

      bool success = await UserService.saveUserRoutine(currentRoutine);

      if (success && mounted) {
        // ✅ Mostrar indicador sutil de guardado exitoso
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Guardado automáticamente'),
              ],
            ),
            backgroundColor: Colors.green.withOpacity(0.9),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error: Usuario no logueado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Agregar método para verificar autenticación
  void _checkAuthentication() {
    if (!UserService.isLoggedIn) {
      // Redirigir a login si no hay usuario
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
  }

  // ✅ MÉTODO MEJORADO con reordenamiento automático y guardado
  Future<void> _deleteExerciseFromFirebase(Exercise exercise) async {
    try {
      setState(() => _isLoading = true);

      // Remover el ejercicio
      currentRoutine.exercises.removeWhere((e) => e.id == exercise.id);

      // ✅ Reordenar los índices de los ejercicios restantes
      for (var i = 0; i < currentRoutine.exercises.length; i++) {
        currentRoutine.exercises[i] = currentRoutine.exercises[i].copyWith(
          order: i,
        );
      }

      // ✅ Guardar inmediatamente
      await _saveRoutineToFirebase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ejercicio eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar ejercicio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ MÉTODO MEJORADO con guardado automático
  Future<void> _saveExerciseChanges(Exercise exercise, bool isNew) async {
    try {
      setState(() => _isLoading = true);

      if (isNew) {
        // ✅ Asignar orden correcto al nuevo ejercicio
        exercise = exercise.copyWith(order: currentRoutine.exercises.length);
        currentRoutine.exercises.add(exercise);
      } else {
        // Encontrar y reemplazar el ejercicio existente
        final index = currentRoutine.exercises.indexWhere(
          (e) => e.id == exercise.id,
        );
        if (index != -1) {
          currentRoutine.exercises[index] = exercise;
        }
      }

      // ✅ Guardar automáticamente
      await _saveRoutineToFirebase();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar ejercicio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Container(
      decoration: AppTheme.foundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildRoutineInfo(),
                      _buildExercisesList(),
                      _buildActionButtons(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ HEADER MEJORADO con indicador de guardado
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppTheme.iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentRoutine.name,
                        style: const TextStyle(
                          color: AppTheme.iconColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // ✅ NUEVO: Indicador de estado de guardado
                    if (_isSaving)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.orange,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Guardando...',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Text(
                  'Nivel ${currentRoutine.level} • ${currentRoutine.difficulty}',
                  style: TextStyle(
                    color: AppTheme.textColor.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de la rutina',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.access_time,
              'Duración',
              currentRoutine.duration,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Frecuencia',
              currentRoutine.frequency,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.fitness_center,
              'Equipo',
              currentRoutine.equipment,
            ),
            const SizedBox(height: 16),
            const Text(
              'Beneficios principales:',
              style: TextStyle(
                color: AppTheme.iconColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...currentRoutine.benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildBenefitChip(benefit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ejercicios incluidos',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${currentRoutine.exercises.length} ejercicios',
                    style: TextStyle(
                      color: AppTheme.textColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppTheme.accentColor),
                    onPressed: _addNewExercise,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentRoutine.exercises.length,
            // ✅ MEJORADO: Guardado automático al reordenar
            onReorder: (oldIndex, newIndex) async {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final Exercise item = currentRoutine.exercises.removeAt(
                  oldIndex,
                );
                currentRoutine.exercises.insert(newIndex, item);
                // Actualizar el orden de todos los ejercicios
                for (var i = 0; i < currentRoutine.exercises.length; i++) {
                  currentRoutine.exercises[i] = currentRoutine.exercises[i]
                      .copyWith(order: i);
                }
              });
              // ✅ Guardar inmediatamente en Firebase
              await _saveRoutineToFirebase();
            },
            itemBuilder: (context, index) {
              final exercise = currentRoutine.exercises[index];
              return _buildExerciseCardFromModel(exercise, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCardFromModel(Exercise exercise, int index) {
    return Container(
      key: Key(exercise.id),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.drag_handle,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconFromName(exercise.iconName),
                  color: AppTheme.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        color: AppTheme.iconColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      exercise.target,
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(
                    exercise.difficulty,
                  ).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  exercise.difficulty,
                  style: TextStyle(
                    color: _getDifficultyColor(exercise.difficulty),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: AppTheme.accentColor,
                onPressed: () => _editExercise(exercise),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                onPressed: () => _deleteExercise(exercise),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildExerciseDetail(Icons.repeat, exercise.sets),
              const SizedBox(width: 16),
              _buildExerciseDetail(Icons.timer, exercise.rest),
            ],
          ),
        ],
      ),
    );
  }

  void _addNewExercise() async {
    final newExercise = Exercise(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Nuevo ejercicio',
      target: 'Grupo muscular',
      sets: '3 series x 10 reps',
      rest: '60 seg',
      difficulty: 'Medio',
      iconName: 'fitness_center',
      order: currentRoutine.exercises.length,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                EditExerciseScreen(exercise: newExercise, isNewExercise: true),
      ),
    );

    if (result != null && result is Exercise) {
      await _saveExerciseChanges(result, true);
    }
  }

  void _editExercise(Exercise exercise) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                EditExerciseScreen(exercise: exercise, isNewExercise: false),
      ),
    );

    if (result != null && result is Exercise) {
      await _saveExerciseChanges(result, false);
    }
  }

  void _deleteExercise(Exercise exercise) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: const Text(
              'Eliminar ejercicio',
              style: TextStyle(color: AppTheme.iconColor),
            ),
            content: Text(
              '¿Estás seguro de que quieres eliminar "${exercise.name}"?',
              style: const TextStyle(color: AppTheme.textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteExerciseFromFirebase(exercise);
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentColor, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppTheme.iconColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.textColor, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitChip(String benefit) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          benefit,
          style: const TextStyle(color: AppTheme.textColor, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildExerciseDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textColor.withOpacity(0.6), size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: AppTheme.textColor.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'fácil':
        return Colors.green;
      case 'medio':
        return Colors.orange;
      case 'difícil':
        return Colors.red;
      default:
        return AppTheme.accentColor;
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Botón Personalizar Rutina
          Container(
            width: double.infinity,
            height: 50,
            margin: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: () => _navigateToEditRoutine(context),
              icon: const Icon(Icons.edit, color: AppTheme.accentColor),
              label: const Text(
                'Personalizar Rutina',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.accentColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),

          // Botón Comenzar Rutina
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [AppTheme.accentColor, Color(0xFFFFA500)],
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RoutineExecutionScreen(
                          routineName: currentRoutine.name,
                          level: currentRoutine.level,
                          exercises: _convertExercisesToMap(),
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
              label: const Text(
                'Comenzar Rutina',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO MEJORADO con guardado automático
  void _navigateToEditRoutine(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                EditRoutineScreen(routine: currentRoutine, isNewRoutine: false),
      ),
    );

    if (result != null && result is Routine) {
      setState(() {
        currentRoutine = result;
      });
      // ✅ Guardar automáticamente los cambios de la rutina
      await _saveRoutineToFirebase();
    }
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'directions_run':
        return Icons.directions_run;
      case 'straighten':
        return Icons.straighten;
      case 'accessibility_new':
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }

  String _getIconName(IconData icon) {
    if (icon == Icons.fitness_center) return 'fitness_center';
    if (icon == Icons.directions_run) return 'directions_run';
    if (icon == Icons.straighten) return 'straighten';
    if (icon == Icons.accessibility_new) return 'accessibility_new';
    return 'fitness_center';
  }

  List<Map<String, dynamic>> _convertExercisesToMap() {
    return currentRoutine.exercises.map((exercise) {
      return {
        'name': exercise.name,
        'target': exercise.target,
        'sets': exercise.sets,
        'rest': exercise.rest,
        'difficulty': exercise.difficulty,
        'icon': _getIconFromName(exercise.iconName),
      };
    }).toList();
  }

  // Métodos para obtener información personalizada según el nivel
  String _getDuration() {
    switch (widget.level.toLowerCase()) {
      case 'principiante':
      case 'beginner':
        return '30-45 minutos';
      case 'intermedio':
      case 'intermediate':
        return '45-60 minutos';
      case 'avanzado':
      case 'advanced':
        return '60-90 minutos';
      default:
        return '45-60 minutos';
    }
  }

  String _getFrequency() {
    switch (widget.level.toLowerCase()) {
      case 'principiante':
      case 'beginner':
        return '2-3 veces por semana';
      case 'intermedio':
      case 'intermediate':
        return '3-4 veces por semana';
      case 'avanzado':
      case 'advanced':
        return '4-5 veces por semana';
      default:
        return '3-4 veces por semana';
    }
  }

  String _getEquipment() {
    switch (widget.level.toLowerCase()) {
      case 'principiante':
      case 'beginner':
        return 'Peso corporal, mancuernas ligeras';
      case 'intermedio':
      case 'intermediate':
        return 'Mancuernas, banco, barras';
      case 'avanzado':
      case 'advanced':
        return 'Equipamiento completo de gimnasio';
      default:
        return 'Mancuernas, banco';
    }
  }

  List<String> _getBenefits() {
    switch (widget.level.toLowerCase()) {
      case 'principiante':
      case 'beginner':
        return [
          'Introducción al ejercicio',
          'Construcción de hábitos',
          'Fortalecimiento básico',
        ];
      case 'intermedio':
      case 'intermediate':
        return [
          'Fortalecimiento muscular',
          'Mejora de la resistencia',
          'Tonificación corporal',
        ];
      case 'avanzado':
      case 'advanced':
        return ['Hipertrofia muscular', 'Fuerza máxima', 'Definición avanzada'];
      default:
        return [
          'Fortalecimiento muscular',
          'Mejora de la resistencia',
          'Tonificación corporal',
        ];
    }
  }

  List<Map<String, dynamic>> _getExercises() {
    switch (widget.level.toLowerCase()) {
      case 'principiante':
      case 'beginner':
        return [
          {
            'name': 'Sentadillas básicas',
            'target': 'Piernas, glúteos',
            'sets': '3 series x 8-12 reps',
            'rest': '60 seg',
            'difficulty': 'Fácil',
            'icon': Icons.fitness_center,
          },
          {
            'name': 'Flexiones de rodillas',
            'target': 'Pecho, brazos',
            'sets': '3 series x 5-10 reps',
            'rest': '60 seg',
            'difficulty': 'Fácil',
            'icon': Icons.directions_run,
          },
          {
            'name': 'Plancha básica',
            'target': 'Core',
            'sets': '3 series x 20-30 seg',
            'rest': '45 seg',
            'difficulty': 'Fácil',
            'icon': Icons.straighten,
          },
        ];
      case 'avanzado':
      case 'advanced':
        return [
          {
            'name': 'Sentadillas con peso',
            'target': 'Piernas, glúteos',
            'sets': '4 series x 8-10 reps',
            'rest': '90-120 seg',
            'difficulty': 'Difícil',
            'icon': Icons.fitness_center,
          },
          {
            'name': 'Peso muerto',
            'target': 'Espalda, piernas',
            'sets': '4 series x 6-8 reps',
            'rest': '120 seg',
            'difficulty': 'Difícil',
            'icon': Icons.directions_run,
          },
          {
            'name': 'Press de banca',
            'target': 'Pecho, hombros',
            'sets': '4 series x 8-10 reps',
            'rest': '90-120 seg',
            'difficulty': 'Difícil',
            'icon': Icons.accessibility_new,
          },
        ];
      default: // intermedio
        return [
          {
            'name': 'Sentadillas con sumo',
            'target': 'Piernas, glúteos',
            'sets': '3 series x 12-15 reps',
            'rest': '60-90 seg',
            'difficulty': 'Medio',
            'icon': Icons.fitness_center,
          },
          {
            'name': 'Búlgaras',
            'target': 'Cuádriceps, glúteos',
            'sets': '3 series x 10-12 reps',
            'rest': '60 seg',
            'difficulty': 'Medio',
            'icon': Icons.directions_run,
          },
          {
            'name': 'Extensiones',
            'target': 'Cuádriceps',
            'sets': '3 series x 12-15 reps',
            'rest': '45-60 seg',
            'difficulty': 'Fácil',
            'icon': Icons.straighten,
          },
          {
            'name': 'Hip thrust',
            'target': 'Glúteos, isquiotibiales',
            'sets': '3 series x 12-15 reps',
            'rest': '60-90 seg',
            'difficulty': 'Medio',
            'icon': Icons.accessibility_new,
          },
        ];
    }
  }
}
