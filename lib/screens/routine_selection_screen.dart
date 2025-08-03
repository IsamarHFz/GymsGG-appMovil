import 'package:flutter/material.dart';
import 'package:gymsgg_app/screens/routine_details_screen.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class RoutineSelectionScreen extends StatefulWidget {
  final String selectedLevel;

  const RoutineSelectionScreen({super.key, required this.selectedLevel});

  @override
  State<RoutineSelectionScreen> createState() => _RoutineSelectionScreenState();
}

class _RoutineSelectionScreenState extends State<RoutineSelectionScreen> {
  String selectedRoutine = '';

  // Rutinas personalizadas por nivel (sin ejercicios)
  Map<String, List<RoutineData>> get routinesByLevel => {
    'beginner': [
      RoutineData(
        id: 'beginner_basic',
        title: 'Pierna y gluteos',
        description: 'Ejercicios fundamentales\npara comenzar',
        duration: '10 min cada rutina',
        difficulty: 'Medio',
        icon: Icons.fitness_center,
      ),
      RoutineData(
        id: 'beginner_cardio',
        title: 'Espalda y brazo',
        description: 'Activación cardiovascular\nbásica',
        duration: '10-15 min',
        difficulty: 'Muy Fácil',
        icon: Icons.favorite,
      ),
      RoutineData(
        id: 'beginner_flexibility',
        title: 'Abdominales y Cardio',
        description: 'Estiramientos y\nmobilidad articular',
        duration: '12-18 min',
        difficulty: 'Fácil',
        icon: Icons.self_improvement,
      ),
    ],
    'intermediate': [
      RoutineData(
        id: 'intermediate_strength',
        title: 'Fuerza Completa',
        description: 'Trabajo de fuerza\npara todo el cuerpo',
        duration: '25-30 min',
        difficulty: 'Moderado',
        icon: Icons.fitness_center,
      ),
      RoutineData(
        id: 'intermediate_hiit',
        title: 'HIIT Intermedio',
        description: 'Intervalos de alta\nintensidad',
        duration: '20-25 min',
        difficulty: 'Intenso',
        icon: Icons.whatshot,
      ),
      RoutineData(
        id: 'intermediate_core',
        title: 'Core Power',
        description: 'Fortalecimiento del\nnúcleo corporal',
        duration: '18-22 min',
        difficulty: 'Moderado',
        icon: Icons.center_focus_strong,
      ),
    ],
    'advanced': [
      RoutineData(
        id: 'advanced_beast',
        title: 'Bestia Mode',
        description: 'Rutina extrema para\natletas avanzados',
        duration: '35-45 min',
        difficulty: 'Extremo',
        icon: Icons.flash_on,
      ),
      RoutineData(
        id: 'advanced_warrior',
        title: 'Warrior Training',
        description: 'Entrenamiento de\nguerrero funcional',
        duration: '40-50 min',
        difficulty: 'Máximo',
        icon: Icons.sports_martial_arts,
      ),
      RoutineData(
        id: 'advanced_endurance',
        title: 'Resistencia Elite',
        description: 'Máxima resistencia\ny condición física',
        duration: '45-60 min',
        difficulty: 'Elite',
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
    return Container(
      decoration: AppTheme.foundColor,
      child: Scaffold(
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
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
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
      onTap: () {
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
        gradient: const LinearGradient(
          colors: [AppTheme.accentColor, Color(0xFFFFA500)],
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          final selectedRoutineData = currentRoutines.firstWhere(
            (routine) => routine.id == selectedRoutine,
          );
          debugPrint('Rutina seleccionada: ${selectedRoutineData.title}');
          debugPrint('Nivel: ${widget.selectedLevel}');
          // Aquí puedes navegar a la siguiente pantalla
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => RoutineDetailsScreen(
                    routineName: '',
                    level: '',
                    difficulty: '',
                    fitnessLevel: '',
                  ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'muy fácil':
        return Colors.green;
      case 'fácil':
        return Colors.lightGreen;
      case 'moderado':
        return Colors.orange;
      case 'intenso':
        return Colors.deepOrange;
      case 'extremo':
        return Colors.red;
      case 'máximo':
        return Colors.red[800]!;
      case 'elite':
        return Colors.purple;
      default:
        return AppTheme.accentColor;
    }
  }
}

// Clase para los datos de rutina (sin ejercicios)
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
