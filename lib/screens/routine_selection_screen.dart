import 'package:flutter/material.dart';
import 'package:gymsgg_app/screens/routine_details_screen.dart';
import 'package:gymsgg_app/services/firebase_service.dart'; // ← AGREGAR IMPORT
import 'package:gymsgg_app/theme/app_theme.dart';

class RoutineSelectionScreen extends StatefulWidget {
  final String selectedLevel;
  final String fitnessLevel; // ← Parámetro requerido agregado

  const RoutineSelectionScreen({
    super.key,
    required this.selectedLevel,
    required this.fitnessLevel,
  });

  @override
  State<RoutineSelectionScreen> createState() => _RoutineSelectionScreenState();
}

class _RoutineSelectionScreenState extends State<RoutineSelectionScreen> {
  String selectedRoutine = '';
  bool _isLoading = false; // ← AGREGAR ESTADO DE LOADING

  // Rutinas personalizadas por nivel
  Map<String, List<RoutineData>> get routinesByLevel => {
    'beginner': [
      RoutineData(
        id: 'beginner_legs_glutes',
        title: 'Pierna y Glúteos',
        description: 'Ejercicios fundamentales\npara comenzar',
        duration: '30-40 min',
        difficulty: 'Fácil',
        icon: Icons.fitness_center,
      ),
      RoutineData(
        id: 'beginner_back_arms',
        title: 'Espalda y Brazos',
        description: 'Fortalecimiento\nbásico superior',
        duration: '25-35 min',
        difficulty: 'Fácil',
        icon: Icons.directions_run,
      ),
      RoutineData(
        id: 'beginner_abs_cardio',
        title: 'Abdominales y Cardio',
        description: 'Core y activación\ncardiovascular',
        duration: '20-30 min',
        difficulty: 'Fácil',
        icon: Icons.favorite,
      ),
    ],
    'intermediate': [
      RoutineData(
        id: 'intermediate_strength',
        title: 'Fuerza Completa',
        description: 'Trabajo de fuerza\npara todo el cuerpo',
        duration: '45-55 min',
        difficulty: 'Medio',
        icon: Icons.fitness_center,
      ),
      RoutineData(
        id: 'intermediate_hiit',
        title: 'HIIT Intermedio',
        description: 'Intervalos de alta\nintensidad',
        duration: '35-45 min',
        difficulty: 'Medio',
        icon: Icons.whatshot,
      ),
      RoutineData(
        id: 'intermediate_core',
        title: 'Core Power',
        description: 'Fortalecimiento del\nnúcleo corporal',
        duration: '30-40 min',
        difficulty: 'Medio',
        icon: Icons.center_focus_strong,
      ),
    ],
    'advanced': [
      RoutineData(
        id: 'advanced_beast',
        title: 'Bestia Mode',
        description: 'Rutina extrema para\natletas avanzados',
        duration: '60-75 min',
        difficulty: 'Difícil',
        icon: Icons.flash_on,
      ),
      RoutineData(
        id: 'advanced_warrior',
        title: 'Warrior Training',
        description: 'Entrenamiento de\nguerrero funcional',
        duration: '65-80 min',
        difficulty: 'Difícil',
        icon: Icons.sports_martial_arts,
      ),
      RoutineData(
        id: 'advanced_endurance',
        title: 'Resistencia Elite',
        description: 'Máxima resistencia\ny condición física',
        duration: '70-90 min',
        difficulty: 'Difícil',
        icon: Icons.timer,
      ),
    ],
  };

  List<RoutineData> get currentRoutines =>
      routinesByLevel[widget.selectedLevel] ?? [];

  String get levelTitle {
    switch (widget.selectedLevel) {
      case 'beginner':
        return 'Principiante';
      case 'intermediate':
        return 'Intermedio';
      case 'advanced':
        return 'Avanzado';
      default:
        return 'Nivel';
    }
  }

  IconData get levelIcon {
    switch (widget.selectedLevel) {
      case 'beginner':
        return Icons.directions_walk;
      case 'intermediate':
        return Icons.directions_run;
      case 'advanced':
        return Icons.fitness_center;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(decoration: AppTheme.foundColor),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildLevelInfo(),
                  const SizedBox(height: 30),
                  _buildRoutineOptions(),
                  const SizedBox(height: 40),
                  if (selectedRoutine.isNotEmpty) _buildStartButton(),
                ],
              ),
            ),
          ),
        ),
        // ← AGREGAR LOADING OVERLAY
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppTheme.iconColor,
            size: 24,
          ),
        ),
        const Expanded(
          child: Text(
            'Elige una rutina',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.iconColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 48), // Balance for back button
      ],
    );
  }

  Widget _buildLevelInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(levelIcon, color: AppTheme.accentColor, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nivel $levelTitle',
                  style: const TextStyle(
                    color: AppTheme.iconColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${currentRoutines.length} rutinas disponibles',
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineOptions() {
    return Expanded(
      child: ListView.builder(
        itemCount: currentRoutines.length,
        itemBuilder: (context, index) {
          final routine = currentRoutines[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: _buildRoutineCard(routine),
          );
        },
      ),
    );
  }

  Widget _buildRoutineCard(RoutineData routine) {
    bool isSelected = selectedRoutine == routine.id;

    return GestureDetector(
      onTap:
          _isLoading
              ? null
              : () {
                setState(() {
                  selectedRoutine = routine.id;
                });
              },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppTheme.accentColor.withOpacity(0.1)
                  : AppTheme.cardColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                isSelected
                    ? AppTheme.accentColor
                    : AppTheme.accentColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppTheme.accentColor.withOpacity(0.2)
                        : AppTheme.cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                routine.icon,
                color: isSelected ? AppTheme.accentColor : AppTheme.textColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.title,
                    style: TextStyle(
                      color:
                          isSelected
                              ? AppTheme.accentColor
                              : AppTheme.iconColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    routine.description,
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(
                      routine.difficulty,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    routine.difficulty,
                    style: TextStyle(
                      color: _getDifficultyColor(routine.difficulty),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  routine.duration,
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors:
              _isLoading
                  ? [
                    AppTheme.accentColor.withOpacity(0.5),
                    const Color(0xFFFFA500).withOpacity(0.5),
                  ]
                  : [AppTheme.accentColor, const Color(0xFFFFA500)],
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleContinue, // ← CAMBIO AQUÍ
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 2.5,
                  ),
                )
                : const Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
      ),
    );
  }

  // ✅ NUEVO MÉTODO PARA MANEJAR LA CONTINUACIÓN
  Future<void> _handleContinue() async {
    final selectedRoutineData = currentRoutines.firstWhere(
      (routine) => routine.id == selectedRoutine,
    );

    debugPrint('🎯 Rutina seleccionada: ${selectedRoutineData.title}');
    debugPrint('🎯 Nivel: ${widget.selectedLevel}');

    setState(() => _isLoading = true);

    try {
      // ✅ Guardar la rutina seleccionada y marcar onboarding como completado
      final userData = {
        'selectedRoutineId': selectedRoutine,
        'selectedRoutineName': selectedRoutineData.title,
        'profileCompleted': true, // ✅ AHORA SÍ marcar como completado
        'onboardingCompleted': true,
        'onboardingStep': 'completed',
        'completedAt': DateTime.now().toIso8601String(),
      };

      final success = await FirebaseService.updateCurrentUserProfile(userData);

      if (mounted) {
        if (success) {
          // ✅ Navegar a los detalles de la rutina seleccionada
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => RoutineDetailsScreen(
                    routineId: selectedRoutine,
                    routineName: selectedRoutineData.title,
                    level: levelTitle,
                    difficulty: selectedRoutineData.difficulty,
                    fitnessLevel: widget.selectedLevel,
                    routine: null, // Se cargará automáticamente con el ID
                  ),
            ),
          );
        } else {
          _showErrorMessage('Error al guardar la rutina seleccionada');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
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
}

// Clase para los datos de rutina
class RoutineData {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final IconData icon;

  RoutineData({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.icon,
  });
}
