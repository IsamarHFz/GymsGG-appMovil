import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class WorkoutSession {
  final String routineName;
  final String level;
  final DateTime startTime;
  DateTime? endTime;
  final List<ExerciseSession> exercises;
  int totalRestTime = 0;
  int totalWorkoutTime = 0;

  WorkoutSession({
    required this.routineName,
    required this.level,
    required this.startTime,
    required this.exercises,
  });

  Duration get totalDuration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'routineName': routineName,
      'level': level,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalRestTime': totalRestTime,
      'totalWorkoutTime': totalWorkoutTime,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class ExerciseSession {
  final String name;
  final String target;
  final List<SetSession> sets;
  DateTime? startTime;
  DateTime? endTime;

  ExerciseSession({
    required this.name,
    required this.target,
    required this.sets,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'target': target,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }
}

class SetSession {
  int reps;
  double weight;
  DateTime? completedAt;
  int restTimeUsed;
  bool isCompleted;

  SetSession({
    this.reps = 0,
    this.weight = 0.0,
    this.completedAt,
    this.restTimeUsed = 0,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'completedAt': completedAt?.toIso8601String(),
      'restTimeUsed': restTimeUsed,
      'isCompleted': isCompleted,
    };
  }
}

class RoutineExecutionScreen extends StatefulWidget {
  static const String routeName = '/routine-execution';

  final String routineName;
  final String level;
  final List<Map<String, dynamic>> exercises;

  const RoutineExecutionScreen({
    super.key,
    required this.routineName,
    required this.level,
    required this.exercises,
  });

  @override
  State<RoutineExecutionScreen> createState() => _RoutineExecutionScreenState();
}

class _RoutineExecutionScreenState extends State<RoutineExecutionScreen>
    with TickerProviderStateMixin {
  int currentExerciseIndex = 0;
  int currentSet = 1;
  bool isResting = false;
  bool isPaused = false;
  bool isCompleted = false;
  bool isPreviewMode = false;

  Timer? _timer;
  Timer? _workoutTimer;
  int _secondsRemaining = 0;
  int _workoutElapsedSeconds = 0;
  int _restStartTime = 0;

  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Workout Session Tracking
  late WorkoutSession workoutSession;

  // Controllers para modificar reps y peso
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeWorkoutSession();
    _startWorkoutTimer();
  }

  void _initializeControllers() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  void _initializeWorkoutSession() {
    final exercises =
        widget.exercises.map((exercise) {
          int totalSets = _extractSetsCount(exercise['sets']);
          return ExerciseSession(
            name: exercise['name'],
            target: exercise['target'],
            sets: List.generate(totalSets, (index) => SetSession()),
          );
        }).toList();

    workoutSession = WorkoutSession(
      routineName: widget.routineName,
      level: widget.level,
      startTime: DateTime.now(),
      exercises: exercises,
    );

    // Iniciar el primer ejercicio
    workoutSession.exercises[0].startTime = DateTime.now();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused && !isCompleted) {
        setState(() {
          _workoutElapsedSeconds++;
        });
      }
    });
  }

  int _extractSetsCount(String setsText) {
    RegExp regExp = RegExp(r'(\d+)\s*series');
    Match? match = regExp.firstMatch(setsText);
    return match != null ? int.parse(match.group(1)!) : 3;
  }

  int _extractRestTime(String restText) {
    RegExp regExp = RegExp(r'(\d+)');
    Match? match = regExp.firstMatch(restText);
    return match != null ? int.parse(match.group(1)!) : 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _workoutTimer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _startRestTimer() {
    if (isResting || _timer?.isActive == true) return;

    setState(() {
      isResting = true;
      isPaused = false;
    });

    final currentExercise = widget.exercises[currentExerciseIndex];
    _secondsRemaining = _extractRestTime(currentExercise['rest']);
    _restStartTime = _secondsRemaining;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isPaused) return;

      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _finishRest();
        }
      });
    });

    HapticFeedback.lightImpact();
    _playRestSound();
  }

  void _finishRest() {
    _timer?.cancel();

    // Calcular tiempo de descanso real utilizado
    int restTimeUsed = _restStartTime - _secondsRemaining;
    workoutSession.totalRestTime += restTimeUsed;

    // Actualizar la sesión del set anterior
    if (currentSet > 1) {
      workoutSession
          .exercises[currentExerciseIndex]
          .sets[currentSet - 2]
          .restTimeUsed = restTimeUsed;
    }

    setState(() {
      isResting = false;
      _secondsRemaining = 0;
    });

    HapticFeedback.mediumImpact();
    _playRestCompleteSound();
  }

  void _completeSet() {
    _showSetCompletionDialog();
  }

  void _showSetCompletionDialog() {
    final currentExercise = widget.exercises[currentExerciseIndex];
    final currentSetSession =
        workoutSession.exercises[currentExerciseIndex].sets[currentSet - 1];

    // Pre-llenar con valores estimados
    _repsController.text = _extractRepsEstimate(currentExercise['sets']);
    _weightController.text = currentSetSession.weight.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Serie $currentSet completada',
              style: const TextStyle(
                color: AppTheme.iconColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentExercise['name'],
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de repeticiones
                TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.iconColor),
                  decoration: InputDecoration(
                    labelText: 'Repeticiones realizadas',
                    labelStyle: const TextStyle(color: AppTheme.textColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.accentColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.accentColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Campo de peso
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.iconColor),
                  decoration: InputDecoration(
                    labelText: 'Peso usado (kg)',
                    labelStyle: const TextStyle(color: AppTheme.textColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.accentColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.accentColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppTheme.textColor),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _confirmSetCompletion();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                ),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  String _extractRepsEstimate(String setsText) {
    RegExp regExp = RegExp(r'(\d+)-?(\d+)?\s*reps');
    Match? match = regExp.firstMatch(setsText);
    if (match != null) {
      return match.group(1) ?? '10';
    }
    return '10';
  }

  void _confirmSetCompletion() {
    final currentSetSession =
        workoutSession.exercises[currentExerciseIndex].sets[currentSet - 1];

    // Actualizar datos del set
    currentSetSession.reps = int.tryParse(_repsController.text) ?? 0;
    currentSetSession.weight = double.tryParse(_weightController.text) ?? 0.0;
    currentSetSession.completedAt = DateTime.now();
    currentSetSession.isCompleted = true;

    final totalSets =
        workoutSession.exercises[currentExerciseIndex].sets.length;

    if (currentSet < totalSets) {
      // Hay más series en este ejercicio
      setState(() {
        currentSet++;
      });
      _startRestTimer();
    } else {
      // Ejercicio completado, pasar al siguiente
      _completeExercise();
    }

    HapticFeedback.lightImpact();
  }

  void _completeExercise() {
    // Marcar ejercicio como completado
    workoutSession.exercises[currentExerciseIndex].endTime = DateTime.now();

    if (currentExerciseIndex < widget.exercises.length - 1) {
      setState(() {
        currentExerciseIndex++;
        currentSet = 1;
        isResting = false;
      });

      // Iniciar siguiente ejercicio
      workoutSession.exercises[currentExerciseIndex].startTime = DateTime.now();
      _timer?.cancel();
    } else {
      // Rutina completada
      _completeWorkout();
    }
  }

  void _previousExercise() {
    if (currentExerciseIndex > 0) {
      // Finalizar ejercicio actual si estaba iniciado
      if (workoutSession.exercises[currentExerciseIndex].startTime != null) {
        workoutSession.exercises[currentExerciseIndex].endTime = DateTime.now();
      }

      setState(() {
        currentExerciseIndex--;
        currentSet = 1;
        isResting = false;
      });

      // Reiniciar ejercicio anterior
      workoutSession.exercises[currentExerciseIndex].startTime = DateTime.now();
      workoutSession.exercises[currentExerciseIndex].endTime = null;
      _timer?.cancel();
    }
  }

  void _nextExercise() {
    _completeExercise();
  }

  void _completeWorkout() {
    workoutSession.endTime = DateTime.now();
    workoutSession.totalWorkoutTime = _workoutElapsedSeconds;

    setState(() {
      isCompleted = true;
      isResting = false;
    });

    _timer?.cancel();
    _workoutTimer?.cancel();
    HapticFeedback.heavyImpact();

    // Aquí podrías guardar la sesión en una base de datos o storage local
    _saveWorkoutSession();

    _showCompletionDialog();
  }

  void _saveWorkoutSession() {
    // TODO: Implementar guardado en base de datos local o remota
    debugPrint('Guardando sesión de entrenamiento:');
    debugPrint('Rutina: ${workoutSession.routineName}');
    debugPrint(
      'Duración total: ${workoutSession.totalDuration.inMinutes} minutos',
    );
    debugPrint('Tiempo de descanso: ${workoutSession.totalRestTime} segundos');
    debugPrint('Ejercicios completados: ${workoutSession.exercises.length}');

    // Ejemplo de cómo acceder a los datos:
    for (var exercise in workoutSession.exercises) {
      debugPrint('${exercise.name}:');
      for (int i = 0; i < exercise.sets.length; i++) {
        final set = exercise.sets[i];
        if (set.isCompleted) {
          debugPrint('  Serie ${i + 1}: ${set.reps} reps, ${set.weight} kg');
        }
      }
    }
  }

  void _showCompletionDialog() {
    final duration = workoutSession.totalDuration;
    final completedSets =
        workoutSession.exercises
            .expand((e) => e.sets)
            .where((s) => s.isCompleted)
            .length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.celebration, color: AppTheme.accentColor, size: 28),
                SizedBox(width: 8),
                Text(
                  '¡Felicitaciones!',
                  style: TextStyle(
                    color: AppTheme.iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Has completado tu rutina exitosamente',
                  style: TextStyle(color: AppTheme.textColor, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.routineName,
                        style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Duración: ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppTheme.textColor),
                      ),
                      Text(
                        '$completedSets series completadas',
                        style: const TextStyle(color: AppTheme.textColor),
                      ),
                      Text(
                        '${widget.exercises.length} ejercicios',
                        style: const TextStyle(color: AppTheme.textColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar dialog
                  Navigator.of(context).pop(); // Volver a routine details
                  Navigator.of(context).pop(); // Volver a home
                },
                child: const Text(
                  'Finalizar',
                  style: TextStyle(color: AppTheme.accentColor, fontSize: 16),
                ),
              ),
            ],
          ),
    );
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  void _skipRest() {
    _finishRest();
  }

  void _togglePreviewMode() {
    setState(() {
      isPreviewMode = !isPreviewMode;
    });
  }

  void _playRestSound() {
    // TODO: Implementar sonido de inicio de descanso
    // Podrías usar el paquete 'audioplayers' para reproducir sonidos
  }

  void _playRestCompleteSound() {
    // TODO: Implementar sonido de fin de descanso
  }

  double get overallProgress {
    int totalExercises = widget.exercises.length;
    return (currentExerciseIndex + 1) / totalExercises;
  }

  double get exerciseProgress {
    int totalSets = workoutSession.exercises[currentExerciseIndex].sets.length;
    int completedCount =
        workoutSession.exercises[currentExerciseIndex].sets
            .where((set) => set.isCompleted)
            .length;
    return completedCount / totalSets;
  }

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return _buildCompletionScreen();
    }

    return Container(
      decoration: AppTheme.foundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              _buildProgressSection(),
              if (isPreviewMode)
                _buildPreviewSection()
              else
                _buildMainContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            if (isResting) _buildRestSection() else _buildExerciseSection(),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => _showExitDialog(),
        icon: const Icon(Icons.close, color: AppTheme.iconColor),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.routineName,
            style: const TextStyle(
              color: AppTheme.iconColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _formatWorkoutTime(_workoutElapsedSeconds),
            style: TextStyle(
              color: AppTheme.textColor.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _togglePreviewMode,
          icon: Icon(
            isPreviewMode ? Icons.fitness_center : Icons.preview,
            color: AppTheme.accentColor,
          ),
        ),
        if (isResting)
          IconButton(
            onPressed: _togglePause,
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              color: AppTheme.accentColor,
            ),
          ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Progreso general
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso general',
                style: TextStyle(color: AppTheme.textColor, fontSize: 16),
              ),
              Text(
                '${currentExerciseIndex + 1}/${widget.exercises.length}',
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: overallProgress,
            backgroundColor: AppTheme.cardColor.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.accentColor,
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 16),

          // Progreso del ejercicio actual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Serie actual',
                style: TextStyle(color: AppTheme.textColor, fontSize: 16),
              ),
              Text(
                '$currentSet/${workoutSession.exercises[currentExerciseIndex].sets.length}',
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: exerciseProgress,
            backgroundColor: AppTheme.cardColor.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vista previa de ejercicios',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = widget.exercises[index];
                  final isCurrentExercise = index == currentExerciseIndex;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isCurrentExercise
                              ? AppTheme.accentColor.withOpacity(0.2)
                              : AppTheme.cardColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isCurrentExercise
                                ? AppTheme.accentColor
                                : AppTheme.accentColor.withOpacity(0.2),
                        width: isCurrentExercise ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isCurrentExercise)
                          const Icon(
                            Icons.play_arrow,
                            color: AppTheme.accentColor,
                            size: 24,
                          ),
                        if (isCurrentExercise) const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise['name'],
                                style: TextStyle(
                                  color:
                                      isCurrentExercise
                                          ? AppTheme.accentColor
                                          : AppTheme.iconColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                exercise['target'],
                                style: TextStyle(
                                  color: AppTheme.textColor.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                exercise['sets'],
                                style: TextStyle(
                                  color: AppTheme.textColor.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text(
            'Tiempo de descanso',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isPaused ? 1.0 : _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentColor.withOpacity(0.1),
                    border: Border.all(color: AppTheme.accentColor, width: 3),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_secondsRemaining),
                          style: const TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isPaused ? 'PAUSADO' : 'DESCANSANDO',
                          style: TextStyle(
                            color: AppTheme.textColor.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _togglePause,
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(isPaused ? 'Reanudar' : 'Pausar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardColor,
                  foregroundColor: AppTheme.iconColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _skipRest,
                icon: const Icon(Icons.skip_next),
                label: const Text('Omitir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSection() {
    final currentExercise = widget.exercises[currentExerciseIndex];
    final exerciseSession = workoutSession.exercises[currentExerciseIndex];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Título del ejercicio
          Text(
            currentExercise['name'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.iconColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentExercise['target'],
            style: TextStyle(
              color: AppTheme.textColor.withOpacity(0.8),
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 30),

          // Card del ejercicio
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Icono del ejercicio
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    currentExercise['icon'],
                    color: AppTheme.accentColor,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                // Información de la serie
                Text(
                  'Serie $currentSet',
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentExercise['sets'],
                  style: const TextStyle(
                    color: AppTheme.iconColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                // Historial de series anteriores
                if (currentSet > 1) _buildPreviousSetsHistory(exerciseSession),

                // Indicadores de series
                _buildSetsIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousSetsHistory(ExerciseSession exerciseSession) {
    final completedSets =
        exerciseSession.sets.where((set) => set.isCompleted).toList();

    if (completedSets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Series anteriores:',
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...completedSets.asMap().entries.map((entry) {
          final index = entry.key;
          final set = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(
                  'Serie ${index + 1}: ',
                  style: TextStyle(
                    color: AppTheme.textColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${set.reps} reps',
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (set.weight > 0) ...[
                  Text(
                    ' • ${set.weight} kg',
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSetsIndicator() {
    final exerciseSession = workoutSession.exercises[currentExerciseIndex];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(exerciseSession.sets.length, (index) {
        bool isCompleted = exerciseSession.sets[index].isCompleted;
        bool isCurrent = index == currentSet - 1;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isCompleted
                    ? AppTheme.accentColor
                    : isCurrent
                    ? AppTheme.accentColor.withOpacity(0.5)
                    : AppTheme.textColor.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          if (!isResting && !isPreviewMode) ...[
            // Botón completar serie
            Container(
              width: double.infinity,
              height: 60,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [AppTheme.accentColor, Color(0xFFFFA500)],
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: _completeSet,
                icon: const Icon(Icons.check, color: Colors.white, size: 24),
                label: Text(
                  'Completar Serie $currentSet',
                  style: const TextStyle(
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

          // Botones de navegación
          if (!isResting) ...[
            Row(
              children: [
                if (currentExerciseIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousExercise,
                      icon: const Icon(
                        Icons.skip_previous,
                        color: AppTheme.textColor,
                      ),
                      label: const Text(
                        'Anterior',
                        style: TextStyle(color: AppTheme.textColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.textColor.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),

                if (currentExerciseIndex > 0 &&
                    currentExerciseIndex < widget.exercises.length - 1)
                  const SizedBox(width: 12),

                if (currentExerciseIndex < widget.exercises.length - 1)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _nextExercise,
                      icon: const Icon(
                        Icons.skip_next,
                        color: AppTheme.accentColor,
                      ),
                      label: const Text(
                        'Siguiente',
                        style: TextStyle(color: AppTheme.accentColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.accentColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final duration = workoutSession.totalDuration;
    final completedSets =
        workoutSession.exercises
            .expand((e) => e.sets)
            .where((s) => s.isCompleted)
            .length;
    final totalVolume = workoutSession.exercises
        .expand((e) => e.sets)
        .where((s) => s.isCompleted)
        .fold<double>(0, (sum, set) => sum + (set.weight * set.reps));

    return Container(
      decoration: AppTheme.foundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.celebration,
                  color: AppTheme.accentColor,
                  size: 100,
                ),
                const SizedBox(height: 30),
                const Text(
                  '¡Rutina Completada!',
                  style: TextStyle(
                    color: AppTheme.iconColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.routineName,
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 40),

                // Estadísticas de la sesión
                Container(
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
                    children: [
                      _buildStatRow(
                        'Duración total',
                        '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow('Series completadas', '$completedSets'),
                      const SizedBox(height: 12),
                      _buildStatRow('Ejercicios', '${widget.exercises.length}'),
                      const SizedBox(height: 12),
                      _buildStatRow(
                        'Volumen total',
                        '${totalVolume.toStringAsFixed(0)} kg',
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow(
                        'Tiempo de descanso',
                        '${(workoutSession.totalRestTime / 60).toStringAsFixed(1)} min',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Ir a pantalla de historial/estadísticas
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.analytics,
                          color: AppTheme.accentColor,
                        ),
                        label: const Text(
                          'Ver Estadísticas',
                          style: TextStyle(color: AppTheme.accentColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.accentColor),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.home, color: Colors.white),
                        label: const Text(
                          'Finalizar',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textColor, fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.accentColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '¿Abandonar rutina?',
              style: TextStyle(
                color: AppTheme.iconColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Si sales ahora perderás el progreso de esta sesión.',
                  style: TextStyle(color: AppTheme.textColor),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tiempo transcurrido: ${_formatWorkoutTime(_workoutElapsedSeconds)}',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Continuar',
                  style: TextStyle(color: AppTheme.textColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar dialog
                  Navigator.of(context).pop(); // Volver atrás
                },
                child: const Text('Salir', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatWorkoutTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    } else {
      return '${minutes}m ${remainingSeconds}s';
    }
  }
}
