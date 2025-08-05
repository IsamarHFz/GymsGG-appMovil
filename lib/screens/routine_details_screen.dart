// screens/routine_details_screen.dart
import 'package:flutter/material.dart';
import 'package:gymsgg_app/screens/edit_routine_screen.dart';
import 'package:gymsgg_app/screens/routine_execution_screen.dart';
import 'package:gymsgg_app/models/routine_model.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class RoutineDetailsScreen extends StatefulWidget {
  static const String routeName = '/routine-details';

  final String routineName;
  final String level;
  final String difficulty;

  const RoutineDetailsScreen({
    super.key,
    required this.routineName,
    required this.level,
    required this.difficulty,
    required String fitnessLevel,
  });

  @override
  State<RoutineDetailsScreen> createState() => _RoutineDetailsScreenState();
}

class _RoutineDetailsScreenState extends State<RoutineDetailsScreen> {
  late Routine currentRoutine;

  @override
  void initState() {
    super.initState();
    _initializeRoutine();
  }

  void _initializeRoutine() {
    final exercisesList = _getExercises();
    currentRoutine = Routine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: widget.routineName,
      level: widget.level,
      difficulty: widget.difficulty,
      duration: _getDuration(),
      frequency: _getFrequency(),
      equipment: _getEquipment(),
      benefits: _getBenefits(),
      exercises:
          exercisesList.map((exerciseMap) {
            return Exercise(
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
            );
          }).toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: "",
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  currentRoutine.name, // Cambio aquí: usar currentRoutine.name
                  style: const TextStyle(
                    color: AppTheme.iconColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Nivel ${currentRoutine.level} • ${currentRoutine.difficulty}', // Cambio aquí también
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

  void _navigateToEditRoutine(BuildContext context) async {
    // Cambio aquí: hacer la navegación async y esperar el resultado
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                EditRoutineScreen(routine: currentRoutine, isNewRoutine: false),
      ),
    );

    // Si se editó la rutina, actualizar el estado
    if (result != null && result is Routine) {
      setState(() {
        currentRoutine = result;
      });

      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Rutina personalizada guardada'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String _getIconName(IconData icon) {
    // Mapear IconData a String para la compatibilidad con el modelo
    if (icon == Icons.fitness_center) return 'fitness_center';
    if (icon == Icons.directions_run) return 'directions_run';
    if (icon == Icons.straighten) return 'straighten';
    if (icon == Icons.accessibility_new) return 'accessibility_new';
    return 'fitness_center'; // default
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
              // Cambio aquí: usar currentRoutine.benefits directamente
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

  Widget _buildExercisesList() {
    final exercises =
        currentRoutine
            .exercises; // Cambio aquí: usar currentRoutine.exercises directamente

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
              Text(
                '${exercises.length} ejercicios',
                style: TextStyle(
                  color: AppTheme.textColor.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...exercises.map((exercise) => _buildExerciseCardFromModel(exercise)),
        ],
      ),
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
                debugPrint('Comenzar rutina: ${currentRoutine.name}');
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

  Widget _buildExerciseCardFromModel(Exercise exercise) {
    return Container(
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

  // Métodos para obtener información personalizada según el nivel (fallback)
  String _getDuration() {
    switch (widget.level.toLowerCase()) {
      case 'principiante':
        return '30-45 minutos';
      case 'intermedio':
        return '45-60 minutos';
      case 'avanzado':
        return '60-90 minutos';
      default:
        return '45-60 minutos';
    }
  }

  String _getFrequency() {
    switch (widget.level.toLowerCase()) {
      case 'principiante':
        return '2-3 veces por semana';
      case 'intermedio':
        return '3-4 veces por semana';
      case 'avanzado':
        return '4-5 veces por semana';
      default:
        return '3-4 veces por semana';
    }
  }

  String _getEquipment() {
    switch (widget.level.toLowerCase()) {
      case 'principiante':
        return 'Peso corporal, mancuernas ligeras';
      case 'intermedio':
        return 'Mancuernas, banco, barras';
      case 'avanzado':
        return 'Equipamiento completo de gimnasio';
      default:
        return 'Mancuernas, banco';
    }
  }

  List<String> _getBenefits() {
    switch (widget.level.toLowerCase()) {
      case 'principiante':
        return [
          'Introducción al ejercicio',
          'Construcción de hábitos',
          'Fortalecimiento básico',
        ];
      case 'intermedio':
        return [
          'Fortalecimiento muscular',
          'Mejora de la resistencia',
          'Tonificación corporal',
        ];
      case 'avanzado':
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
    // Ejercicios personalizados según el nivel
    switch (widget.level.toLowerCase()) {
      case 'principiante':
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
            'name': 'Bulgárias',
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
